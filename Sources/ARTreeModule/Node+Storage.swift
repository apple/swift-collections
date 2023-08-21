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

typealias RawNodeBuffer = ManagedBuffer<NodeType, UInt8>

final class NodeBuffer<Mn: ManagedNode>: RawNodeBuffer {
  typealias Value = Mn.Value
  
  deinit {
    Mn.deinitialize(NodeStorage<Mn>(buf: self))
  }
}

struct NodeStorage<Mn: ManagedNode> {
  var buf: NodeBuffer<Mn>
}

extension NodeStorage {
  init(raw: RawNodeBuffer) {
    self.buf = raw as! NodeBuffer<Mn>
  }

  static func create(type: NodeType, size: Int) -> RawNodeBuffer {
    let buf = NodeBuffer<Mn>.create(minimumCapacity: size,
                                    makingHeaderWith: {_ in type })
    buf.withUnsafeMutablePointerToElements {
      $0.initialize(repeating: 0, count: size)
    }
    return buf
  }
}

extension NodeStorage {
  func withUnsafePointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
    return try buf.withUnsafeMutablePointerToElements {
      return try body(UnsafeMutableRawPointer($0))
    }
  }
}

extension NodeStorage where Mn: InternalNode {
  typealias Header = Mn.Header

  static func allocate() -> NodeStorage<Mn> {
    let size = Mn.size
    let buf = NodeStorage<Mn>.create(type: Mn.type, size: size)
    let storage = NodeStorage(raw: buf)
    _ = buf.withUnsafeMutablePointerToElements {
      UnsafeMutableRawPointer($0).bindMemory(to: Header.self, capacity: 1)
    }
    return storage
  }

  func withHeaderPointer<R>(_ body: (UnsafeMutablePointer<Header>) throws -> R) rethrows -> R {
    return try buf.withUnsafeMutablePointerToElements {
      return try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Header.self))
    }
  }

  func withBodyPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
    return try buf.withUnsafeMutablePointerToElements {
      return try body(UnsafeMutableRawPointer($0).advanced(by: MemoryLayout<Header>.stride))
    }
  }
}
