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

struct Node4 {
  static let numKeys: Int = 4

  typealias Storage = NodeStorage<Self>

  var storage: Storage
}

extension Node4 {
  init(ptr: RawNodeBuffer) {
    self.init(storage: Storage(ptr))
  }
}

extension Node4: Node {
  static let type: NodeType = .node4
  var type: NodeType { .node4 }
}

extension Node4 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<(any Node)?>

  func withBody<R>(body: (Keys, Childs) throws -> R) rethrows -> R {
    return try storage.withBodyPointer { bodyPtr in
      let keys = UnsafeMutableBufferPointer(
        start: bodyPtr.assumingMemoryBound(to: KeyPart.self),
        count: Self.numKeys
      )
      let childPtr = bodyPtr
        .advanced(by: Self.numKeys * MemoryLayout<KeyPart>.stride)
        .assumingMemoryBound(to: (any Node)?.self)
      let childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)

      return try body(keys, childs)
    }
  }
}

extension Node4 {
  static func allocate() -> Self {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    let node = Self(storage: buf)
    node.withBody { keys, childs in
      UnsafeMutableRawPointer(keys.baseAddress!)
        .bindMemory(to: UInt8.self, capacity: Self.numKeys)
      UnsafeMutableRawPointer(childs.baseAddress!)
        .bindMemory(to: (any Node)?.self, capacity: Self.numKeys)
    }
    return node
  }

  static func allocate(copyFrom: Node16) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)
    node.withBody { newKeys, newChilds in
      copyFrom.withBody { fromKeys, fromChilds in
        UnsafeMutableRawBufferPointer(newKeys).copyBytes(
          from: UnsafeBufferPointer(rebasing: fromKeys[0..<numKeys]))
        UnsafeMutableRawBufferPointer(newChilds).copyBytes(
          from: UnsafeRawBufferPointer(
            UnsafeBufferPointer(rebasing: fromChilds[0..<numKeys])))
      }
    }
    return node
  }
}

extension Node4: InternalNode {
  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + Self.numKeys
      * (MemoryLayout<KeyPart>.stride + MemoryLayout<(any Node)?>.stride)
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

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> (any Node)? {
    guard let index = index(forKey: k) else {
      return nil
    }

    return withBody {_, childs in
      ref = childs.baseAddress! + index
      return child(at: index)
    }
  }

  func child(at: Index) -> (any Node)? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed, given index = \(at)")
    return withBody { _, childs in
      return childs[at]
    }
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> (any Node)? {
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
    node: any Node,
    ref: ChildSlotPtr?
  ) {
    if let slot = _insertSlot(forKey: k) {
      withBody { keys, childs in
        assert(count == 0 || keys[slot] != k, "node for key \(k) already exists")
        keys.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        childs.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        keys[slot] = k
        childs[slot] = node
        count += 1
      }
    } else {
      var newNode = Node16.allocate(copyFrom: self)
      newNode.addChild(forKey: k, node: node)
      ref?.pointee = newNode
      // pointer.deallocate()
    }
  }

  mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    assert(index < 4, "index can't >= 4 in Node4")
    assert(index < count, "not enough childs in node")

    let childBuf = child(at: index)
    // childBuf?.deallocate()

    withBody { keys, childs in
      keys[self.count] = 0
      childs[self.count] = nil

      count -= 1
      keys.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)
      childs.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)

      if count == 1 {
        // Shrink to leaf node.
        ref?.pointee = childs[0]
      }
    }
  }
}
