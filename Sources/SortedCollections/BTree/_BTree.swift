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
  
  /// Recommended node size of a given B-Tree
  @inlinable
  @inline(__always)
  internal static var defaultInternalCapacity: Int {
    #if DEBUG
    return 4
    #else
    let capacityInBytes = 128
    return Swift.min(16, capacityInBytes / MemoryLayout<Key>.stride)
    #endif
  }
  
  /// Recommended node size of a given B-Tree
  @inlinable
  @inline(__always)
  internal static var defaultLeafCapacity: Int {
    #if DEBUG
    return 5
    #else
    let capacityInBytes = 2000
    return Swift.min(16, capacityInBytes / MemoryLayout<Key>.stride)
    #endif
  }
  
  /// The element type of the collection.
  @usableFromInline
  internal typealias Element = (key: Key, value: Value)
  
  /// The type of each node in the tree
  @usableFromInline
  internal typealias Node = _Node<Key, Value>
  
  /// A size large enough to represent any slot within a node
  @usableFromInline
  internal typealias Slot = UInt16
  
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
  
  /// Creates a dummy B-Tree with no underlying node storage class.
  ///
  /// It is invalid and a serious error to ever attempt to read or write to such a B-Tree.
  @inlinable
  @inline(__always)
  internal static var dummy: _BTree {
    _BTree(
      _rootedAtNode: _Node.dummy,
      internalCapacity: 0,
      version: 0
    )
  }
  
  /// Creates an empty B-Tree with an automatically determined optimal capacity.
  @inlinable
  @inline(__always)
  internal init() {
    let root = Node(withCapacity: _BTree.defaultLeafCapacity, isLeaf: true)
    self.init(rootedAt: root, internalCapacity: _BTree.defaultInternalCapacity)
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
  
  /// Creates an empty B-Tree which creates node with specified capacities
  /// - Parameters:
  ///   - leafCapacity: The capacity of the leaf nodes. This is the initial buffer used to allocate.
  ///   - internalCapacity: The capacity of the internal nodes. Generally preferred to be less than
  ///       `leafCapacity`.
  @inlinable
  @inline(__always)
  internal init(leafCapacity: Int, internalCapacity: Int) {
    self.init(
      rootedAt: Node(withCapacity: leafCapacity, isLeaf: true),
      internalCapacity: internalCapacity
    )
  }
  
  /// Creates a B-Tree rooted at a specific node
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
  
  @inlinable
  @inline(__always)
  internal init(
    _rootedAtNode root: Node,
    internalCapacity: Int,
    version: Int
  ) {
    self.root = root
    self.internalCapacity = internalCapacity
    self.version = version
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
    defer { self.checkInvariants() }
    
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
    defer { self.checkInvariants() }
    
    // TODO: It is possible that there is a single transient CoW copied made
    // if the removal results in the CoW copied node being completely removed
    // from the tree.
    let removedElement = self.root.update { $0.removeAnyElement(forKey: key) }
    
    // Check if the tree height needs to be reduced
    self._balanceRoot()
    self.checkInvariants()
    
    return removedElement
  }
}

// MARK: Removal Operations
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
    defer { self.checkInvariants() }
    
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
  internal func findAnyIndex(forKey key: Key) -> Index? {
    var childSlots = Index.Offsets(repeating: 0)
    var node: Unmanaged? = .passUnretained(self.root.storage)
    var offset: Int = 0
    
    while let currentNode = node {
      let index: Index? = currentNode._withUnsafeGuaranteedRef { storage in
        storage.read { handle in
          let keySlot = handle.startSlot(forKey: key)
          offset += keySlot
          
          if keySlot < handle.elementCount && handle[keyAt: keySlot] == key {
            if !handle.isLeaf {
              for i in 0...keySlot {
                offset += handle[childAt: i].storage.header.subtreeCount
              }
            }
            
            return Index(
              node: .passUnretained(storage),
              slot: keySlot,
              childSlots: childSlots,
              offset: offset,
              forTree: self
            )
          } else {
            if handle.isLeaf {
              node = nil
            } else {
              for i in 0..<keySlot {
                offset += handle[childAt: i].storage.header.subtreeCount
              }
              
              childSlots.append(UInt16(keySlot))
              node = .passUnretained(handle[childAt: keySlot].storage)
            }
            
            return nil
          }
        }
      }
      
      if let index = index { return index }
    }
    
    return nil
  }
  
  /// Obtains the path to the element at a specified integer offset within the tree.
  ///
  /// - Parameter offset: The absolute offset that must be in-bounds or the last position.
  /// - Returns: An unsafe path to the element, or `nil` if corresponds to the last position.
  @inlinable
  internal func index(atOffset offset: Int) -> Index {
    assert(offset <= self.count, "Index out of bounds.")

    // Return nil path if at the end of the tree
    if offset == self.count {
      return self.endIndex
    }
    
    var childSlots = Index.Offsets(repeating: 0)
    
    var node: Unmanaged<Node.Storage> = .passUnretained(self.root.storage)
    var startIndex = 0
    
    while true {
      let index: Index? = node._withUnsafeGuaranteedRef { storage in
        storage.read({ handle in
          if handle.isLeaf {
            return Index(
              node: node,
              slot: offset - startIndex,
              childSlots: childSlots,
              offset: offset,
              forTree: self
            )
          }
          
          for childSlot in 0..<handle.childCount {
            let childSubtreeCount =
              handle[childAt: childSlot].read({ $0.subtreeCount })
            
            let endIndex = startIndex + childSubtreeCount
            
            if offset < endIndex {
              childSlots.append(UInt16(childSlot))
              node = .passUnretained(handle[childAt: childSlot].storage)
              return nil
            } else if offset == endIndex {
              // We've found the node we want
              return Index(
                node: node,
                slot: childSlot,
                childSlots: childSlots,
                offset: offset,
                forTree: self
              )
            } else {
              startIndex = endIndex + 1
              continue
            }
          }
          
          preconditionFailure("In-bounds index not found within tree.")
        })
      }
      
      if let index = index { return index }
    }
  }
}

