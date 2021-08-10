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
  internal var storage: Storage { _storage.unsafelyUnwrapped }
  
  /// Creates a node wrapping a Storage object in order to interact with it.
  /// - Parameter storage: Underlying node storage.
  @inlinable
  @inline(__always)
  internal init(_ storage: Storage) {
    self._storage = storage
  }
  
  /// Creates a new node with values modified by a transformation closure
  @inlinable
  @inline(__always)
  internal init<T>(
    mappingFrom existingNode: _Node<Key, T>,
    _ transform: (T) throws -> Value
  ) rethrows {
    let isLeaf = existingNode.storage.header.children == nil
    _storage = .create(
      withCapacity: existingNode.storage.header.capacity,
      isLeaf: isLeaf
    )
    
    let elementCount = existingNode.storage.header.count
    storage.header.count = elementCount
    storage.header.subtreeCount = existingNode.storage.header.subtreeCount
    
    storage.withUnsafeMutablePointerToElements { keys in
      existingNode.storage.withUnsafeMutablePointerToElements { sourceKeys in
        keys.initialize(from: sourceKeys, count: existingNode.storage.header.count)
      }
    }
    
    for i in 0..<elementCount {
      if _Node.hasValues {
        let newValue = try transform(
          existingNode.storage.header.values?.advanced(by: i).pointee
            ?? _Node<Key, T>.dummyValue
        )
        
        storage.header.values.unsafelyUnwrapped
          .advanced(by: i)
          .initialize(to: newValue)
      }
      
      if !isLeaf {
        let oldChild = existingNode.storage.header
          .children.unsafelyUnwrapped
          .advanced(by: i)
          .pointee
        
        storage.header.children.unsafelyUnwrapped
          .advanced(by: i)
          .initialize(to: try _Node(mappingFrom: oldChild, transform))
      }
    }
    
    if !isLeaf {
      let oldChild = existingNode.storage.header
        .children.unsafelyUnwrapped
        .advanced(by: elementCount)
        .pointee
      
      storage.header.children.unsafelyUnwrapped
        .advanced(by: elementCount)
        .initialize(to: try _Node(mappingFrom: oldChild, transform))
    }
  }
  
  /// Creates a node which copies the storage of an existing node.
  @inlinable
  @inline(__always)
  internal init(copyingFrom oldNode: _Node) {
    self._storage = oldNode.storage.copy()
  }
  
  /// Creates and allocates a new node.
  /// - Parameters:
  ///   - capacity: the maximum potential size of the node.
  ///   - isLeaf: whether or not the node is a leaf (it does not have any children).
  @inlinable
  internal init(withCapacity capacity: Int, isLeaf: Bool) {
    self._storage = Storage.create(withCapacity: capacity, isLeaf: isLeaf)
  }
  
  /// Whether the B-Tree has values associated with the keys
  @inlinable
  @inline(__always)
  internal static var hasValues: Bool { _fastPath(Value.self != Void.self) }
  
  /// Dummy value for when a B-Tree does not maintain a value buffer.
  ///
  /// - Warning: Traps when used on a tree with a value buffer.
  @inlinable
  @inline(__always)
  internal static var dummyValue: Value {
    assert(!hasValues, "Cannot get dummy value on tree with value buffer.")
    return unsafeBitCast((), to: Value.self)
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
    if !isKnownUniquelyReferenced(&self._storage) {
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

