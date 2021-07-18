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

/// A bidirectional collection representing a BTree which efficiently stores its
/// elements in sorted order and maintains roughly `O(log count)`
/// performance for most operations.
///
/// - Warning: Indexing operations on a BTree are unchecked. ``_BTree.Index``
///   offers `ensureValid(for:)` methods to validate indices for use in higher-level
///   collections.
@usableFromInline
internal struct _BTree<Key: Comparable, Value> {
  
  // TODO: decide node capacity. Currently exploring 470 v 1050
  // TODO: better benchmarking here
  
  /// Internal node capacity for BTree
  @inlinable
  @inline(__always)
  static internal var defaultInternalCapacity: Int { 16 }
  
  /// Leaf node capacity for BTree
  @inlinable
  @inline(__always)
  static internal var defaultLeafCapacity: Int { 500 }
  
  @usableFromInline
  internal typealias Element = (key: Key, value: Value)
  
  @usableFromInline
  internal typealias Node = _Node<Key, Value>
  
  /// The underlying node behind this local BTree
  @usableFromInline
  internal var root: Node
  
  // TODO: remove
  // TODO: compute capacity based on key/value size.
  /// The capacity of each of the internal nodes
  @usableFromInline
  internal var internalCapacity: Int
  
  /// A metric to uniquely identify a given BTree's state. It is not
  /// impossible for two BTrees to have the same age by pure
  /// coincidence.
  @usableFromInline
  internal var version: Int
  
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
  internal init(leafCapacity: Int = defaultLeafCapacity, internalCapacity: Int = defaultInternalCapacity) {
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
  internal init(rootedAt root: Node, leafCapacity: Int = defaultLeafCapacity, internalCapacity: Int = defaultInternalCapacity) {
    self.root = root
    self.internalCapacity = internalCapacity
    self.version = ObjectIdentifier(root.storage).hashValue
  }
}

// MARK: Mutating Operations
extension _BTree {
  /// Invalidates the issued indices of the dictionary. Ensure this is
  /// called for operations which mutate the SortedDictionary.
  @inlinable
  @inline(__always)
  internal mutating func invalidateIndices() {
    self.version &+= 1
  }
  
  /// Inserts an element into the BTree, or updates it if it already exists within the tree. If there are
  /// multiple instances of the key in the tree, this may update any one.
  ///
  /// This operation is marginally more efficient on trees without duplicates, and may have
  /// inconsistent results on trees with duplicates.
  ///
  /// - Parameters:
  ///   - value: The value to set corresponding to the key.
  ///   - key: The key to search for.
  ///   - updatingKey: If the key is found, whether it should be updated.
  /// - Returns: If updated, the previous element.
  /// - Complexity: O(`log n`)
  @inlinable
  @discardableResult
  // updateAnyValue(_:forKey:)
  internal mutating func setAnyValue(
    _ value: Value,
    forKey key: Key,
    updatingKey: Bool = false
  ) -> Element? {
    invalidateIndices()
    
    let result = self.root.update { $0.setAnyValue(value, forKey: key, updatingKey: updatingKey) }
    switch result {
    case let .updated(previousValue):
      return previousValue
    case let .splintered(splinter):
      self.root = splinter.toNode(
        leftChild: self.root,
        capacity: self.internalCapacity
      )
    default: break
    }
    
    return nil
  }
  
  /// Verifies if the tree is balanced post-removal
  /// - Warning: This does not invalidate indices.
  @inlinable
  @inline(__always)
  internal mutating func _balanceRoot() {
    if self.root.read({ $0.elementCount == 0 && !$0.isLeaf }) {
      let newRoot: Node = self.root.update { handle in
        let newRoot = handle.moveChild(atSlot: 0)
        handle.drop()
        return newRoot
      }
      
      self.root = newRoot
    }
  }
  
  /// Removes the key-value pair corresponding to the first found instance of the key.
  ///
  /// This may not be the first instance of the key. This is marginally more efficient for trees
  /// that do not have duplicates.
  ///
  /// If the key is not found, the tree is not modified, although the version of the tree may change.
  ///
  /// - Parameter key: The key to remove in the tree
  /// - Returns: The key-value pair which was removed. `nil` if not removed.
  @inlinable
  @discardableResult
  internal mutating func removeAnyElement(forKey key: Key) -> Element? {
    invalidateIndices()
    
    // TODO: Don't create CoW copy until needed.
    let removedElement = self.root.update { $0.removeAnyElement(forKey: key) }
    
    // Check if the tree height needs to be reduced
    self._balanceRoot()
    
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
        let slot = handle.startSlot(forKey: key)
        
        if slot < handle.elementCount && handle[keyAt: slot] == key {
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
  internal func findAnyValue(forKey key: Key) -> Value? {
    var node: Unmanaged<Node.Storage>? = .passUnretained(self.root.storage)
    
    while let currentNode = node {
      let value: Value? = currentNode._withUnsafeGuaranteedRef { storage -> Value? in
        storage.read { handle in
          let slot = handle.startSlot(forKey: key)
          
          if slot < handle.elementCount && handle[keyAt: slot] == key {
            return handle[valueAt: slot]
          } else {
            if handle.isLeaf {
              node = nil
            } else {
              node = .passUnretained(handle[childAt: slot].storage)
            }
          }
          
          return nil
        }
      }
      
      if let value = value { return value }
    }
    
    return nil
  }
}
