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

  init(buffer: RawNodeBuffer) {
    self.init(storage: Storage(raw: buffer))
  }
}

extension Node256 {
  static func allocate() -> Node256 {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    let node = Self(storage: buf)
    _ = node.withBody { childs in
      UnsafeMutableRawPointer(childs.baseAddress!)
        .bindMemory(to: RawNode?.self, capacity: Self.numKeys)
    }
    return node
  }

  static func allocate(copyFrom: Node48<Spec>) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    copyFrom.withBody { fromKeys, fromChilds in
      node.withBody { newChilds in
        for key in 0..<256 {
          let slot = Int(fromKeys[key])
          if slot < 0xFF {
            newChilds[key] = fromChilds[slot]
          }
        }
      }
    }

    assert(node.count == 48, "should have exactly 48 childs")
    return node
  }
}

extension Node256 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<RawNode?>

  func withBody<R>(body: (Childs) throws -> R) rethrows -> R {
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

  mutating func addChild(forKey k: KeyPart, node: any ManagedNode<Spec>) -> UpdateResult<RawNode?> {
    return withBody { childs in
      assert(childs[Int(k)] == nil, "node for key \(k) already exists")
      childs[Int(k)] = node.rawNode
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
        return .replaceWith(newNode.rawNode)
      }

      return .noop
    }
  }

  mutating func withChildRef<R>(at index: Index, _ body: (ChildSlotPtr) -> R) -> R {
    assert(index < count, "not enough childs in node")
    return withBody { childs in
      let ref = childs.baseAddress! + index
      return body(ref)
    }
  }

  static func deinitialize(_ storage: NodeStorage<Self>) {
  }
}
