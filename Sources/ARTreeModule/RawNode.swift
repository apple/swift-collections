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

@usableFromInline
struct RawNode {
  var buf: RawNodeBuffer

  init(buf: RawNodeBuffer) {
    self.buf = buf
  }
}

extension RawNode {
  typealias SlotRef = UnsafeMutablePointer<RawNode?>

  var type: NodeType {
    @inline(__always) get { return buf.header }
  }

  var isUnique: Bool {
    mutating get { isKnownUniquelyReferenced(&buf) }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RawNode {
  func clone<Spec: ARTreeSpec>(spec: Spec.Type) -> RawNode {
    switch type {
    case .node4:
      return NodeStorage<Node4<Spec>>(raw: buf).clone().rawNode
    case .node16:
      return NodeStorage<Node16<Spec>>(raw: buf).clone().rawNode
    case .node48:
      return NodeStorage<Node48<Spec>>(raw: buf).clone().rawNode
    case .node256:
      return NodeStorage<Node256<Spec>>(raw: buf).clone().rawNode
    case .leaf:
      return NodeStorage<NodeLeaf<Spec>>(raw: buf).clone().rawNode
    }
  }

  func toInternalNode<Spec: ARTreeSpec>() -> any InternalNode<Spec> {
    switch type {
    case .node4:
      return Node4<Spec>(buffer: buf)
    case .node16:
      return Node16<Spec>(buffer: buf)
    case .node48:
      return Node48<Spec>(buffer: buf)
    case .node256:
      return Node256<Spec>(buffer: buf)
    default:
      assert(false, "leaf nodes are not internal nodes")
    }
  }

  func toLeafNode<Spec: ARTreeSpec>() -> NodeLeaf<Spec> {
    assert(type == .leaf)
    return NodeLeaf(buffer: buf)
  }

  func toArtNode<Spec: ARTreeSpec>() -> any ArtNode<Spec> {
    switch type {
    case .leaf:
      return toLeafNode()
    default:
      return toInternalNode()
    }
  }
}
