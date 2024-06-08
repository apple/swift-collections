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
  var keys: UnsafeMutableBufferPointer<KeyPart> {
    storage.withBodyPointer {
      UnsafeMutableBufferPointer(
        start: $0.assumingMemoryBound(to: KeyPart.self),
        count: Self.numKeys
      )
    }
  }

  var childs: UnsafeMutableBufferPointer<RawNode?> {
    storage.withBodyPointer {
      let childPtr = $0.advanced(by: Self.numKeys * MemoryLayout<KeyPart>.stride)
        .assumingMemoryBound(to: RawNode?.self)
      return UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)
    }
  }
}

extension Node4 {
  static func allocate() -> NodeStorage<Self> {
    let storage = NodeStorage<Self>.allocate()

    storage.update { node in
      UnsafeMutableRawPointer(node.keys.baseAddress!)
        .bindMemory(to: UInt8.self, capacity: Self.numKeys)
      UnsafeMutableRawPointer(node.childs.baseAddress!)
        .bindMemory(to: RawNode?.self, capacity: Self.numKeys)
    }

    return storage
  }

  static func allocate(copyFrom: Node16<Spec>) -> NodeStorage<Self> {
    let storage = Self.allocate()

    storage.update { newNode in
      newNode.copyHeader(from: copyFrom)

      UnsafeMutableRawBufferPointer(newNode.keys).copyBytes(
        from: UnsafeBufferPointer(rebasing: copyFrom.keys[0..<numKeys]))
      UnsafeMutableRawBufferPointer(newNode.childs).copyBytes(
        from: UnsafeRawBufferPointer(
          UnsafeBufferPointer(rebasing: copyFrom.childs[0..<numKeys])))

      Self.retainChildren(newNode.childs, count: newNode.count)
    }

    return storage
  }
}

extension Node4: InternalNode {
  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + Self.numKeys
      * (MemoryLayout<KeyPart>.stride + MemoryLayout<RawNode?>.stride)
  }

  var startIndex: Index { 0 }
  var endIndex: Index { count }

  func index(forKey k: KeyPart) -> Index? {
    for (index, key) in keys[..<count].enumerated() {
      if key == k {
        return index
      }
    }

    return nil
  }

  func index(after index: Index) -> Index {
    let next = index + 1
    if next >= count {
      return count
    } else {
      return next
    }
  }

  func _insertSlot(forKey k: KeyPart) -> Int? {
    if count >= Self.numKeys {
      return nil
    }

    for idx in 0..<count {
      if keys[idx] >= Int(k) {
        return idx
      }
    }

    return count
  }

  func child(at index: Index) -> RawNode? {
    assert(index < Self.numKeys, "maximum \(Self.numKeys) childs allowed, given index = \(index)")
    assert(index < count, "not enough childs in node")
    return childs[index]
  }

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?> {
    if let slot = _insertSlot(forKey: k) {
      assert(count == 0 || keys[slot] != k, "node for key \(k) already exists")
      keys.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
      childs.shiftRight(startIndex: slot, endIndex: count - 1, by: 1)
      keys[slot] = k
      childs[slot] = node
      count += 1
      return .noop
    } else {
      var newNode = Node16.allocate(copyFrom: self)
      _ = newNode.addChild(forKey: k, node: node)
      return .replaceWith(newNode.rawNode)
    }
  }

  mutating func removeChild(at index: Index) -> UpdateResult<RawNode?> {
    assert(index < 4, "index can't >= 4 in Node4")
    assert(index < count, "not enough childs in node")

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

  mutating func withChildRef<R>(at index: Index, _ body: (RawNode.SlotRef) -> R) -> R {
    assert(index < count, "index=\(index) less than count=\(count)")
    let ref = childs.baseAddress! + index
    return body(ref)
  }
}

extension Node4: ArtNode {
  final class Buffer: RawNodeBuffer {
    deinit {
      var node = Node4(buffer: self)
      for idx in 0..<4 {
        node.childs[idx] = nil
      }
      node.count = 0
    }
  }

  func clone() -> NodeStorage<Self> {
    let storage = Self.allocate()

    storage.update { newNode in
      newNode.copyHeader(from: self)
      for idx in 0..<Self.numKeys {
        newNode.keys[idx] = self.keys[idx]
        newNode.childs[idx] = self.childs[idx]
      }
    }

    return storage
  }
}
