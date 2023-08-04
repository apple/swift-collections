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

struct ChildPointers {
  private var childs: UnsafeMutableBufferPointer<Int>

  init(ptr: UnsafeMutableRawPointer) {
    self.childs = UnsafeMutableBufferPointer(
      start: ptr.assumingMemoryBound(to: Int.self),
      count: 256
    )
    for idx in 0..<256 {
      childs[idx] = 0
    }
  }

  subscript(key: UInt8) -> NodePtr? {
    get {
      NodePtr(bitPattern: childs[Int(key)])
    }

    set {
      if let ptr = newValue {
        childs[Int(key)] = Int(bitPattern: UnsafeRawPointer(ptr))
      } else {
        childs[Int(key)] = 0
      }
    }
  }
}

struct Node256 {
  var pointer: NodePtr
  var childs: UnsafeMutableBufferPointer<NodePtr?>

  init(ptr: NodePtr) {
    self.pointer = ptr
    let body = ptr + MemoryLayout<NodeHeader>.stride
    self.childs = UnsafeMutableBufferPointer(
      start: body.assumingMemoryBound(to: NodePtr?.self),
      count: 256
    )
  }
}

extension Node256 {
  static func allocate() -> Node256 {
    let buf = NodeBuffer.allocate(type: .node256, size: size)
    return Node256(ptr: buf)
  }

  static func allocate(copyFrom: Node48) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)
    for key in 0..<256 {
      let slot = Int(copyFrom.keys[key])
      if slot < 0xFF {
        node.childs[key] = copyFrom.childs[slot]
      }
    }
    assert(node.count == 48, "should have exactly 48 childs")
    return node
  }

  static var size: Int {
    MemoryLayout<NodeHeader>.stride + 256 * MemoryLayout<NodePtr>.stride
  }
}

extension Node256: Node {
  func type() -> NodeType { .node256 }

  func index(forKey k: KeyPart) -> Index? {
    return childs[Int(k)] != nil ? Int(k) : nil
  }

  func index() -> Index? {
    return next(index: -1)
  }

  func next(index: Index) -> Index? {
    for idx in index + 1..<256 {
      if childs[idx] != nil {
        return idx
      }
    }

    return nil
  }

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> NodePtr? {
    ref = childs.baseAddress! + Int(k)
    return childs[Int(k)]
  }

  func child(at: Int) -> NodePtr? {
    assert(at < 256, "maximum 256 childs allowed")
    return childs[at]
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> NodePtr? {
    assert(index < 256, "maximum 256 childs allowed")
    ref = childs.baseAddress! + index
    return childs[index]
  }

  mutating func addChild(
    forKey k: KeyPart,
    node: NodePtr,
    ref: ChildSlotPtr?
  ) {
    assert(self.childs[Int(k)] == nil, "node for key \(k) already exists")
    self.childs[Int(k)] = node
    count += 1
  }

  public mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    childs[index]?.deallocate()
    childs[index] = nil
    count -= 1

    if count == 40 {
      let newNode = Node48.allocate(copyFrom: self)
      ref?.pointee = newNode.pointer
      pointer.deallocate()
    }
  }
}
