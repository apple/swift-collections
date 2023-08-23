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

struct Node256<Spec: ARTreeSpec> {
  var storage: Storage
}

extension Node256 {
  static var type: NodeType { .node256 }
  static var numKeys: Int { 256 }
}

extension Node256 {
  static func allocate() -> NodeStorage<Self> {
    let storage = NodeStorage<Self>.allocate()

    storage.update { node in
      _ = node.withBody { childs in
        UnsafeMutableRawPointer(childs.baseAddress!)
          .bindMemory(to: RawNode?.self, capacity: Self.numKeys)
      }
    }

    return storage
  }

  static func allocate(copyFrom: Node48<Spec>) -> NodeStorage<Self> {
    let storage = Self.allocate()

    storage.update { node in
      node.copyHeader(from: copyFrom)
      copyFrom.withBody { fromKeys, fromChilds in
        node.withBody { newChilds in
          for key in 0..<256 {
            let slot = Int(fromKeys[key])
            if slot < 0xFF {
              newChilds[key] = fromChilds[slot]
            }
          }

          Self.retainChildren(newChilds, count: Self.numKeys)
        }
      }
      assert(node.count == 48, "should have exactly 48 childs")
    }

    return storage
  }
}

extension Node256 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Children = UnsafeMutableBufferPointer<RawNode?>

  func withBody<R>(body: (Children) throws -> R) rethrows -> R {
    return try storage.withBodyPointer {
      return try body(
        UnsafeMutableBufferPointer(
          start: $0.assumingMemoryBound(to: RawNode?.self),
          count: 256))
    }
  }
}

extension Node256: InternalNode {
  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + 256 * MemoryLayout<RawNode?>.stride
  }

  func index(forKey k: KeyPart) -> Index? {
    return withBody { childs in
      return childs[Int(k)] != nil ? Int(k) : nil
    }
  }

  func index() -> Index? {
    return next(index: -1)
  }

  func next(index: Index) -> Index? {
    return withBody { childs in
      for idx in index + 1..<256 {
        if childs[idx] != nil {
          return idx
        }
      }

      return nil
    }
  }

  func child(at: Int) -> RawNode? {
    assert(at < 256, "maximum 256 childs allowed")
    return withBody { childs in
      return childs[at]
    }
  }

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?> {
    return withBody { childs in
      assert(childs[Int(k)] == nil, "node for key \(k) already exists")
      childs[Int(k)] = node
      count += 1
      return .noop
    }
  }

  public mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?> {
    return withBody { childs in
      childs[index] = nil
      count -= 1

      if count == 40 {
        let newNode = Node48.allocate(copyFrom: self)
        return .replaceWith(newNode.node.rawNode)
      }

      return .noop
    }
  }

  mutating func withChildRef<R>(at index: Index, _ body: (RawNode.SlotRef) -> R) -> R {
    assert(index < count, "not enough childs in node")
    return withBody { childs in
      let ref = childs.baseAddress! + index
      return body(ref)
    }
  }
}


extension Node256: ArtNode {
  final class Buffer: RawNodeBuffer {
    deinit {
      var node = Node256(buffer: self)
      let count = node.count
      node.withBody { childs in
        for idx in 0..<count {
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
      self.withBody { fromChildren in
        node.withBody { newChildren in
          for idx in 0..<256 {
            newChildren[idx] = fromChildren[idx]
          }
        }
      }
    }

    return storage
  }
}
