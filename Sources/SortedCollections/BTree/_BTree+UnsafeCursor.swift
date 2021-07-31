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

extension _BTree {
  /// A mutable cursor to an element of the B-Tree represented as a path.
  ///
  /// There are two variants of a B-Tree cursor, a 'concrete' cursor which points at a specific element which
  /// already exists in the tree, and a 'non-concrete' cursor which points to a specific slot, representing an
  /// element which does not exist within the tree. It is therefore an invalid operation to operate on a
  /// non-concrete cursor's element (as it may be out-of-bounds). However, you can convert a
  /// non-concrete cursor to a concrete cursor using the
  /// ``_BTree.UnsafeCursor.makeConcrete()`` operation. Concrete cursor checks are no-ops in
  /// non-debug builds.
  ///
  /// Cursors consume the original tree on which they were created. It is undefined behavior to operate or
  /// read a tree on which a cursor was created. While this is the case, the original tree must remain alive
  /// for the entire lifetime of a cursor. Certain cursor operations, will yield a new tree root which can be
  /// used to obtain a usable tree reference. It is invalid to use a cursor after such operations.
  ///
  /// If you wish to retrieve your tree and an operation yielding a new tree root has not been called yet, you
  /// may use ``_BTree.UnsafeCursor.finish()``.
  ///
  /// This is a heavier alternative to ``_BTree.Index``, however this allows mutable operations to be
  /// efficiently performed.
  ///
  /// - Warning: It is invalid to operate on a tree while a cursor to it exists.
  /// - Warning: the tree root must remain alive for the entire lifetime of a cursor otherwise bad things
  ///     may occur.
  @usableFromInline
  internal struct UnsafeCursor {
    @usableFromInline
    internal typealias Path = FixedSizeArray<Unmanaged<Node.Storage>>
    
    /// This property is what takes ownership of the tree during the lifetime of the cursor. Once the cursor
    /// is consumed, it is set to nil and it is invalid to use the cursor.
    @usableFromInline
    internal var __root: Node.Storage?
    
    @inlinable
    @inline(__always)
    internal var root: Node.Storage { __root.unsafelyUnwrapped }
    
    /// Position of each of the parent nodes in their parents, including the bottom-most node.
    ///
    /// In the following tree, a cursor to `7` would contain `[1, 0]`. Referring to the child at index 1
    /// and its element at index 0.
    ///
    ///         ┌─┐
    ///         │5│
    ///       ┌─┴─┴─┐
    ///       │     │
    ///     ┌─┼─┐ ┌─┼─┐
    ///     │1│3│ │7│9│
    ///     └─┴─┘ └─┴─┘
    @usableFromInline
    internal var slots: FixedSizeArray<_BTree.Slot>
    
    /// This stores a list of the nodes from top-to-bottom.
    @usableFromInline
    internal var path: Path
    
    /// Bottom most node that the index point to.
    // TODO: look at implementing _modify accessor.
    @usableFromInline
    internal var currentNode: Unmanaged<Node.Storage> {
      get { path[path.depth - 1] }
      set { path[path.depth - 1] = newValue }
    }
    
    /// Slot within the bottom most node which the index points to.
    @inlinable
    @inline(__always)
    internal var slot: Int { Int(slots[slots.depth - 1]) }
    
    /// The depth at which the last instance of sequential unique nodes starting at the root was found.
    ///
    /// In the following path where 'U' denotes a unique node, and 'S' denotes a shared node. The value
    /// of this parameter would be '1' indicating the second level of the tre.
    ///
    ///     ┌─┐
    ///     │U├─┐
    ///     └─┘ ├─┐
    ///         │U├─┐
    ///         └─┘ ├─┐
    ///          ▲  │S├─┐
    ///          │  └─┘ ├─┐
    ///          │      │U│
    ///                 └─┘
    ///
    /// This is notable for CoW as all values below it would need to be duplicated. Updating this to be as
    /// high as accurately possible ensures there are no unnecessary copies made.
    @usableFromInline
    internal var lastUniqueDepth: Int
    
    @inlinable
    @inline(__always)
    internal init(
      root: Node.Storage,
      slots: FixedSizeArray<_BTree.Slot>,
      path: Path,
      lastUniqueDepth: Int,
      // Debug-only properties
      isConcrete: Bool
    ) {
      // Slots and path should be non-empty
      assert(slots.depth >= 1, "Invalid tree cursor.")
      assert(path.depth >= 1, "Invalid tree cursor.")
      
      self.__root = root
      self.slots = slots
      self.path = path
      self.lastUniqueDepth = lastUniqueDepth
      
      #if COLLECTIONS_INTERNAL_CHECKS
      self.isConcrete = isConcrete
      #endif
    }
    
    // MARK: Internal Checks
    #if COLLECTIONS_INTERNAL_CHECKS
    /// A concrete cursor is one that refers to a specific element, not just a generic position.
    @usableFromInline internal let isConcrete: Bool
    #endif
    
