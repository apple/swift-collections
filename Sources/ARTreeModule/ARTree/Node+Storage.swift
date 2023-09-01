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

struct NodeStorage<Mn: ArtNode> {
  var ref: Mn.Buffer

  var node: Mn { Mn(buffer: ref) }
  var rawNode: RawNode { RawNode(buf: ref) }

  init(raw: RawNodeBuffer) {
    self.ref = unsafeDowncast(raw, to: Mn.Buffer.self)
  }
}

extension NodeStorage {
  static func create(type: NodeType, size: Int) -> NodeStorage<Mn> {
    let buf = Mn.Buffer.create(
      minimumCapacity: size,
      makingHeaderWith: { _ in type })
    buf.withUnsafeMutablePointerToElements {
      $0.initialize(repeating: 0, count: size)
    }
    return NodeStorage<Mn>(raw: buf)
  }

  func clone() -> Self {
    read { $0.clone() }
  }
}

extension NodeStorage where Mn: InternalNode {
  typealias Header = Mn.Header
  typealias Index = Mn.Index

  static func allocate() -> NodeStorage<Mn> {
    let size = Mn.size
    let buf = Self.create(type: Mn.type, size: size)
    _ = buf.ref.withUnsafeMutablePointerToElements {
      UnsafeMutableRawPointer($0).bindMemory(to: Header.self, capacity: 1)
    }
    return buf
  }

  var type: NodeType {
    read { $0.type }
  }
  var partialBytes: PartialBytes {
    get {
      read { $0.partialBytes }
    }
    set {
      update { $0.partialBytes = newValue }
    }
  }

  var partialLength: Int {
    get {
      read { $0.partialLength }
    }
    set {
      update { $0.partialLength = newValue }
    }
  }

  mutating func index(forKey k: KeyPart) -> Index? {
    read {
      $0.index(forKey: k)
    }
  }

  // TODO: Remove this so that we don't use it by mistake where `node` is invalid.
  mutating func addChild(forKey k: KeyPart, node: some ArtNode<Mn.Spec>)
    -> UpdateResult<RawNode?>
  {

    update {
      $0.addChild(forKey: k, node: node.rawNode)
    }
  }

  mutating func addChild<N>(forKey k: KeyPart, node: NodeStorage<N>)
    -> UpdateResult<RawNode?> where N.Spec == Mn.Spec
  {
    update {
      $0.addChild(forKey: k, node: node.rawNode)
    }
  }

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?> {
    update {
      $0.addChild(forKey: k, node: node)
    }
  }

  mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?> {
    update {
      $0.deleteChild(at: index)
    }
  }
}

extension NodeStorage {
  func read<R>(_ body: (Mn) throws -> R) rethrows -> R {
    try body(self.node)
  }

  func update<R>(_ body: (inout Mn) throws -> R) rethrows -> R {
    var n = self.node
    return try body(&n)
  }
}