// MARK: Custom Indexing Operations
extension _BTree {
  /// Returns a path to the key at absolute offset `i`.
  /// - Parameter offset: 0-indexed offset within BTree bounds, else may panic.
  /// - Returns: the index of the appropriate element.
  /// - Complexity: O(`log n`)
  

  /// Obtains the start index for a key (or where it would exist).
  @inlinable
  internal func startIndex(forKey key: Key) -> Index {
    var childSlots = Index.Offsets(repeating: 0)
    var targetSlot: Int = 0
    var offset = 0
    
    func search(in node: Node) -> Unmanaged<Node.Storage>? {
      node.read({ handle in
        let slot = handle.startSlot(forKey: key)
        if slot < handle.elementCount {
          if handle.isLeaf {
            offset += slot
            targetSlot = slot
            return .passUnretained(node.storage)
          } else {
            // Calculate offset by summing previous subtrees
            for i in 0...slot {
              offset += handle[childAt: i].read({ $0.subtreeCount })
            }
            
            let currentOffset = offset
            let currentDepth = childSlots.depth
            childSlots.append(UInt16(slot))
            
            if let foundEarlier = search(in: handle[childAt: slot]) {
              return foundEarlier
            } else {
              childSlots.depth = currentDepth
              targetSlot = slot
              offset = currentOffset
              
              return .passUnretained(node.storage)
            }
          }
        } else {
          // Start index exceeds node and is therefore not in this.
          return nil
        }
      })
    }
    
    if let targetChild = search(in: self.root) {
      return Index(
        node: targetChild,
        slot: targetSlot,
        childSlots: childSlots,
        offset: offset,
        forTree: self
      )
    } else {
      return endIndex
    }
  }
  
  /// Obtains the last index at which a value less than or equal to the key appears.
  @inlinable
  internal func lastIndex(forKey key: Key) -> Index {
    var childSlots = Index.Offsets(repeating: 0)
    var targetSlot: Int = 0
    var offset = 0
    
    func search(in node: Node) -> Unmanaged<Node.Storage>? {
      node.read({ handle in
        let slot = handle.endSlot(forKey: key) - 1
        if slot > 0 {
          assert(slot < handle.elementCount, "Slot out of bounds")
          
          if handle.isLeaf {
            offset += slot
            targetSlot = slot
            return .passUnretained(node.storage)
          } else {
            for i in 0...slot {
              offset += handle[childAt: i].read({ $0.subtreeCount })
            }
            
            let currentOffset = offset
            let currentDepth = childSlots.depth
            childSlots.append(UInt16(slot + 1))
            
            if let foundLater = search(in: handle[childAt: slot + 1]) {
              return foundLater
            } else {
              childSlots.depth = currentDepth
              targetSlot = slot
              offset = currentOffset
              
              return .passUnretained(node.storage)
            }
          }
        } else {
          // Start index exceeds node and is therefore not in this.
          return nil
        }
      })
    }
    
    if let targetChild = search(in: self.root) {
      return Index(
        node: targetChild,
        slot: targetSlot,
        childSlots: childSlots,
        offset: offset,
        forTree: self
      )
    } else {
      return endIndex
    }
  }
  
}

// MARK: Immutable Operations
extension _BTree {
  @inlinable
  @inline(__always)
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> _BTree<Key, T> {
    let root = try _Node<Key, T>(
      mappingFrom: self.root,
      transform
    )
    
    return _BTree<Key, T>(rootedAt: root, internalCapacity: internalCapacity)
  }
}
