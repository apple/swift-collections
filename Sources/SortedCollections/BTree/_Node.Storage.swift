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
      values: _Node<Key, Value>.Buffer<Value>,
      children: _Node<Key, Value>.Buffer<_Node<Key, Value>>?
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
    internal var values: Buffer<Value>
    
    /// Pointer to the buffer containing the elements.
    @usableFromInline
    internal var children: Buffer<_Node<Key, Value>>?
  }
  
  /// Represents the underlying data for a node in the heap.
  @usableFromInline
  internal class Storage: ManagedBuffer<_Node.Header, Key> {
    @inlinable
    deinit {
      self.withUnsafeMutablePointers { header, elements in
        _ = header.pointee.values.withUnsafeMutablePointerToElements { values in
          values.deinitialize(count: header.pointee.count)
        }
        
        _ = header.pointee.children?.withUnsafeMutablePointerToElements { children in
          children.deinitialize(count: header.pointee.count + 1)
        }
        
        elements.deinitialize(count: header.pointee.count)
      }
    }
  }
}
