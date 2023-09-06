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

  func child(forKey k: KeyPart) -> RawNode?  // TODO: Remove
  func child(at: Index) -> RawNode?  // TODO: Remove

  mutating func addChild(forKey k: KeyPart, node: RawNode) -> UpdateResult<RawNode?>
  mutating func addChild(forKey k: KeyPart, node: some ArtNode<Spec>) -> UpdateResult<RawNode?>

  mutating func removeChild(at index: Index) -> UpdateResult<RawNode?>

  mutating func withChildRef<R>(at index: Index, _ body: (RawNode.SlotRef) -> R) -> R
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
    @inline(__always) set { _ptr.pointee = newValue }
  }
}

extension InternalNode {
  var partialLength: Int {
    get {
      storage.withHeaderPointer {
        Int($0.pointee.partialLength)
      }
    }
    set {
      assert(newValue <= Const.maxPartialLength)
      storage.withHeaderPointer {
        $0.pointee.partialLength = KeyPart(newValue)
      }
    }
  }

  var partialBytes: PartialBytes {
    get {
      storage.withHeaderPointer {
        $0.pointee.partialBytes
      }
    }
    set {
      storage.withHeaderPointer {
        $0.pointee.partialBytes = newValue
      }
    }
  }

  var count: Int {
    get {
      storage.withHeaderPointer {
        Int($0.pointee.count)
      }
    }
    set {
      storage.withHeaderPointer {
        $0.pointee.count = UInt16(newValue)
      }
    }
  }

  func child(forKey k: KeyPart) -> RawNode? {
    return index(forKey: k).flatMap { child(at: $0) }
  }

  mutating func addChild(forKey k: KeyPart, node: some ArtNode<Spec>) -> UpdateResult<RawNode?> {
    return addChild(forKey: k, node: node.rawNode)
  }

  mutating func copyHeader(from: any InternalNode) {
    self.storage.withHeaderPointer { header in
      header.pointee.count = UInt16(from.count)
      header.pointee.partialLength = UInt8(from.partialLength)
      header.pointee.partialBytes = from.partialBytes
    }
  }

  // Calculates the index at which prefix mismatches.
  func prefixMismatch(withKey key: Key, fromIndex depth: Int) -> Int {
    assert(partialLength <= Const.maxPartialLength, "partial length is always bounded")
    let maxComp = min(partialLength, key.count - depth)

    for index in 0..<maxComp {
      if partialBytes[index] != key[depth + index] {
        return index
      }
    }

    return maxComp
  }

  // TODO: Look everywhere its used, and try to avoid unnecessary RC traffic.
  static func retainChildren(_ children: Children, count: Int) {
    for idx in 0..<count {
      if let c = children[idx] {
        _ = Unmanaged.passRetained(c.buf)
      }
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension InternalNode {
  mutating func maybeReadChild<R>(
    forKey k: KeyPart,
    ref: inout NodeReference,
    _ body: (any ArtNode<Spec>, Bool) -> R
  ) -> R? {
    if count == 0 {
      return nil
    }

    return index(forKey: k).flatMap { index in
      self.withChildRef(at: index) { ptr in
        ref = NodeReference(ptr)
        return body(ptr.pointee!.toArtNode(), ptr.pointee!.isUnique)
      }
    }
  }
}

enum UpdateResult<T> {
  case noop
  case replaceWith(T)
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension InternalNode {
  @inline(__always)
  fileprivate mutating func withSelfOrClone<R>(
    isUnique: Bool,
    _ body: (any InternalNode<Spec>) -> R
  ) -> R {
    if isUnique {
      return body(self)
    }

    let clone = clone()
    let node: any InternalNode<Spec> = clone.node
    return body(node)
  }

  mutating func updateChild(
    forKey k: KeyPart,
    isUniquePath: Bool,
    body: (inout RawNode?, Bool) -> UpdateResult<RawNode?>
  )
    -> UpdateResult<RawNode?>
  {

    guard let childPosition = index(forKey: k) else {
      return .noop
    }

    let isUnique = isUniquePath && withChildRef(at: childPosition) { $0.pointee!.isUnique }
    var child = child(at: childPosition)
    let action = body(&child, isUnique)

    // TODO: This is ugly. Rewrite.
    switch action {
    case .noop:
      // No action asked to be executed from body.
      return .noop

    case .replaceWith(nil) where self.count == 1:
      // Body asked to remove the last child. So just delete ourselves too.
      return .replaceWith(nil)

    case .replaceWith(nil):
      // Body asked to remove the child. Removing the child can lead to these situations:
      // - Remove successful. No more action need.
      // - Remove successful, but that left us with one child, and we can apply
      //   path compression right now.
      // - Remove successful, but we can shrink ourselves now with newValue.
      return withSelfOrClone(isUnique: isUnique) {
        var selfRef = $0
        switch selfRef.removeChild(at: childPosition) {
        case .noop:
          // Child removed successfully, nothing to do. Keep ourselves.
          return .replaceWith(selfRef.rawNode)

        case .replaceWith(let newValue?):
          if newValue.type != .leaf && selfRef.count == 1 {
            assert(selfRef.type == .node4, "only node4 can have count = 1")
            let slf: Node4<Spec> = selfRef as! Node4<Spec>
            var node: any InternalNode<Spec> = newValue.toInternalNode()
            node.partialBytes.shiftRight()
            node.partialBytes[0] = slf.keys[0]
            node.partialLength += 1
          }
          return .replaceWith(newValue)

        case .replaceWith(nil):
          fatalError("unexpected state: removeChild should not be called with count == 1")
        }
      }

    case .replaceWith(let newValue?):
      // Body asked to replace the child, with a new one. Wont affect
      // the self count.
      return withSelfOrClone(isUnique: isUnique) {
        var selfRef = $0
        selfRef.withChildRef(at: childPosition) {
          $0.pointee = newValue
        }
        return .replaceWith(selfRef.rawNode)
      }
    }
  }
}
