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
      self.totalElements = totalElements
    }
    
    @usableFromInline
    internal var capacity: Int
    
    /// Refers to the amount of keys in the node.
    @usableFromInline
    internal var count: Int
    
    /// The total amount of elements contained underneath this node
    @usableFromInline
    internal var totalElements: Int
    
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

