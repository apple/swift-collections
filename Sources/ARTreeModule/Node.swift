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

typealias ChildSlotPtr = UnsafeMutablePointer<(any Node)?>

/// Shared protocol implementation for Node types in an Adaptive Radix Tree
protocol Node: NodePrettyPrinter {
  associatedtype Header

  var storage: NodeStorage<Self> { get }
  var type: NodeType { get }
}

protocol InternalNode: Node {
  typealias Index = Int
  typealias Header = InternalNodeHeader

  static var type: NodeType { get }
  static var size: Int { get }

  var header: UnsafeMutablePointer<InternalNodeHeader> { get }

  var count: Int { get set }
  var partialLength: Int { get }
  var partialBytes: PartialBytes { get set }

  func index(forKey k: KeyPart) -> Index?
  func index() -> Index?
  func next(index: Index) -> Index?

  func child(forKey k: KeyPart) -> (any Node)?
  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> (any Node)?
  func child(at: Index) -> (any Node)?
  func child(at index: Index, ref: inout ChildSlotPtr?) -> (any Node)?

  mutating func addChild(forKey k: KeyPart, node: any Node)
  mutating func addChild(
    forKey k: KeyPart,
    node: any Node,
    ref: ChildSlotPtr?)

  // TODO: Shrinking/expand logic can be moved out.
  mutating func deleteChild(forKey k: KeyPart, ref: ChildSlotPtr?)
  mutating func deleteChild(at index: Index, ref: ChildSlotPtr?)
}

extension Node {
  static func deinitialize<AdaptiveNode: Node>(_ storage: NodeStorage<AdaptiveNode>) {
    // TODO
  }
}
