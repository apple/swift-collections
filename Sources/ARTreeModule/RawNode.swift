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

  init(storage: RawNodeBuffer){
    self.storage = storage
  }
}

extension RawNode {
  typealias SlotRef = UnsafeMutablePointer<RawNode?>

  var type: NodeType {
    @inline(__always) get { return storage.header }
  }

  mutating func isUnique() -> Bool {
    return isKnownUniquelyReferenced(&storage)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RawNode {
  func toInternalNode<Spec: ARTreeSpec>() -> any InternalNode<Spec> {
    switch type {
    case .node4:
      return Node4<Spec>(buffer: storage)
    case .node16:
      return Node16<Spec>(buffer: storage)
    case .node48:
      return Node48<Spec>(buffer: storage)
    case .node256:
      return Node256<Spec>(buffer: storage)
    default:
      assert(false, "leaf nodes are not internal nodes")
    }
  }

  func toLeafNode<Spec: ARTreeSpec>() -> NodeLeaf<Spec> {
    assert(type == .leaf)
    return NodeLeaf(buffer: storage)
  }

  func toManagedNode<Spec: ARTreeSpec>() -> any ManagedNode<Spec> {
    switch type {
    case .leaf:
      return toLeafNode()
    default:
      return toInternalNode()
    }
  }
}
