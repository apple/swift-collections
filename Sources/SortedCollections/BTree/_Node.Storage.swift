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
      totalElements: Int,
      values: UnsafeMutablePointer<Value>,
      children: UnsafeMutablePointer<_Node<Key, Value>>?
    ) {
      self.capacity = capacity
      self.count = count
      self.values = values
      self.children = children
      self.subtreeCount = totalElements
    }
    
    @usableFromInline
    internal var capacity: Int
    
    /// Refers to the amount of keys in the node.
    @usableFromInline
    internal var count: Int
    
    /// The total amount of elements contained underneath this node
    @usableFromInline
    internal var subtreeCount: Int
    
    /// Pointer to the buffer containing the corresponding values.
    @usableFromInline
    internal var values: UnsafeMutablePointer<Value>
    
    /// Pointer to the buffer containing the elements.
    @usableFromInline
    internal var children: UnsafeMutablePointer<_Node<Key, Value>>?
  }
  
  /// Represents the underlying data for a node in the heap.
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
    
    /// Allows **mutable** access to the underlying data behind the node.
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
    
    /// Creates a new storage instance
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
          totalElements: 0,
          values: UnsafeMutablePointer<Value>.allocate(capacity: capacity),
          children: isLeaf ? nil
            : UnsafeMutablePointer<_Node>.allocate(capacity: capacity + 1)
        )
      }
      
      return unsafeDowncast(storage, to: Storage.self)
    }
    
    /// Copies an existing storage to a new storage
    @inlinable
    @inline(__always)
    internal func copy() -> Storage {
      let capacity = self.header.capacity
      let count = self.header.count
      let totalElements = self.header.subtreeCount
      let isLeaf = self.header.children == nil
      
      let newStorage = Storage.create(withCapacity: capacity, isLeaf: isLeaf)
      
      newStorage.header.count = count
      newStorage.header.subtreeCount = totalElements
      
      self.withUnsafeMutablePointerToElements { oldKeys in
        newStorage.withUnsafeMutablePointerToElements { newKeys in
          newKeys.initialize(from: oldKeys, count: count)
        }
      }
      
      newStorage.header.values
        .initialize(from: self.header.values, count: count)
      
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
        header.pointee.values.deallocate()
        header.pointee.children?.deallocate()
        
        elements.deinitialize(count: header.pointee.count)
      }
    }
  }
}
