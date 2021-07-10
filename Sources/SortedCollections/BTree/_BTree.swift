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

// TODO: decide node capacity. Currently exploring 470 v 1050
// TODO: better benchmarking here

/// Internal node capacity for BTree
@usableFromInline
internal let BTREE_INTERNAL_CAPACITY = 16

/// Leaf node capacity for BTree
@usableFromInline
internal let BTREE_LEAF_CAPACITY = 470

/// An expected rough upper bound for BTree depth
@usableFromInline
internal let BTREE_MAX_DEPTH = 10

/// A bidirectional collection representing a BTree which efficiently stores its
/// elements in sorted order and maintains roughly `O(log count)`
/// performance for most operations.
///
/// - Warning: Indexing operations on a BTree are unchecked. ``_BTree.Index``
///   offers `ensureValid(for:)` methods to validate indices for use in higher-level
///   collections.
@usableFromInline
internal struct _BTree<Key: Comparable, Value> {
  @usableFromInline
  typealias Element = (key: Key, value: Value)
  
  @usableFromInline
  typealias Node = _Node<Key, Value>
  
  /// The underlying node behind this local BTree
  @usableFromInline
  internal var root: Node
  
  // TODO: remove
  /// The capacity of each of the internal nodes
  @usableFromInline
  internal var internalCapacity: Int
  
  /// A metric to uniquely identify a given BTree's state. It is not
  /// impossible for two BTrees to have the same age by pure
  /// coincidence.
  @usableFromInline
  internal var age: Int32
  
  /// Creates an empty BTree rooted at a specific node with a specified uniform capacity
  /// - Parameter capacity: The key capacity of all nodes.
  @inlinable
  @inline(__always)
  internal init(capacity: Int) {
    self.init(
      leafCapacity: capacity,
      internalCapacity: capacity
    )
  }
  
  /// Creates an empty BTree which creates node with specified capacities
  /// - Parameters:
  ///   - leafCapacity: The capacity of the leaf nodes. This is the initial buffer used to allocate.
  ///   - internalCapacity: The capacity of the internal nodes. Generally prefered to be less than `leafCapacity`.
  @inlinable
  @inline(__always)
  internal init(leafCapacity: Int = BTREE_LEAF_CAPACITY, internalCapacity: Int = BTREE_INTERNAL_CAPACITY) {
    self.init(
      rootedAt: Node(withCapacity: leafCapacity, isLeaf: true),
      leafCapacity: leafCapacity,
      internalCapacity: internalCapacity
    )
  }
  
  /// Creates a BTree rooted at a specific node with a specified uniform capacity
  /// - Parameters:
  ///   - root: The root node.
  ///   - capacity: The key capacity of all nodes.
  @inlinable
  @inline(__always)
  internal init(rootedAt root: Node, capacity: Int) {
    self.init(
      rootedAt: root,
      leafCapacity: capacity,
      internalCapacity: capacity
    )
  }
  
  /// Creates a BTree rooted at a specific node.
  /// - Parameters:
  ///   - root: The root node.
  ///   - leafCapacity: The capacity of the leaf nodes. This is the initial buffer used to allocate.
  ///   - internalCapacity: The capacity of the internal nodes. Generally prefered to be less than `leafCapacity`.
  @inlinable
  @inline(__always)
  internal init(rootedAt root: Node, leafCapacity: Int = BTREE_LEAF_CAPACITY, internalCapacity: Int = BTREE_INTERNAL_CAPACITY) {
    self.root = root
    self.internalCapacity = internalCapacity
    self.age = Int32(truncatingIfNeeded: ObjectIdentifier(root.storage).hashValue)
  }
}

// MARK: Mutating Operations
extension _BTree {
  /// Invalidates the issued indices of the dictionary. Ensure this is
  /// called for operations which mutate the SortedDictionary.
  @inlinable
  @inline(__always)
  internal mutating func invalidateIndices() {
    self.age &+= 1
  }
  
