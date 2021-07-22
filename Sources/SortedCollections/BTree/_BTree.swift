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
  static internal var defaultInternalCapacity: Int { 64 }
  
  /// Leaf node capacity for BTree
  @inlinable
  @inline(__always)
  static internal var defaultLeafCapacity: Int { 2000 }
  
  @usableFromInline
  internal typealias Element = (key: Key, value: Value)
  
  @usableFromInline
  internal typealias Node = _Node<Key, Value>
  
  /// The underlying node behind this local BTree
  @usableFromInline
  internal var root: Node
  
  /// The capacity of each of the internal nodes
  @usableFromInline
  internal var internalCapacity: Int
  
  /// A metric to uniquely identify a given B-Tree's state. It is not
  /// impossible for two B-Trees to have the same age by pure
  /// coincidence.
  @usableFromInline
  internal var version: Int
  
  /// Creates an empty B-Tree with an automatically determined optimal capacity.
  @inlinable
  @inline(__always)
  internal init() {
    let leafCapacity = Swift.min(
      16,
      _BTree.defaultLeafCapacity / MemoryLayout<Key>.stride
    )
    
    let internalCapacity = Swift.min(
      16,
      _BTree.defaultInternalCapacity / MemoryLayout<Key>.stride
    )
    
    let root = Node(withCapacity: leafCapacity, isLeaf: true)
    self.init(rootedAt: root, internalCapacity: internalCapacity)
  }
  
  /// Creates an empty B-Tree rooted at a specific node with a specified uniform capacity
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
  ///   - internalCapacity: The capacity of the internal nodes. Generally prefered to be less than
  ///       `leafCapacity`.
  @inlinable
  @inline(__always)
  internal init(leafCapacity: Int, internalCapacity: Int) {
    self.init(
      rootedAt: Node(withCapacity: leafCapacity, isLeaf: true),
      internalCapacity: internalCapacity
    )
  }
  
  /// Creates a BTree rooted at a specific nodey
  /// - Parameters:
  ///   - root: The root node.
  ///   - internalCapacity: The key capacity of new internal nodes.
  @inlinable
  @inline(__always)
  internal init(rootedAt root: Node, internalCapacity: Int) {
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
  internal mutating func updateAnyValue(
    _ value: Value,
    forKey key: Key,
    updatingKey: Bool = false
  ) -> Element? {
    invalidateIndices()
    
    let result = self.root.update { $0.updateAnyValue(value, forKey: key, updatingKey: updatingKey) }
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

// MARK: Removal Opertations
extension _BTree {
  /// Removes the element of a tree at a given offset.
  ///
  /// - Parameter offset: the offset which must be in-bounds.
  /// - Returns: The moved element of the tree
  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func remove(atOffset offset: Int) -> Element {
    invalidateIndices()
    let removedElement = self.root.update { $0.remove(at: offset) }
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
      let value: Value? = currentNode._withUnsafeGuaranteedRef {
        $0.read { handle in
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
  
  /// Returns the path corresponding to the first found instance of the key. This may
  /// not be the first instance of the key. This is marginally more efficient for trees
  /// that do not have duplicates.
  ///
  /// - Parameter key: The key to search for within the tree.
  /// - Returns: If found, returns a path to the element. Otherwise, `nil`.
  @inlinable
  internal func findAnyPath(forKey key: Key) -> UnsafePath? {
    var childSlots = UnsafePath.Offsets(repeating: 0)
    var node: Unmanaged<Node.Storage>? = .passUnretained(self.root.storage)
    
    while let currentNode = node {
      let path: UnsafePath? = currentNode._withUnsafeGuaranteedRef { storage in
        storage.read { handle in
          let keySlot = handle.startSlot(forKey: key)
          if keySlot < handle.elementCount && handle[keyAt: keySlot] == key {
            return UnsafePath(
              node: .passUnretained(storage),
              slot: keySlot,
              childSlots: childSlots,
              offset: 0
            )
          } else {
            if handle.isLeaf {
              node = nil
            } else {
              childSlots.append(UInt16(keySlot))
              node = .passUnretained(handle[childAt: keySlot].storage)
            }
            
            return nil
          }
        }
      }
      
      if let path = path { return path }
    }
    
    return nil
  }
  
  /// Obtains the path to the element at a specified integer offset within the tree.
  ///
  /// - Parameter offset: The absolute offset that must be in-bounds or the last position.
  /// - Returns: An unsafe path to the element, or `nil` if corresponds to the last position.
  @inlinable
  internal func path(atOffset offset: Int) -> UnsafePath? {
    assert(offset <= self.count, "Index out of bounds.")

    // Return nil path if at the end of the tree
    if offset == self.count {
      return nil
    }
    
    var childSlots = UnsafePath.Offsets(repeating: 0)
    
    var node: _Node = self.root
    var startIndex = 0
    
    while !node.read({ $0.isLeaf }) {
      let internalPath: UnsafePath? = node.read { handle in
        for childSlot in 0..<handle.childCount {
          let child = handle[childAt: childSlot]
          let endIndex = startIndex + child.read({ $0.subtreeCount })
          
          if offset < endIndex {
            childSlots.append(UInt16(childSlot))
            node = child
            return nil
          } else if offset == endIndex {
            // We've found the node we want
            return UnsafePath(node: node, slot: childSlot, childSlots: childSlots, offset: offset)
          } else {
            startIndex = endIndex + 1
          }
        }
        
        // TODO: convert into debug-only preconditionFaliure
        preconditionFailure("In-bounds index not found within tree.")
      }
      
      if let internalPath = internalPath { return internalPath }
    }
    
    return UnsafePath(
      node: node,
      slot: offset - startIndex,
      childSlots: childSlots,
      offset: offset
    )
  }
}