    /// Check that this cursor is concrete
    /// Every member that operates on the element of the cursor must start by calling this function.
    ///
    /// Note that this is a noop in release builds.
    @inlinable
    @inline(__always)
    internal func assertConcrete() {
      #if COLLECTIONS_INTERNAL_CHECKS
      assert(self.isConcrete,
             "Attempt to operate on an element using a non-concrete cursor.")
      #endif
    }
    
    // MARK: Basic Cursor Operations
    /// Finishes operating on a cursor and restores a tree
    @inlinable
    @inline(__always)
    internal mutating func apply(to tree: inout _BTree) {
      assert(tree.root._storage == nil, "Must apply to same tree as original.")
      swap(&tree.root._storage, &self.__root)
    }
    
    /// Operators on a handle of the node
    /// - Warning: Ensure this is never called on an endIndex.
    @inlinable
    @inline(__always)
    internal func readCurrentNode<R>(
      _ body: (Node.UnsafeHandle) throws -> R
    ) rethrows -> R {
      return try currentNode._withUnsafeGuaranteedRef { try $0.read(body) }
    }
    
    /// Updates the node at a given depth.
    /// - Warning: this does not perform CoW checks
    @inlinable
    @inline(__always)
    internal mutating func updateNode<R>(
      at depth: Int8,
      _ body: (Node.UnsafeHandle, Int) throws -> R
    ) rethrows -> (node: Node, result: R) {
      var node = Node(path[depth].takeUnretainedValue())
      let slot = Int(slots[depth])
      let isOnUniquePath = depth <= lastUniqueDepth
      let result = try node.update(isUnique: isOnUniquePath) {
        try body($0, slot)
      }
      path[depth] = .passUnretained(node.storage)
      return (node, result)
    }
    
    
    // MARK: Mutating with the Cursor
    
    /// Operates on a handle of the node.
    ///
    /// This MUST be followed by an operation which consumes the cursor and returns the new tree, as
    /// this only performs CoW on the bottom-most level
    ///
    /// - Parameter body: Updating callback to run on a unique instance of the node containing the
    ///     cursor's target.
    /// - Returns: The body's return value
    /// - Complexity: O(`log n`) if non-unique. O(`1`) if unique.
    @inlinable
    @inline(__always)
    internal mutating func updateCurrentNode<R>(
      _ body: (Node.UnsafeHandle, Int) throws -> R
    ) rethrows -> R {
      defer { self.lastUniqueDepth = .max }
      
      // Update the bottom-most node
      var (node, result) = try self.updateNode(at: path.depth - 1, body)
      
      // Start the node above the bottom-most node, and propogate up the change
      var depth = path.depth - 2
      while depth >= 0 {
        if depth > lastUniqueDepth {
          // If we're on a
          let (newNode, _) = self.updateNode(at: depth) { (handle, slot) in
            _ = handle.exchangeChild(atSlot: slot, with: node)
          }
          
          node = newNode
        } else if depth == lastUniqueDepth {
          // The node directly above the first shared node, we can update its
          // child without performing uniqueness checks since it's guaranteed
          // to be unique.
          let child = node
          let slot = Int(slots[depth])
          
          path[depth]._withUnsafeGuaranteedRef { storage in
            storage.updateGuaranteedUnique { handle in
              _ = handle.exchangeChild(atSlot: slot, with: child)
            }
          }
        } else {
          // depth < lastUniqueDepth
          
          // In this case we don't need to traverse to the root since we know
          // it remains the same.
          return result
        }
        
        depth -= 1
      }
      
      self.__root = node.storage
      return result
    }
    
    /// Inserts a key-value pair at a position within the tree.
    ///
    /// Invalidates the cursor. Returns a splinter object which owning the new tree.
    ///
    /// - Parameters:
    ///   - element: A new key-value element to insert.
    ///   - capacity: Capacity of new internal nodes created during insertion.
    /// - Returns: The new root object which may equal in identity to the previous one.
    /// - Warning: Doesn not check sortedness invariant
    /// - Complexity: O(`log n`). Ascends the tree once
    @inlinable
    internal mutating func insertElement(
      _ element: Node.Element,
      capacity: Int
    ) {
      defer { self.lastUniqueDepth = .max }
      
      // TODO: make this not invalidate the cursor by updating slots
      
      var (node, splinter) = self.updateNode(at: path.depth - 1) { handle, slot in
        handle.insertElement(element, withRightChild: nil, atSlot: slot)
      }

      // Start the node above the bottom-most node, and propogate up the change
      var depth = path.depth - 2
      while depth >= 0 {
        // TODO: optimize this by stopping descent once we reach the unique
        // section
        if splinter == nil && depth < lastUniqueDepth { return }
        
        let (newNode, _) = self.updateNode(at: depth) { (handle, slot) in
          handle.exchangeChild(atSlot: slot, with: node)
          
          if let lastSplinter = splinter {
            splinter = handle.insertSplinter(lastSplinter, atSlot: slot)
          }
        }
        
        node = newNode
        depth -= 1
      }
      
      if let splinter = splinter {
        let newRoot = splinter.toNode(leftChild: node, capacity: capacity)
        self.__root = newRoot.storage
      } else {
        self.__root = node.storage
      }
    }
    
