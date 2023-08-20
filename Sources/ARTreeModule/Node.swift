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

protocol ManagedNode: NodePrettyPrinter {
  typealias Storage = NodeStorage<Self>
  typealias ChildSlotPtr = UnsafeMutablePointer<RawNode?>

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
  func child(at: Index) -> RawNode?

  mutating func addChild(forKey k: KeyPart, node: any ManagedNode) -> UpdateResult<RawNode?>
  mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?>

  mutating func withChildRef<R>(at index: Index, _ body: (ChildSlotPtr) -> R) -> R
}

extension ManagedNode {
  var rawNode: RawNode { RawNode(from: self) }
  var type: NodeType { Self.type }
}

struct NodeReference {
  var _ptr: InternalNode.ChildSlotPtr

  init(_ ptr: InternalNode.ChildSlotPtr) {
    self._ptr = ptr
  }
}

extension NodeReference {
  var pointee: RawNode? {
    @inline(__always) get { _ptr.pointee }
    @inline(__always) set {
      _ptr.pointee = newValue
    }
  }
}

enum UpdateResult<T> {
  case noop
  case replaceWith(T)
}

extension InternalNode {
  mutating func child(forKey k: KeyPart, ref: inout NodeReference) -> RawNode? {
    if count == 0 {
      return nil
    }

    return index(forKey: k).flatMap { index in
      self.withChildRef(at: index) { ptr in
        ref = NodeReference(ptr)
        return ptr.pointee
      }
    }
  }

  mutating func updateChild(forKey k: KeyPart, body: (RawNode?) -> UpdateResult<RawNode?>)
    -> UpdateResult<RawNode?> {

    guard let childPosition = index(forKey: k) else {
      return .noop
    }

    let ref = withChildRef(at: childPosition) { $0 }
    let child = child(at: childPosition)
    switch body(child) {
    case .noop:
      return .noop
    case .replaceWith(nil):
      let shouldDeleteMyself = count == 1
      switch deleteChild(at: childPosition) {
      case .noop:
        return .noop
      case .replaceWith(nil) where shouldDeleteMyself:
        return .replaceWith(nil)
      case .replaceWith(let newValue):
        return .replaceWith(newValue)
      }
    case .replaceWith(let newValue):
      ref.pointee = newValue
      return .noop
    }
  }
}
