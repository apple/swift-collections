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

typealias NodeBuffer = UnsafeMutableRawPointer

extension NodeBuffer {
  static func allocate(type: NodeType, size: Int) -> NodeBuffer {
    let size = size
    let buf = NodeBuffer.allocate(byteCount: size, alignment: Const.defaultAlignment)
    buf.initializeMemory(as: UInt8.self, repeating: 0, count: size)

    let header = buf.bindMemory(to: NodeHeader.self, capacity: MemoryLayout<NodeHeader>.stride)
    header.pointee.type = type
    header.pointee.count = 0
    header.pointee.partialLength = 0
    return buf
  }

  func asNode<Value>(of: Value.Type) -> Node? {
    switch self.type() {
    case .leaf:
      return NodeLeaf<Value>(ptr: self)
    case .node4:
      return Node4(ptr: self)
    case .node16:
      return Node16(ptr: self)
    case .node48:
      return Node48(ptr: self)
    case .node256:
      return Node256(ptr: self)
    }
  }

  func asNode4() -> Node4 {
    let type: NodeType = load(as: NodeType.self)
    assert(type == .node4, "node is not a node4")
    return Node4(ptr: self)
  }

  func asNode16() -> Node16 {
    let type: NodeType = load(as: NodeType.self)
    assert(type == .node16, "node is not a node16")
    return Node16(ptr: self)
  }

  func asNode48() -> Node48 {
    let type: NodeType = load(as: NodeType.self)
    assert(type == .node48, "node is not a node48")
    return Node48(ptr: self)
  }

  func asNode256() -> Node256 {
    let type: NodeType = load(as: NodeType.self)
    assert(type == .node256, "node is not a node256")
    return Node256(ptr: self)
  }

  func asLeaf<Value>() -> NodeLeaf<Value> {
    let type: NodeType = load(as: NodeType.self)
    assert(type == .leaf, "node is not a leaf")
    return NodeLeaf<Value>(ptr: self)
  }

  func type() -> NodeType {
    load(as: NodeType.self)
  }
}
