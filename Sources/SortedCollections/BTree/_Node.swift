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

/// A single node within a B-Tree, containing keys, values, and children.
///
/// A node is merely struct wrapper of the ``_Node.Storage`` class. This does not and should not
/// contain any other properties. By using a ``_Node`` over the underlying storage class, operations can
/// be performed with automatic copy-on-write (CoW) checks such as through the ``update(_:)``
/// method.
///
/// Refer to ``_Node.Storage`` for more information on the allocation and structure of the underlying
/// buffers of a node.
///
/// You cannot operate or read directly from a node. Instead use `read(_:)` and `update(_:)` to make
/// modifications to a node.
///
///     let nodeMedian = node.read { handle in
///       let medianSlot = handle.elementCount
///       return handle[elementAt: medianSlot]
///     }
///
/// Refer to ``_Node.UnsafeHandle`` for the APIs available when operating on a node in such a
/// manner.
@usableFromInline
internal struct _Node<Key: Comparable, Value> {
  @usableFromInline
  typealias Element = (key: Key, value: Value)
  
  /// An optional parameter to the storage. Use ``storage`` instead
  ///
  /// This will never be `nil` during a valid access of ``_Node``. However, to support moving the
  /// underlying storage instance for internal and unsafe operations, this is made optional as an
  /// implementation artifact.
  @usableFromInline
  internal var _storage: Storage?
  
  /// Strong reference to the node's underlying data
  @inlinable
  @inline(__always)
  internal var storage: Storage { _storage.unsafelyUnwrapped }
  
  /// An instance of a ``_Node`` with no underlying storage allocated.
  ///
  /// Use this when you need a dummy node. It is invalid to ever attempt to read or write to this node.
  @inlinable
  @inline(__always)
  internal static var dummy: _Node {
    _Node(_underlyingStorage: nil)
  }
  
  /// Creates a node with a potentially empty underlying storage.
  @inlinable
  @inline(__always)
  internal init(_underlyingStorage storage: Storage?) {
    self._storage = storage
  }
  
  /// Creates a node wrapping a Storage object in order to interact with it.
  /// - Parameter storage: Underlying node storage.
  @inlinable
  @inline(__always)
  internal init(_ storage: Storage) {
    self._storage = storage
  }
  
  /// Creates a new node from a left, right, and separator.
  @inlinable
  internal init(
    leftChild: __owned _Node,
    separator: __owned Element,
    rightChild: __owned _Node,
    capacity: Int
  ) {
    assert(
      leftChild.storage.header.depth == rightChild.storage.header.depth,
      "Left and right nodes of a splinter must have equal depth"
    )
    
    self.init(withCapacity: capacity, isLeaf: false)
    self.storage.updateGuaranteedUnique { handle in
      handle.keys.initialize(to: separator.key)
      if _Node.hasValues {
        handle.values.unsafelyUnwrapped.initialize(to: separator.value)
      }
      
      handle.children.unsafelyUnwrapped.initialize(to: leftChild)
      handle.children.unsafelyUnwrapped.advanced(by: 1).initialize(to: rightChild)
      
      handle.elementCount = 1
      handle.subtreeCount = 1 +
        leftChild.storage.header.subtreeCount +
        rightChild.storage.header.subtreeCount
      handle.depth = leftChild.storage.header.depth + 1
    }
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

// MARK: Join Subroutine
extension _Node {
  /// Joins the current node with another node of potentially differing depths.
  ///
  /// If you know that your nodes are the same depth, then use
  /// ``_Node.UnsafeHandle.concatenateWith(node:separatedBy:)``.
  ///
  /// - Parameters:
  ///   - leftNode:A well-formed node with elements less than or equal to `separator`. This
  ///       node is **consumed and invalided** when this method is called.
  ///   - rightNode: A well-formed node with elements greater than or equal to `separator`. This
  ///       node is **consumed and invalided** when this method is called.
  ///   - separator: An element greater than or equal to all elements in the current node.
  /// - Returns: A new node containing both the right and left node combined. This may or may not be
  ///     referentially identical to one of the old nodes.
  @inlinable
  internal static func join(
    _ leftNode: inout _Node,
    with rightNode: inout _Node,
    separatedBy separator: __owned _Node.Element,
    capacity: Int
  ) -> _Node {
    let leftNodeDepth = leftNode.storage.header.depth
    let leftNodeSubtreeCount = leftNode.storage.header.subtreeCount
    let rightNodeDepth = rightNode.storage.header.depth
    let rightNodeSubtreeCount = rightNode.storage.header.subtreeCount
    
    func prepending(
      atDepth depth: Int,
      onto node: inout _Node
    ) -> _Node.Splinter? {
      if depth == 0 {
        let splinter = leftNode.update {
          $0.concatenateWith(node: &node, separatedBy: separator)
        }
        node = leftNode
        return splinter
      } else {
        return node.update { handle in
          let splinter = prepending(atDepth: depth - 1, onto: &handle[childAt: 0])
          handle.subtreeCount += leftNodeSubtreeCount
          if let splinter = splinter {
            return handle.insertSplinter(splinter, atSlot: 0)
          } else {
            handle.subtreeCount += 1
            return nil
          }
        }
      }
    }
    
    func appending(
      atDepth depth: Int,
      onto node: _Node.UnsafeHandle
    ) -> _Node.Splinter? {
      assert(node.depth >= depth, "Cannot graft at a depth deeper than the node.")
      
      if depth == 0 {
        // Graft at the current node
        return node.concatenateWith(node: &rightNode, separatedBy: separator)
      } else {
        let endSlot = node.childCount - 1
        let splinter = node[childAt: endSlot].update {
          appending(atDepth: depth - 1, onto: $0)
        }
          
        node.subtreeCount += rightNodeSubtreeCount
        
        if let splinter = splinter {
          return node.insertSplinter(splinter, atSlot: endSlot)
        } else {
          node.subtreeCount += 1
          return nil
        }
      }
    }
    
    if leftNodeDepth >= rightNodeDepth {
      let splinter = leftNode.update {
        appending(atDepth: leftNodeDepth - rightNodeDepth, onto: $0)
      }
      if let splinter = splinter {
        return splinter.toNode(leftChild: leftNode, capacity: capacity)
      } else {
        return leftNode
      }
    } else {
      let splinter = prepending(atDepth: rightNodeDepth - leftNodeDepth, onto: &rightNode)
      if let splinter = splinter {
        return splinter.toNode(leftChild: rightNode, capacity: capacity)
      } else {
        return rightNode
      }
    }
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
  /// Whether two nodes are the same underlying reference in memory.
  /// - Warning: This **does not** compare the keys at all.
  @inlinable
  @inline(__always)
  internal static func ==(lhs: _Node, rhs: _Node) -> Bool {
    return lhs.storage === rhs.storage
  }
}

