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

extension _Node {
  @usableFromInline
  internal struct Header {
    @inlinable
    internal init(
      capacity: Int,
      count: Int,
      subtreeCount: Int,
      depth: Int,
      values: UnsafeMutablePointer<Value>?,
      children: UnsafeMutablePointer<_Node<Key, Value>>?
    ) {
      self._internalCounts = 0
      self.values = values
      self.children = children
      self.subtreeCount = subtreeCount
      
      self.capacity = capacity
      self.count = count
      self.depth = depth
    }
    
    /// Packed integer to store all node counts.
    ///
    /// This is represented as:
    ///
    ///              subtreeCount
    ///              vvvvvvv
    ///     0x0000000FFFFFFF00
    ///       ^^^^^^^       ^^
    ///       count         depth
    ///
    @usableFromInline
    internal var _internalCounts: UInt64
    
    /// Refers to the amount of keys in the node.
    @inlinable
    @inline(__always)
    internal var count: Int {
      get { Int((_internalCounts & 0xFFFFFFF000000000) >> 40) }
      set {
        assert(0 <= newValue && newValue <= 0xFFFFFFF, "Invalid count.")
        assert(newValue <= capacity, "Count cannot exceed capacity.")
        _internalCounts &= ~0xFFFFFFF000000000
        _internalCounts |= UInt64(newValue) << 40
      }
    }
    
    /// The total amount of keys possible to store within the node.
    @inlinable
    @inline(__always)
    internal var capacity: Int {
      get { Int((_internalCounts & 0x0000000FFFFFFF00) >> 8) }
      set {
        assert(0 <= newValue && newValue <= 0xFFFFFFF, "Invalid capacity.")
        assert(newValue >= count, "Capacity cannot be below count.")
        _internalCounts &= ~0x0000000FFFFFFF00
        _internalCounts |= UInt64(newValue) << 8
      }
    }
    
    /// The depth of the node represented as the number of nodes below the current one.
    @inlinable
    @inline(__always)
    internal var depth: Int {
      get { Int(_internalCounts & 0x00000000000000FF) }
      set {
        assert(0 <= newValue && newValue <= 0xFF, "Invalid depth.")
        _internalCounts &= ~0x00000000000000FF
        _internalCounts |= UInt64(newValue)
      }
    }
    
    /// The total amount of elements contained underneath this node
    @usableFromInline
    internal var subtreeCount: Int
    
    /// Pointer to the buffer containing the corresponding values.
    @usableFromInline
    internal var values: UnsafeMutablePointer<Value>?
    
    /// Pointer to the buffer containing the elements.
    @usableFromInline
    internal var children: UnsafeMutablePointer<_Node<Key, Value>>?
  }
  
  /// Represents the underlying data for a node.
  ///
  /// Generally, this shouldn't be directly accessed. However, in performance-critical code where operating
  /// on a ``_Node`` may create unwanted ARC traffic, or other concern, this provides a few low-level
  /// and unsafe APIs for operations.
  ///
  /// A node contains a tail-allocated contiguous buffer of keys, and also may maintain pointers to buffers
  /// for the corresponding values and children.
  ///
  /// There are two types of nodes distinguished "leaf" and "internal" nodes. Leaf nodes do not have a
  /// buffer allocated for their children in the underlying storage class.
  ///
  /// Additionally, a node does not have a value buffer allocated in some cases. Specifically, when the
  /// value type is `Void`, no value buffer is allocated. ``_Node.hasValues`` can be used to check
  /// whether a value buffer exists for a given set of generic parameters. Additionally, when a value buffer
  /// does not exist, ``_Node.dummyValue`` can be used to obtain a valid value within the type system
  /// that can be passed to APIs.
  @usableFromInline
  internal class Storage: ManagedBuffer<_Node.Header, Key> {    
    /// Allows **read-only** access to the underlying data behind the node.
    ///
    /// - Parameter body: A closure with a handle which allows interacting with the node
    /// - Returns: The value the closure body returns, if any.
    @inlinable
    @inline(__always)
    internal func read<R>(_ body: (UnsafeHandle) throws -> R) rethrows -> R {
      return try self.withUnsafeMutablePointers { header, keys in
        let handle = UnsafeHandle(
          keys: keys,
          values: header.pointee.values,
          children: header.pointee.children,
          header: header,
          isMutable: false
        )
        return try body(handle)
      }
    }
    
