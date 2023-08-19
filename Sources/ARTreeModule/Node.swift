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

public typealias KeyPart = UInt8
public typealias Key = [KeyPart]

typealias ChildSlotPtr = UnsafeMutablePointer<RawNode?>

struct RawNode {
  var storage: RawNodeBuffer
}

extension RawNode {
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

protocol ManagedNode: NodePrettyPrinter {
  static func deinitialize<N: ManagedNode>(_ storage: NodeStorage<N>)
  static var type: NodeType { get }

  var storage: NodeStorage<Self> { get }
  var type: NodeType { get }
  var rawNode: RawNode { get }
}

extension ManagedNode {
  var rawNode: RawNode { RawNode(from: self) }
}

protocol InternalNode: ManagedNode {
  typealias Index = Int
  typealias Header = InternalNodeHeader

  static var size: Int { get }

  var count: Int { get set }
  var partialLength: Int { get }
  var partialBytes: PartialBytes { get set }

  func index(forKey k: KeyPart) -> Index?
  func index() -> Index?
  func next(index: Index) -> Index?

  func child(forKey k: KeyPart) -> RawNode?
  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> RawNode?
  func child(at: Index) -> RawNode?
  func child(at index: Index, ref: inout ChildSlotPtr?) -> RawNode?

  mutating func addChild(forKey k: KeyPart, node: any ManagedNode)
  mutating func addChild(
    forKey k: KeyPart,
    node: any ManagedNode,
    ref: ChildSlotPtr?)

  // TODO: Shrinking/expand logic can be moved out.
  mutating func deleteChild(forKey k: KeyPart, ref: ChildSlotPtr?)
  mutating func deleteChild(at index: Index, ref: ChildSlotPtr?)
}

extension ManagedNode {
  static func deinitialize<N: ManagedNode>(_ storage: NodeStorage<N>) {
    // TODO
  }
}
