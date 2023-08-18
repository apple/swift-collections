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

final class NodeBuffer<ArtNode: Node>: RawNodeBuffer {
  deinit {
    ArtNode.deinitialize(NodeStorage(self))
  }
}

struct NodeStorage<ArtNode: Node> {
  typealias Header = InternalNodeHeader
  var buf: NodeBuffer<ArtNode>
}

extension NodeStorage {
  fileprivate init(_ buf: NodeBuffer<ArtNode>) {
    self.buf = buf
  }

  init(_ raw: RawNodeBuffer) {
    self.buf = unsafeDowncast(raw, to: NodeBuffer<ArtNode>.self)
  }
}

extension NodeStorage {
  static func create(type: NodeType, size: Int) -> RawNodeBuffer {
    return NodeBuffer<ArtNode>.create(minimumCapacity: size,
                                      makingHeaderWith: {_ in type })
  }
}

extension NodeStorage where ArtNode: InternalNode {
  static func allocate() -> NodeStorage<ArtNode> {
    let size = ArtNode.size
    let buf = NodeStorage<ArtNode>.create(type: ArtNode.type, size: size)
    let storage = NodeStorage(buf)
    storage.withBodyPointer { $0.initializeMemory(as: UInt8.self, repeating: 0, count: size) }
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


extension NodeStorage {
  func getPointer() -> UnsafeMutableRawPointer {
    return self.buf.withUnsafeMutablePointerToElements {
      UnsafeMutableRawPointer($0)
    }
  }
}