    /// Dangerously allows **mutable** access to the underlying data behind the node.
    ///
    /// This does **not** perform CoW checks and so when calling this, one must be certain that the
    /// storage class is indeed unique. Generally this is the wrong function to call, and should only be used
    /// when the callee has created and is guaranteed to be the only owner during the execution of the
    /// update callback, _and_ it has been identified that ``_Node.update(_:)`` or other alternatives
    /// result in noticeable slow-down.
    ///
    /// - Parameter body: A closure with a handle which allows interacting with the node
    /// - Returns: The value the closure body returns, if any.
    /// - Warning: The underlying storage **must** be unique.
    @inlinable
    @inline(__always)
    internal func updateGuaranteedUnique<R>(
      _ body: (UnsafeHandle) throws -> R
    ) rethrows -> R {
      try self.read { try body(UnsafeHandle(mutating: $0)) }
    }
    
    /// Creates a new storage object.
    ///
    /// It is generally recommend to use the ``_Node.init(withCapacity:, isLeaf:)``
    /// initializer instead to create a new node.
    @inlinable
    @inline(__always)
    internal static func create(
      withCapacity capacity: Int,
      isLeaf: Bool
    ) -> Storage {
      let storage = Storage.create(minimumCapacity: capacity) { _ in
        Header(
          capacity: capacity,
          count: 0,
          subtreeCount: 0,
          depth: 0,
          values:
            Value.self == Void.self ? nil
            : UnsafeMutablePointer<Value>.allocate(capacity: capacity),
          children: isLeaf ? nil
            : UnsafeMutablePointer<_Node>.allocate(capacity: capacity + 1)
        )
      }
      
      return unsafeDowncast(storage, to: Storage.self)
    }
    
    /// Copies an existing storage to a new storage.
    ///
    /// It is generally recommended to use the ``_Node.init(copyingFrom:)`` initializer.
    @inlinable
    @inline(__always)
    internal func copy() -> Storage {
      let capacity = self.header.capacity
      let count = self.header.count
      let subtreeCount = self.header.subtreeCount
      let depth = self.header.depth
      let isLeaf = self.header.children == nil
      
      let newStorage = Storage.create(withCapacity: capacity, isLeaf: isLeaf)
      
      newStorage.header.count = count
      newStorage.header.subtreeCount = subtreeCount
      newStorage.header.depth = depth
      
      self.withUnsafeMutablePointerToElements { oldKeys in
        newStorage.withUnsafeMutablePointerToElements { newKeys in
          newKeys.initialize(from: oldKeys, count: count)
        }
      }
      
      if _Node.hasValues {
        newStorage.header.values.unsafelyUnwrapped
          .initialize(
            from: self.header.values.unsafelyUnwrapped,
            count: count
          )
      }
      
      newStorage.header.children?
        .initialize(
          from: self.header.children.unsafelyUnwrapped,
          count: count + 1
        )
      
      return newStorage
    }
    
    @inlinable
    deinit {
      self.withUnsafeMutablePointers { header, elements in
        let count = header.pointee.count
        
        if _Node.hasValues {
          let values = header.pointee.values.unsafelyUnwrapped
          values.deinitialize(count: count)
          values.deallocate()
        }
        
        
        if let children = header.pointee.children {
          children.deinitialize(count: count + 1)
          children.deallocate()
        }
        
        elements.deinitialize(count: header.pointee.count)
      }
    }
  }
}
