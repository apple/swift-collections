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

protocol InternalNode<Spec>: ArtNode {
  typealias Value = Spec.Value
  typealias Index = Int
  typealias Header = InternalNodeHeader
  typealias Children = UnsafeMutableBufferPointer<RawNode?>

  static var size: Int { get }

  var count: Int { get set }
  var partialLength: Int { get }
  var partialBytes: PartialBytes { get set }

  func index(forKey k: KeyPart) -> Index?
  func index() -> Index?
  func next(index: Index) -> Index?

  func child(forKey k: KeyPart) -> RawNode? // TODO: Remove
  func child(at: Index) -> RawNode? // TODO: Remove

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?>
  mutating func addChild(forKey k: KeyPart, node: some ArtNode<Spec>) -> UpdateResult<RawNode?>

  mutating func deleteChild(at index: Index) -> UpdateResult<RawNode?>

  mutating func withChildRef<R>(at index: Index, _ body: (RawNode.SlotRef) -> R) -> R
}

extension ArtNode {
  var rawNode: RawNode { RawNode(buf: self.storage.ref.takeUnretainedValue()) }
  var type: NodeType { Self.type }
}

struct NodeReference {
  var _ptr: RawNode.SlotRef

  init(_ ptr: RawNode.SlotRef) {
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
  mutating func updateChild(forKey k: KeyPart, isUnique: Bool,
                            body: (RawNode?) -> UpdateResult<RawNode?>) -> UpdateResult<RawNode?> {

    guard let childPosition = index(forKey: k) else {
      return .noop
    }

    let child = child(at: childPosition)

    // TODO: This is ugly. Rewrite.
    let action = body(child)
    if isUnique {
      switch action {
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
        withChildRef(at: childPosition) {
          $0.pointee = newValue
        }

        return .noop
      }
    } else {
      switch action {
      case .noop:
        // Key wasn't in the tree.
        return .noop
      case .replaceWith(nil) where count == 1:
        // Subtree was deleted, and that was our last child. Delete myself.
        return .replaceWith(nil)
      case .replaceWith(nil):
        // Clone myself and remove the child from the clone.
        return self.clone().update { myClone in
          switch myClone.deleteChild(at: childPosition) {
          case .noop:
            return .replaceWith(myClone.rawNode)
          case .replaceWith(nil):
            fatalError("unexpected state: should be handled in branch where count == 1")
          case .replaceWith(let newValue):
            // Our clone got shrunk down after delete.
            return .replaceWith(newValue)
          }
        }
      case .replaceWith(let newValue):
        // Clone myself and update the subtree.
        return clone().update { clone in
          clone.withChildRef(at: childPosition) {
            $0.pointee = newValue
          }
          return .replaceWith(clone.rawNode)
        }
      }
    }
  }
}