    /// Removes the element at a cursor.
    ///
    /// - Parameter hasValueHole: Whether the value has been moved out of the node.
    /// - Complexity: O(`log n`). Ascends the tree once.
    @inlinable
    internal mutating func removeElement(hasValueHole: Bool = false) {
      defer { self.lastUniqueDepth = .max }
      
      var (node, _) = self.updateNode(
        at: path.depth - 1
      ) { handle, slot in
        if handle.isLeaf {
          // Deletion within a leaf
          // removeElement(atSlot:) automatically adjusts node counts.
          if hasValueHole {
            handle.removeElementWithoutValue(atSlot: slot)
          } else {
            handle.removeElement(atSlot: slot)
          }
        } else {
          // Deletion within an internal node
          
          // Swap with the predecessor
          let predecessor =
            handle[childAt: slot].update { $0.popLastElement() }
          
          // Reduce the element count.
          handle.subtreeCount -= 1
          
          // Replace the current element with the predecessor.
          if hasValueHole {
            _ = handle.pointerToKey(atSlot: slot).move()
            handle.initializeElement(atSlot: slot, to: predecessor)
          } else {
            handle.exchangeElement(atSlot: slot, with: predecessor)
          }
          
          // Balance the predecessor child slot, as the pop operation may have
          // brought it out of balance.
          handle.balance(atSlot: slot)
        }
      }
      
      // Balance the parents
      var depth = path.depth - 2
      while depth >= 0 {
        var (newNode, _) = self.updateNode(at: depth) { (handle, slot) in
          handle.exchangeChild(atSlot: slot, with: node)
          handle.balance(atSlot: slot)
        }
        
        if depth == 0 && newNode.read({ $0.elementCount == 0 && !$0.isLeaf }) {
          // If the root has no elements, we won't
          newNode.update(isUnique: true) { $0.drop() }
        } else {
          node = newNode
        }
        depth -= 1
      }
      
      self.__root = node.storage
    }
  }
  
  /// Obtains a cursor to a given element in the tree.
  ///
  /// This 'consumes' the tree, however it expects the callee to retain the root of the tree for the duration of
  /// the cursors lifetime.
  ///
  /// - Parameters:
  ///   - key: The key to search for
  ///   - mutable: whether a mutable cursor should be returned.
  /// - Returns: A `cursor` to the key or where the key should be inserted, and a `found`
  ///     parameter indicating whether or not the key exists within the tree, iff `found` is true, the cursor
  ///     is concrete.
  /// - Complexity: O(`log n`)
  @inlinable
  internal mutating func findAnyCursor(
    forKey key: Key
  ) -> (cursor: UnsafeCursor, found: Bool) {
    var slots = Index.Offsets(repeating: 0)
    
    // Initialize parents with some dummy value filling it.
    var parents =
      UnsafeCursor.Path(repeating: .passUnretained(self.root.storage))
    
    // TODO: swap
    var ownedRoot: Node.Storage
    do {
      var tempRoot: Node.Storage? = nil
      swap(&tempRoot, &self.root._storage)
      ownedRoot = tempRoot.unsafelyUnwrapped
    }
    
    var node: Unmanaged<Node.Storage> = .passUnretained(ownedRoot)
    
    // Initialize slot to some dummy value.
    var slot = -1
    var found: Bool = false
    
    // The depth containing the first instance of a shared
    var lastUniqueDepth = isKnownUniquelyReferenced(&ownedRoot) ? 0 : -1
    var isOnUniquePath = isKnownUniquelyReferenced(&ownedRoot)
    
    while true {
      let shouldStop: Bool = node._withUnsafeGuaranteedRef { storage in
        storage.read { handle in
          slot = handle.startSlot(forKey: key)
          
          if slot < handle.elementCount && handle[keyAt: slot] == key {
            found = true
            return true
          } else {
            if handle.isLeaf {
              return true
            } else {
              parents.append(node)
              slots.append(UInt16(slot))
              
              node = .passUnretained(handle[childAt: slot].storage)
              if isOnUniquePath && isKnownUniquelyReferenced(&handle[childAt: slot].storage) {
                lastUniqueDepth += 1
              } else {
                isOnUniquePath = false
              }
              return false
            }
          }
        }
      }
      
      if shouldStop { break }
    }
    
    assert(slot != -1 && lastUniqueDepth != -1, "B-Tree sanity check fail.")
    
    parents.append(node)
    slots.append(UInt16(slot))
    
    let cursor = UnsafeCursor(
      root: ownedRoot,
      slots: slots,
      path: parents,
      lastUniqueDepth: lastUniqueDepth,
      isConcrete: found
    )
    
    return (cursor, found)
  }
}
