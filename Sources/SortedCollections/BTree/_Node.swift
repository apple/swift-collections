//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
internal struct _Node<Key: Comparable, Value> {
  @usableFromInline
  typealias Element = (key: Key, value: Value)
  
  @usableFromInline
  internal var _storage: Storage?
  
  /// Strong reference to the node's underlying data
  @inlinable
  @inline(__always)
  internal var storage: Storage {
    get { _storage.unsafelyUnwrapped }
    set { _storage = newValue }
  }
  
  /// Creates a node wrapping a Storage object in order to interact with it.
  /// - Parameter storage: Underlying node storage.
  @inlinable
  @inline(__always)
  internal init(_ storage: Storage) {
    self.storage = storage
  }
  
  /// Creates a node which copies the storage of an existing node.
  @inlinable
  @inline(__always)
  internal init(copyingFrom oldNode: _Node) {
    self.storage = oldNode.storage.copy()
  }
  
  /// Creates and allocates a new node.
  /// - Parameters:
  ///   - capacity: the maximum potential size of the node.
  ///   - isLeaf: whether or not the node is a leaf (it does not have any children).
  @inlinable
  internal init(withCapacity capacity: Int, isLeaf: Bool) {
    self.storage = Storage.create(withCapacity: capacity, isLeaf: isLeaf)
  }
}

// MARK: CoW
extension _Node {
  /// Allows **read-only** access to the underlying data behind the node.
  ///
  /// - Parameter body: A closure with a handle which allows interacting with the node
  /// - Returns: The value the closure body returns, if any.
  @inlinable
  @inline(__always)
  internal func read<R>(_ body: (UnsafeHandle) throws -> R) rethrows -> R {
    return try self.storage.read(body)
  }
  
  /// Allows mutable access to the underlying data behind the node.
  ///
  /// - Parameter body: A closure with a handle which allows interacting with the node
  /// - Returns: The value the closure body returns, if any.
  @inlinable
  @inline(__always)
  internal mutating func update<R>(
    _ body: (UnsafeHandle) throws -> R
  ) rethrows -> R {
    self.ensureUnique()
    return try self.read { handle in
      defer { handle.checkInvariants() }
      return try body(UnsafeHandle(mutating: handle))
    }
  }
  
  /// Allows mutable access to the underlying data behind the node.
  /// - Parameters:
  ///   - isUnique: Whether the node is unique or needs to be copied
  ///   - body: A closure with a handle which allows interacting with the node
  /// - Returns: The value the closure body returns, if any.
  @inlinable
  @inline(__always)
  internal mutating func update<R>(
    isUnique: Bool,
    _ body: (UnsafeHandle) throws -> R
  ) rethrows -> R {
    if !isUnique {
      self = _Node(copyingFrom: self)
    }
    
    return try self.read { handle in
      defer { handle.checkInvariants() }
      return try body(UnsafeHandle(mutating: handle))
    }
  }
  
  /// Ensure that this storage refers to a uniquely held buffer by copying
  /// elements if necessary.
  @inlinable
  internal mutating func ensureUnique() {
    if !isKnownUniquelyReferenced(&self.storage) {
      self = _Node(copyingFrom: self)
    }
  }
}

// MARK: Equatable
extension _Node: Equatable {
  @inlinable
  @inline(__always)
  internal static func ==(lhs: _Node, rhs: _Node) -> Bool {
    return lhs.storage === rhs.storage
  }
}

