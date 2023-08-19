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
  var storage: Storage
}

extension Node48 {
  static let type: NodeType = .node48
  static let numKeys: Int = 48

  init(buffer: RawNodeBuffer) {
    self.init(storage: Storage(raw: buffer))
  }
}

extension Node48 {
  static func allocate() -> Self {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    let node = Self(storage: buf)

    node.withBody { keys, childs in
      UnsafeMutableRawPointer(keys.baseAddress!)
        .bindMemory(to: UInt8.self, capacity: Self.numKeys)
      UnsafeMutableRawPointer(childs.baseAddress!)
        .bindMemory(to: RawNode?.self, capacity: Self.numKeys)

      for idx in 0..<256 {
        keys[idx] = 0xFF
      }
    }

    return node
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

extension Node48 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<RawNode?>

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
        .assumingMemoryBound(to: RawNode?.self)
      let childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)

      return try body(keys, childs)
    }
  }
}

extension Node48: InternalNode {
  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + 256*MemoryLayout<KeyPart>.stride +
      Self.numKeys*MemoryLayout<RawNode?>.stride
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

  func child(at: Int) -> RawNode? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
    return withBody { _, childs in
      return childs[at]
    }
  }

  mutating func addChild(forKey k: KeyPart, node: any ManagedNode) -> UpdateResult<RawNode?> {
    if count < Self.numKeys {
      withBody { keys, childs in
        assert(keys[Int(k)] == 0xFF, "node for key \(k) already exists")

        guard let slot = findFreeSlot() else {
          assert(false, "cannot find free slot in Node48")
          return
        }

        keys[Int(k)] = KeyPart(slot)
        childs[slot] = node.rawNode
      }

      self.count += 1
      return .noop
    } else {
      var newNode = Node256.allocate(copyFrom: self)
      _ = newNode.addChild(forKey: k, node: node)
      return .replaceWith(RawNode(from: newNode))
    }
  }

  public mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?> {
    return withBody { keys, childs in
      let targetSlot = Int(keys[index])
      assert(targetSlot != 0xFF, "slot is empty already")
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
      if count == 13 {
        let newNode = Node16.allocate(copyFrom: self)
        return .replaceWith(RawNode(from: newNode))
      }

      return .noop
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

  mutating func withChildRef<R>(at index: Index, _ body: (ChildSlotPtr) -> R) -> R {
    assert(index < count, "not enough childs in node")
    return withBody {_, childs in
      let ref = childs.baseAddress! + index
      return body(ref)
    }
  }

  static func deinitialize(_ storage: NodeStorage<Self>) {
  }
}
