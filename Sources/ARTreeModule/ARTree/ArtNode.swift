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

protocol ArtNode<Spec> {
  associatedtype Spec: ARTreeSpec
  associatedtype Buffer: RawNodeBuffer

  typealias Value = Spec.Value
  typealias Storage = UnmanagedNodeStorage<Self>

  static var type: NodeType { get }

  var storage: Storage { get }
  var type: NodeType { get }
  var rawNode: RawNode { get }

  func clone() -> NodeStorage<Self>

  init(storage: Storage)
}

extension ArtNode {
  init(buffer: RawNodeBuffer) {
    self.init(storage: Self.Storage(raw: buffer))
  }
}

extension ArtNode {
  var rawNode: RawNode { RawNode(buf: self.storage.ref.takeUnretainedValue()) }
  var type: NodeType { Self.type }
}

extension ArtNode {
  func equals(_ other: any ArtNode<Spec>) -> Bool {
    return self.rawNode == other.rawNode
  }
}
