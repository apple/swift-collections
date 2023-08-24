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

struct Node4<Spec: ARTreeSpec> {
  var storage: Storage
}

extension Node4 {
  static var type: NodeType { .node4 }
  static var numKeys: Int { 4 }
}

extension Node4 {
  static func allocate() -> NodeStorage<Self> {
    let storage = NodeStorage<Self>.allocate()

    storage.update { node in
      node.withBody { keys, childs in
        UnsafeMutableRawPointer(keys.baseAddress!)
          .bindMemory(to: UInt8.self, capacity: Self.numKeys)
        UnsafeMutableRawPointer(childs.baseAddress!)
          .bindMemory(to: RawNode?.self, capacity: Self.numKeys)
      }
    }

    return storage
  }

  static func allocate(copyFrom: Node16<Spec>) -> NodeStorage<Self> {
    let storage = Self.allocate()

    storage.update { node in
      node.copyHeader(from: copyFrom)
      node.withBody { newKeys, newChilds in
        copyFrom.withBody { fromKeys, fromChilds in
          UnsafeMutableRawBufferPointer(newKeys).copyBytes(
            from: UnsafeBufferPointer(rebasing: fromKeys[0..<numKeys]))
          UnsafeMutableRawBufferPointer(newChilds).copyBytes(
            from: UnsafeRawBufferPointer(
              UnsafeBufferPointer(rebasing: fromChilds[0..<numKeys])))
          Self.retainChildren(newChilds, count: node.count)
        }
      }
    }

    return storage
  }
}

extension Node4 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Children = UnsafeMutableBufferPointer<RawNode?>

  func withBody<R>(body: (Keys, Children) throws -> R) rethrows -> R {
    return try storage.withBodyPointer { bodyPtr in
      let keys = UnsafeMutableBufferPointer(
        start: bodyPtr.assumingMemoryBound(to: KeyPart.self),
        count: Self.numKeys
      )
      let childPtr =
        bodyPtr
        .advanced(by: Self.numKeys * MemoryLayout<KeyPart>.stride)
        .assumingMemoryBound(to: RawNode?.self)
      let childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)

      return try body(keys, childs)
    }
  }
}

extension Node4: InternalNode {
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

  func child(at: Index) -> RawNode? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed, given index = \(at)")
    return withBody { _, childs in
      return childs[at]
    }
  }

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?> {
    if let slot = _insertSlot(forKey: k) {
      withBody { keys, childs in
        assert(count == 0 || keys[slot] != k, "node for key \(k) already exists")
        keys.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        childs.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
        keys[slot] = k
        childs[slot] = node
        count += 1
      }
      return .noop
    } else {
      var newNode = Node16.allocate(copyFrom: self)
      _ = newNode.addChild(forKey: k, node: node)
      return .replaceWith(newNode.rawNode)
    }
  }

  mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?> {
    assert(index < 4, "index can't >= 4 in Node4")
    assert(index < count, "not enough childs in node")

    return withBody { keys, childs in
      keys[index] = 0
      childs[index] = nil

      count -= 1
      keys.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)
      childs.shiftLeft(startIndex: index + 1, endIndex: count, by: 1)
      childs[count] = nil  // Clear the last item.

      if count == 1 {
        // Shrink to leaf node.
        return .replaceWith(childs[0])
      }

      return .noop
    }
  }

  mutating func withChildRef<R>(at index: Index, _ body: (RawNode.SlotRef) -> R) -> R {
    assert(index < count, "index=\(index) less than count=\(count)")
    return withBody { _, childs in
      let ref = childs.baseAddress! + index
      return body(ref)
    }
  }
}

extension Node4: ArtNode {
  final class Buffer: RawNodeBuffer {
    deinit {
      var node = Node4(buffer: self)
      node.withBody { _, childs in
        for idx in 0..<4 {
          childs[idx] = nil
        }
      }
      node.count = 0
    }
  }

  func clone() -> NodeStorage<Self> {
    let storage = Self.allocate()

    storage.update { node in
      node.copyHeader(from: self)
      self.withBody { fromKeys, fromChildren in
        node.withBody { newKeys, newChildren in
          for idx in 0..<Self.numKeys {
            newKeys[idx] = fromKeys[idx]
            newChildren[idx] = fromChildren[idx]
          }
        }
      }
    }

    return storage
  }
}
