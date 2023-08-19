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

struct RawNode {
  var storage: RawNodeBuffer

  init<N: ManagedNode>(from: N) {
    self.storage = from.storage.buf
  }
}

extension RawNode {
  var type: NodeType {
    @inline(__always) get { return storage.header }
  }

  func toInternalNode() -> any InternalNode {
    switch type {
    case .node4:
      return Node4(buffer: storage)
    case .node16:
      return Node16(buffer: storage)
    case .node48:
      return Node48(buffer: storage)
    case .node256:
      return Node256(buffer: storage)
    default:
      assert(false, "leaf nodes are not internal nodes")
    }
  }

  func toLeafNode() -> NodeLeaf {
    assert(type == .leaf)
    return NodeLeaf(ptr: storage)
  }

  func toManagedNode() -> any ManagedNode {
    switch type {
    case .leaf:
      return toLeafNode()
    default:
      return toInternalNode()
    }
  }
}
