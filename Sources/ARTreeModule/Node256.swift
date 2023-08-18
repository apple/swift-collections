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

struct Node256 {
  typealias Storage = NodeStorage<Self>

  var storage: Storage

  init(ptr: RawNodeBuffer) {
      self.init(storage: Storage(ptr))
  }

  init(storage: Storage) {
      self.storage = storage
  }
}

extension Node256 {
  typealias Keys = UnsafeMutableBufferPointer<KeyPart>
  typealias Childs = UnsafeMutableBufferPointer<(any Node)?>

  func withBody<R>(body: (Childs) throws -> R) rethrows -> R {
    return try storage.withBodyPointer {
      return try body(
        UnsafeMutableBufferPointer(
          start: $0.assumingMemoryBound(to: (any Node)?.self),
          count: 256))
    }
  }
}

extension Node256 {
  static func allocate() -> Node256 {
    let buf: NodeStorage<Self> = NodeStorage.allocate()
    return Node256(storage: buf)
  }

  static func allocate(copyFrom: Node48) -> Self {
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


extension Node256: Node {
  static let type: NodeType = .node256
  var type: NodeType { .node256 }
}

extension Node256: InternalNode {
  static let numKeys: Int = 256

  static var size: Int {
    MemoryLayout<InternalNodeHeader>.stride + 256 * MemoryLayout<(any Node)?>.stride
  }

  var header: UnsafeMutablePointer<InternalNodeHeader> {
    storage.withHeaderPointer { $0 }
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

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> (any Node)? {
    return withBody { childs in
      ref = childs.baseAddress! + Int(k)
      return childs[Int(k)]
    }
  }

  func child(at: Int) -> (any Node)? {
    assert(at < 256, "maximum 256 childs allowed")
    return withBody { childs in
      return childs[at]
    }
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> (any Node)? {
    assert(index < 256, "maximum 256 childs allowed")
    return withBody { childs in
      ref = childs.baseAddress! + index
      return childs[index]
    }
  }

  mutating func addChild(
    forKey k: KeyPart,
    node: any Node,
    ref: ChildSlotPtr?
  ) {
    return withBody { childs in
      assert(childs[Int(k)] == nil, "node for key \(k) already exists")
      childs[Int(k)] = node
      count += 1
    }
  }

  public mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    return withBody { childs in
      // childs[index]?.deallocate()
      childs[index] = nil
      count -= 1

      if count == 40 {
        let newNode = Node48.allocate(copyFrom: self)
        ref?.pointee = newNode
        // pointer.deallocate()
      }
    }
  }
}