  @usableFromInline
  internal enum InsertionResult {
    case updated(previousValue: Value)
    case splintered(Node.Splinter)
    case inserted
    
    @inlinable
    @inline(__always)
    internal init(from splinter: Node.Splinter?) {
      if let splinter = splinter {
        self = .splintered(splinter)
      } else {
        self = .inserted
      }
    }
  }
  
  /// Inserts an element into the BTree, or updates it if it already exists within the tree. If there are
  /// multiple instances of the key in the tree, this may update any one.
  ///
  /// This operation is marginally more efficient on trees without duplicates, and may have
  /// inconsistent results on trees with duplicates.
  ///
  /// - Parameters:
  ///   - element: The key-value pair to insert
  /// - Returns: If updated, the previous value for the key.
  /// - Complexity: O(`log n`)
  @inlinable
  @discardableResult
  internal mutating func setAnyValue(_ value: Value, forKey key: Key) -> Value? {
    invalidateIndices()
    
    let result = self.root.update { $0.setAnyValue(value, forKey: key) }
    switch result {
    case let .updated(previousValue):
      return previousValue
    case let .splintered(splinter):
      self.root = splinter.toNode(
        from: self.root,
        withCapacity: self.internalCapacity
      )
    default: break
    }
    
    return nil
  }
  
  /// Removes the key-value pair corresponding to the first found instance of the key.
  ///
  /// This may not be the first instance of the key. This is marginally more efficient for trees
  /// that do not have duplicates.
  ///
  /// If the key is not found, the tree is not modified, although the age of the tree may change.
  ///
  /// - Parameter key: The key to remove in the tree
  /// - Returns: The key-value pair which was removed. `nil` if not removed.
  @inlinable
  @discardableResult
  internal mutating func removeAny(key: Key) -> Element? {
    invalidateIndices()
    
    // TODO: Don't create CoW copy until needed.
    // TODO: Handle root deletion
    let removedElement = self.root.update { $0.removeAny(key: key) }
    
    // Check if the tree height needs to be reduced
    if self.root.read({ $0.numElements == 0 && !$0.isLeaf }) {
      let newRoot: Node = self.root.update { handle in
        let newRoot = handle.moveChild(at: 0)
        handle.drop()
        return newRoot
      }
      
      self.root = newRoot
    }
    
    return removedElement
  }
}

// MARK: Read Operations
extension _BTree {
  /// Determines if a key exists within a tree.
  ///
  /// - Parameter key: The key to search for.
  /// - Returns: Whether or not the key was found.
  @inlinable
  internal func contains(key: Key) -> Bool {
    // the retain/release calls
    // Retain
    var node: Node? = self.root
    
    while let currentNode = node {
      let found: Bool = currentNode.read { handle in
        let slot = handle.firstSlot(for: key)
        
        if slot < handle.numElements && handle[keyAt: slot] == key {
          return true
        } else {
          if handle.isLeaf {
            node = nil
          } else {
            // Release
            // Retain
            node = handle[childAt: slot]
          }
        }
        
        return false
      }
      
      if found { return true }
    }
    
    return false
  }
  
  
  /// Returns the value corresponding to the first found instance of the key.
  ///
  /// This may not be the first instance of the key. This is marginally more efficient
  /// for trees that do not have duplicates.
  ///
  /// - Parameter key: The key to search for
  /// - Returns: `nil` if the key was not found. Otherwise, the previous value.
  /// - Complexity: O(`log n`)
  @inlinable
  internal func anyValue(for key: Key) -> Value? {
    // the retain/release calls
    // Retain
    var node: Node? = self.root
    
    while let currentNode = node {
      let value: Value? = currentNode.read { handle in
        let slot = handle.firstSlot(for: key)
        
        if slot < handle.numElements && handle[keyAt: slot] == key {
          return handle[valueAt: slot]
        } else {
          if handle.isLeaf {
            node = nil
          } else {
            // Release
            // Retain
            node = handle[childAt: slot]
          }
        }
        
        return nil
      }
      
      if let value = value { return value }
    }
    
    return nil
  }
}
