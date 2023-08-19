//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct Node16 {
  var storage: Storage
}

extension Node16 {
  static let type: NodeType = .node16
  static let numKeys: Int = 16

  init(buffer: RawNodeBuffer) {
    self.init(storage: Storage(raw: buffer))
  }
}

extension Node16 {
  static func allocate() -> Self {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    let node = Self(storage: buf)
    node.withBody { keys, childs in
      UnsafeMutableRawPointer(keys.baseAddress!)
        .bindMemory(to: UInt8.self, capacity: Self.numKeys)
      UnsafeMutableRawPointer(childs.baseAddress!)
        .bindMemory(to: RawNode?.self, capacity: Self.numKeys)
    }
    return node
  }

  static func allocate(copyFrom: Node4) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    copyFrom.withBody { fromKeys, fromChilds in
      node.withBody { newKeys, newChilds in
        UnsafeMutableRawBufferPointer(newKeys).copyBytes(from: fromKeys)
        UnsafeMutableRawBufferPointer(newChilds).copyBytes(
          from: UnsafeMutableRawBufferPointer(fromChilds))
      }
    }

    return node
  }

  static func allocate(copyFrom: Node48) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    copyFrom.withBody { fromKeys, fromChilds in
      node.withBody { newKeys, newChilds in
        var slot = 0
        for key: UInt8 in 0...255 {
          let childPosition = Int(fromKeys[Int(key)])
          if childPosition == 0xFF {
            continue
          }

          newKeys[slot] = key
          newChilds[slot] = fromChilds[childPosition]
          slot += 1
        }

        assert(slot == node.count)
      }
    }

    return node
  }
}

extension Node16 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<RawNode?>

  func withBody<R>(body: (Keys, Childs) throws -> R) rethrows -> R {
    return try storage.withBodyPointer { bodyPtr in
      let keys = UnsafeMutableBufferPointer(
        start: bodyPtr.assumingMemoryBound(to: KeyPart.self),
        count: Self.numKeys
      )
      let childPtr = bodyPtr
        .advanced(by: Self.numKeys * MemoryLayout<KeyPart>.stride)
        .assumingMemoryBound(to: RawNode?.self)
      let childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)

      return try body(keys, childs)
    }
  }
}

extension Node16: InternalNode {
  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + Self.numKeys
      * (MemoryLayout<KeyPart>.stride + MemoryLayout<RawNode?>.stride)
  }

  func index(forKey k: KeyPart) -> Index? {
    return withBody { keys, _ in
      for (index, key) in keys.enumerated() {
        if key == k {
          return index
        }
      }

      return nil
    }
  }

  func index() -> Index? {
    return 0
  }

  func next(index: Index) -> Index? {
    let next = index + 1
    return next < count ? next : nil
  }

  func _insertSlot(forKey k: KeyPart) -> Int? {
    // TODO: Binary search.
    if count >= Self.numKeys {
      return nil
    }

    return withBody { keys, _ in
      for idx in 0..<count {
        if keys[idx] >= Int(k) {
          return idx
        }
      }

      return count
    }
  }

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> RawNode? {
    guard let index = index(forKey: k) else {
      return nil
    }

    return withBody {_, childs in
      ref = childs.baseAddress! + index
      return child(at: index)
    }
  }

  func child(at: Index) -> RawNode? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
    return withBody { _, childs in
      return childs[at]
    }
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> RawNode? {
    assert(
      index < Self.numKeys,
      "maximum \(Self.numKeys) childs allowed, given index = \(index)")
    return withBody { _, childs in
      ref = childs.baseAddress! + index
      return childs[index]
    }
  }

  mutating func addChild(
    forKey k: KeyPart,
    node: any ManagedNode,
    ref: ChildSlotPtr?
  ) {
    if let slot = _insertSlot(forKey: k) {
      withBody {keys, childs in
        assert(count == 0 || keys[slot] != k, "node for key \(k) already exists")
        keys.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        childs.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        keys[slot] = k
        childs[slot] = node.rawNode
        count += 1
      }
    } else {
      var newNode = Node48.allocate(copyFrom: self)
      newNode.addChild(forKey: k, node: node)
      ref?.pointee = RawNode(from: newNode)
      // pointer.deallocate()
    }
  }

  mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    assert(index < Self.numKeys, "index can't >= 16 in Node16")
    assert(index < count, "not enough childs in node")

    withBody { keys, childs in
      keys[index] = 0
      childs[index] = nil

      count -= 1
      keys.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)
      childs.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)

      if count == 3 {
        // Shrink to Node4.
        let newNode = Node4.allocate(copyFrom: self)
        ref?.pointee = RawNode(from: newNode)
        // pointer.deallocate()
      }
    }
  }

  static func deinitialize(_ storage: NodeStorage<Self>) {
  }
}
