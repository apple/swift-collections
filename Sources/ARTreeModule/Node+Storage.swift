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

struct NodeStorage<Mn: ManagedNode> {
  var buf: Mn.Buffer
}

extension NodeStorage {
  init(raw: RawNodeBuffer) {
    self.buf = unsafeDowncast(raw, to: Mn.Buffer.self)
  }

  static func create(type: NodeType, size: Int) -> RawNodeBuffer {
    let buf = Mn.Buffer.create(minimumCapacity: size,
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
