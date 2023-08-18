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

struct Node48 {
  typealias Storage = NodeStorage<Self>

  var storage: Storage

  init(ptr: RawNodeBuffer) {
    self.init(storage: Storage(ptr))
  }

  init(storage: Storage) {
    self.storage = storage
  }
}


extension Node48 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<(any Node)?>

  func withBody<R>(body: (Keys, Childs) throws -> R) rethrows -> R {
    return try storage.withBodyPointer { bodyPtr in
      let keys = UnsafeMutableBufferPointer(
        start: bodyPtr.assumingMemoryBound(to: KeyPart.self),
        count: 256
      )

      // NOTE: Initializes each key pointer to point to a value > number of children, as 0 will
      // refer to the first child.
      // TODO: Can we initialize buffer using any stdlib method?
      let childPtr = bodyPtr
        .advanced(by: 256 * MemoryLayout<KeyPart>.stride)
        .assumingMemoryBound(to: (any Node)?.self)
      let childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)

      return try body(keys, childs)
    }
  }
}

extension Node48 {
  static func allocate() -> Self {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    let storage = Self(storage: buf)

    storage.withBody { keys, _ in
      for idx in 0..<256 {
        keys[idx] = 0xFF
      }
    }
    return storage
  }

  static func allocate(copyFrom: Node16) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    copyFrom.withBody { fromKeys, fromChilds in
      node.withBody { newKeys, newChilds in
        UnsafeMutableRawBufferPointer(newChilds).copyBytes(
          from: UnsafeMutableRawBufferPointer(fromChilds))
        for (idx, key) in fromKeys.enumerated() {
          newKeys[Int(key)] = UInt8(idx)
        }
      }
    }

    return node
  }

  static func allocate(copyFrom: Node256) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    copyFrom.withBody { fromChilds in
      node.withBody { newKeys, newChilds in
        var slot = 0
        for (key, child) in fromChilds.enumerated() {
          if child == nil {
            continue
          }

          newKeys[key] = UInt8(slot)
          newChilds[slot] = child
          slot += 1
        }
      }
    }

    return node
  }
}


extension Node48: Node {
  static let type: NodeType = .node48
  var type: NodeType { .node48 }
}

extension Node48: InternalNode {
  static let numKeys: Int = 48

  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + 256*MemoryLayout<KeyPart>.stride +
      Self.numKeys*MemoryLayout<(any Node)?>.stride
  }

  func index(forKey k: KeyPart) -> Index? {
    return withBody { keys, _ in
      let childIndex = Int(keys[Int(k)])
      return childIndex == 0xFF ? nil : childIndex
    }
  }

  func index() -> Index? {
    return next(index: -1)
  }

  func next(index: Index) -> Index? {
    return withBody { keys, _ in
      for idx: Int in index + 1..<256 {
        if keys[idx] != 0xFF {
          return Int(keys[idx])
        }
      }

      return nil
    }
  }

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> (any Node)? {
    return withBody { keys, childs in
      let childIndex = Int(keys[Int(k)])
      if childIndex == 0xFF {
        return nil
      }

      ref = childs.baseAddress! + childIndex
      return child(at: childIndex)
    }
  }

  func child(at: Int) -> (any Node)? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
    return withBody { _, childs in
      return childs[at]
    }
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> (any Node)? {
    assert(index < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
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
    if count < Self.numKeys {
      withBody { keys, childs in
        assert(keys[Int(k)] == 0xFF, "node for key \(k) already exists")

        guard let slot = findFreeSlot() else {
          assert(false, "cannot find free slot in Node48")
          return
        }

        keys[Int(k)] = KeyPart(slot)
        childs[slot] = node
      }

      self.count += 1
    } else {
      var newNode = Node256.allocate(copyFrom: self)
      newNode.addChild(forKey: k, node: node)
      ref?.pointee = newNode
      // pointer.deallocate()
    }
  }

  public mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    withBody { keys, childs in
      let targetSlot = Int(keys[index])
      assert(targetSlot != 0xFF, "slot is empty already")
      let targetChildBuf = childs[targetSlot]
      // targetChildBuf?.deallocate()

      // 1. Find out who has the last slot.
      var lastSlotKey = 0
      for k in 0..<256 {
        if keys[k] == count - 1 {
          lastSlotKey = k
          break
        }
      }

      // 2. Move last child slot into current child slot, and reset last child slot.
      childs[targetSlot] = childs[count - 1]
      childs[count - 1] = nil

      // 3. Map that key to current slot.
      keys[lastSlotKey] = UInt8(targetSlot)

      // 4. Clear input key.
      keys[index] = 0xFF

      // 5. Reduce number of children.
      count -= 1

      // 6. Shrink the node to Node16 if needed.
      if count == 13 {  // TODO: Should be made tunable.
        let newNode = Node16.allocate(copyFrom: self)
        ref?.pointee = newNode
        // pointer.deallocate()
      }
    }
  }

  private func findFreeSlot() -> Int? {
    return withBody { _, childs in
      for (index, child) in childs.enumerated() {
        if child == nil {
          return index
        }
      }

      return nil
    }
  }

}
