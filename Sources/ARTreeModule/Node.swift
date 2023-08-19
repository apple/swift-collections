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

protocol ManagedNode: NodePrettyPrinter {
  typealias Storage = NodeStorage<Self>

  static func deinitialize(_ storage: NodeStorage<Self>)
  static var type: NodeType { get }

  var storage: Storage { get }
  var type: NodeType { get }
  var rawNode: RawNode { get }
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

  mutating func addChild(forKey k: KeyPart, node: any ManagedNode) -> UpdateResult<RawNode?>
  mutating func deleteChild(forKey k: KeyPart) -> UpdateResult<RawNode?>
  mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?>
}

extension ManagedNode {
  var rawNode: RawNode { RawNode(from: self) }
  var type: NodeType { Self.type }
}

enum UpdateResult<T> {
  case noop
  case replaceWith(T)
}

extension InternalNode {
  mutating func updateChild(forKey k: KeyPart, body: (RawNode?) -> UpdateResult<RawNode?>)
    -> UpdateResult<RawNode?> {

    var ref: ChildSlotPtr?
    let child = child(forKey: k, ref: &ref)
    switch body(child) {
    case .noop:
      return .noop
    case .replaceWith(nil):
      let shouldDeleteMyself = count == 1
      switch deleteChild(forKey: k) {
      case .noop:
        return .noop
      case .replaceWith(nil) where shouldDeleteMyself:
        return .replaceWith(nil)
      case .replaceWith(let newValue):
        return .replaceWith(newValue)
      }
    case .replaceWith(let newValue):
      ref?.pointee = newValue
      return .noop
    }
  }
}
