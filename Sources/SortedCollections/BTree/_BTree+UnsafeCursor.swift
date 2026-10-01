//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if UnstableSortedCollections

extension _BTree {
  /// A mutable cursor to an element of the B-Tree represented as a path.
  ///
  /// Cursors consume the original tree on which they were created. It is undefined behavior to operate or
  /// read a tree on which a cursor was created. A cursor strongly references the tree on which it was
  /// operating on. Once operations with a cursor are finished, the tree can be restored using
  /// `_BTree.UnsafeCursor.apply(to:)`.
  ///
  /// This is a heavier alternative to ``_BTree.Index``, however this allows mutable operations to be
  /// efficiently performed.
  ///
  /// - Warning: It is invalid to operate on a tree while a cursor to it exists.
  /// - Warning: the tree root must remain alive for the entire lifetime of a cursor otherwise bad things
  ///     may occur.
  @usableFromInline
  @unsafe
  internal struct UnsafeCursor {
    @usableFromInline
    internal typealias Path = _FixedSizeArray<Unmanaged<Node.Storage>>
    
    /// This property is what takes ownership of the tree during the lifetime of the cursor. Once the cursor
    /// is consumed, it is set to nil and it is invalid to use the cursor.
    @usableFromInline
    @safe
    internal var _root: Node.Storage?
    
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
    @safe
    internal var slots: _FixedSizeArray<_BTree.Slot>
    
    /// This stores a list of the nodes from top-to-bottom.
    @usableFromInline
    @unsafe
    internal var path: Path
    
    /// Bottom most node that the index point to.
    
    /// The depth at which the last instance of sequential unique nodes starting at the root was found.
    ///
    /// In the following path where 'U' denotes a unique node, and 'S' denotes a shared node. The value
    /// of this parameter would be '1' indicating the second level of the tree.
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
    @safe
    internal var lastUniqueDepth: Int
    
    @inlinable
    @inline(__always)
    internal init(
      root: Node.Storage,
      slots: _FixedSizeArray<_BTree.Slot>,
      path: Path,
      lastUniqueDepth: Int
    ) {
      // Slots and path should be non-empty
      assert(slots.depth >= 1, "Invalid tree cursor")
      assert(unsafe path.depth >= 1, "Invalid tree cursor")

      self._root = root
      self.slots = slots
      unsafe self.path = path
      self.lastUniqueDepth = lastUniqueDepth
    }
    
    // MARK: Internal Checks
    /// Check that this cursor is still valid
    ///
    /// Every member that operates on the element of the cursor must start by calling this function.
    ///
    /// Note that this is a noop in release builds.
    @inlinable
    @inline(__always)
    internal func assertValid() {
      #if COLLECTIONS_INTERNAL_CHECKS
      assert(self._root != nil,
             "Attempt to operate on an element using an invalid cursor")
      #endif
    }
    
    // MARK: Core Cursor Operations
    /// Finishes operating on a cursor and restores a tree
    @inlinable
    @inline(__always)
    internal mutating func apply(to tree: inout _BTree) {
      unsafe assertValid()
      assert(tree.root._storage == nil, "Must apply to same tree as original")
      swap(&tree.root._storage, &self._root)
      tree.checkInvariants()
    }
    
    /// Declares that the cursor is completely unique
    @inlinable
    @inline(__always)
    internal mutating func _declareUnique() {
      self.lastUniqueDepth = unsafe Int(path.depth)
    }
    
    /// Operators on a handle of the node
    /// - Warning: Ensure this is never called on an endIndex.
    @inlinable
    @inline(__always)
    internal mutating func readCurrentNode<R>(
      _ body: (Node.UnsafeHandle, Int) throws -> R
    ) rethrows -> R {
      unsafe assertValid()

      let slot = Int(slots[slots.depth - 1])
      return unsafe try path[path.depth - 1]._withUnsafeGuaranteedRef {
        unsafe try $0.read({ unsafe try body($0, slot) })
      }
    }
    
    /// Updates the node at a given depth.
    /// - Warning: this does not perform CoW checks
    @inlinable
    @inline(__always)
    internal mutating func updateNode<R>(
      atDepth depth: Int8,
      _ body: (Node.UnsafeHandle, Int) throws -> R
    ) rethrows -> (node: Node, result: R) {
      unsafe assertValid()

      let slot = Int(slots[depth])
      let isOnUniquePath = depth <= lastUniqueDepth
      
      return unsafe try path[depth]._withUnsafeGuaranteedRef { storage in
        if isOnUniquePath {
          let result = unsafe try storage.updateGuaranteedUnique({ unsafe try body($0, slot) })
          return (Node(storage), result)
        } else {
          let storage = storage.copy()
          unsafe path[depth] = .passUnretained(storage)
          let result = unsafe try storage.updateGuaranteedUnique({ unsafe try body($0, slot) })
          return (Node(storage), result)
        }
      }
    }
    
    
    // MARK: Mutations with the Cursor
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
      unsafe assertValid()
      defer { unsafe self._declareUnique() }

      // Update the bottom-most node
      var (node, result) = unsafe try self.updateNode(atDepth: path.depth - 1, body)

      // Start the node above the bottom-most node, and propagate up the change
      var depth = unsafe path.depth - 2
      while depth >= 0 {
        if depth > lastUniqueDepth {
          // If we're on a
          let (newNode, _) = unsafe self.updateNode(atDepth: depth) { (handle, slot) in
            _ = unsafe handle.exchangeChild(atSlot: slot, with: node)
          }
          
          node = newNode
        } else if depth == lastUniqueDepth {
          // The node directly above the first shared node, we can update its
          // child without performing uniqueness checks since it's guaranteed
          // to be unique.
          let child = node
          let slot = Int(slots[depth])
          
          unsafe path[depth]._withUnsafeGuaranteedRef { storage in
            unsafe storage.updateGuaranteedUnique { handle in
              _ = unsafe handle.exchangeChild(atSlot: slot, with: child)
            }
          }
          
          return result
        } else {
          // depth < lastUniqueDepth
          
          // In this case we don't need to traverse to the root since we know
          // it remains the same.
          return result
        }
        
        depth -= 1
      }
      
      self._root = node.storage
      return result
    }
    
    /// Moves the value from the cursor's position
    @inlinable
    @inline(__always)
    internal mutating func moveValue() -> Value {
      guard Node.hasValues else { return Node.dummyValue }

      return unsafe self.updateCurrentNode { handle, slot in
        unsafe handle.pointerToValue(atSlot: slot).move()
      }
    }
    
    /// Initializes a value for a cursor that points to an element that has a hole for its value.
    @inlinable
    @inline(__always)
    internal mutating func initializeValue(to value: Value) {
      guard Node.hasValues else { return }
      
      unsafe self.updateCurrentNode { handle, slot in
        unsafe handle.pointerToValue(atSlot: slot).initialize(to: value)
      }
    }
    
    /// Inserts a key-value pair at a position within the tree.
    ///
    /// Invalidates the cursor. Returns a splinter object which owning the new tree.
    ///
    /// - Parameters:
    ///   - element: A new key-value element to insert.
    ///   - capacity: Capacity of new internal nodes created during insertion.
    /// - Returns: The new root object which may equal in identity to the previous one.
    /// - Warning: Does not check sortedness invariant
    /// - Complexity: O(`log n`). Ascends the tree once
    @inlinable
    internal mutating func insertElement(
      _ element: Node.Element,
      capacity: Int
    ) {
      unsafe assertValid()
      defer { unsafe self._declareUnique() }

      var (node, splinter) = unsafe self.updateNode(atDepth: path.depth - 1) { handle, slot in
        unsafe handle.insertElement(element, withRightChild: nil, atSlot: slot)
      }

      // Start the node above the bottom-most node, and propagate up the change
      var depth = unsafe path.depth - 2
      while depth >= 0 {
        let (newNode, _) = unsafe self.updateNode(atDepth: depth) { (handle, slot) in
          unsafe handle.exchangeChild(atSlot: slot, with: node)

          if let lastSplinter = splinter {
            splinter = unsafe handle.insertSplinter(lastSplinter, atSlot: slot)
          } else {
            unsafe handle.subtreeCount += 1
          }
        }
        
        node = newNode
        depth -= 1
      }
      
      if let splinter = splinter {
        let newRoot = splinter.toNode(leftChild: node, capacity: capacity)
        self._root = newRoot.storage
      } else {
        self._root = node.storage
      }
    }
    
    /// Removes the element at a cursor.
    ///
    /// - Parameter hasValueHole: Whether the value has been moved out of the node.
    /// - Complexity: O(`log n`). Ascends the tree once.
    @inlinable
    internal mutating func removeElement(hasValueHole: Bool = false) {
      unsafe assertValid()
      defer { unsafe self._declareUnique() }

      var (node, _) = unsafe self.updateNode(
        atDepth: path.depth - 1
      ) { handle, slot in
        if handle.isLeaf {
          // Deletion within a leaf
          // removeElement(atSlot:) automatically adjusts node counts.
          if hasValueHole {
            unsafe handle.removeElementWithoutValue(atSlot: slot)
          } else {
            unsafe handle.removeElement(atSlot: slot)
          }
        } else {
          // Deletion within an internal node
          
          // Swap with the predecessor
          let predecessor =
            unsafe handle[childAt: slot].update { unsafe $0.popLastElement() }

          // Reduce the element count.
          unsafe handle.subtreeCount -= 1

          // Replace the current element with the predecessor.
          if hasValueHole {
            _ = unsafe handle.pointerToKey(atSlot: slot).move()
            unsafe handle.initializeElement(atSlot: slot, to: predecessor)
          } else {
            unsafe handle.exchangeElement(atSlot: slot, with: predecessor)
          }
          
          // Balance the predecessor child slot, as the pop operation may have
          // brought it out of balance.
          unsafe handle.balance(atSlot: slot)
        }
      }
      
      // Balance the parents
      var depth = unsafe path.depth - 2
      while depth >= 0 {
        var (newNode, _) = unsafe self.updateNode(atDepth: depth) { (handle, slot) in
          unsafe handle.exchangeChild(atSlot: slot, with: node)
          unsafe handle.subtreeCount -= 1
          unsafe handle.balance(atSlot: slot)
        }
        
        if unsafe depth == 0 && newNode.read({ unsafe $0.elementCount == 0 && !$0.isLeaf }) {
          // If the root has no elements, we drop it and promote the child.
          node = unsafe newNode.update(isUnique: true) { handle in
            let newRoot = unsafe handle.moveChild(atSlot: 0)
            unsafe handle.drop()
            return newRoot
          }
        } else {
          node = newNode
        }
        depth -= 1
      }
      
      self._root = node.storage
    }
  }
  
  /// Obtains a cursor to a given element in the tree.
  ///
  /// This 'consumes' the tree, however it expects the callee to retain the root of the tree for the duration of
  /// the cursors lifetime.
  ///
  /// - Parameter index: The index to take the cursor at
  /// - Returns: A cursor to the element at that index.
  /// - Complexity: O(`log n`)
  @inlinable
  internal mutating func takeCursor(at index: Index) -> UnsafeCursor {
    var slots = index.childSlots
    slots.append(UInt16(index.slot))
    
    // Initialize parents with some dummy value filling it.
    var parents =
      unsafe UnsafeCursor.Path(repeating: .passUnretained(self.root.storage))

    var ownedRoot: Node.Storage
    do {
      var tempRoot: Node.Storage? = nil
      swap(&tempRoot, &self.root._storage)
      ownedRoot = unsafe tempRoot.unsafelyUnwrapped
    }
    
    var node: Unmanaged<Node.Storage> = unsafe .passUnretained(ownedRoot)

    // The depth containing the first instance of a shared
    var lastUniqueDepth = isKnownUniquelyReferenced(&ownedRoot) ? 0 : -1
    var isOnUniquePath = isKnownUniquelyReferenced(&ownedRoot)
    
    for d in 0..<index.childSlots.depth {
      unsafe node._withUnsafeGuaranteedRef { storage in
        unsafe storage.read { handle in
          unsafe parents.append(node)

          let slot = Int(index.childSlots[d])
          unsafe node = .passUnretained(handle[childAt: slot].storage)
          if unsafe isOnUniquePath && handle.isChildUnique(atSlot: slot) {
            lastUniqueDepth += 1
          } else {
            isOnUniquePath = false
          }
        }
      }
    }
    unsafe parents.append(node)
    return unsafe UnsafeCursor(
      root: ownedRoot,
      slots: slots,
      path: parents,
      lastUniqueDepth: lastUniqueDepth)
  }

  /// Obtains a cursor to a given element in the tree.
  ///
  /// This 'consumes' the tree, however it expects the callee to retain the root of the tree for the duration of
  /// the cursors lifetime.
  ///
  /// - Parameter key: The key to search for
  /// - Returns: A `cursor` to the key or where the key should be inserted, and a `found`
  ///     parameter indicating whether or not the key exists within the tree.
  /// - Complexity: O(`log n`)
  @inlinable
  internal mutating func takeCursor(
    forKey key: Key
  ) -> (cursor: UnsafeCursor, found: Bool) {
    var slots = Index.Offsets(repeating: 0)
    
    // Initialize parents with some dummy value filling it.
    var parents =
      unsafe UnsafeCursor.Path(repeating: .passUnretained(self.root.storage))

    var ownedRoot: Node.Storage
    do {
      var tempRoot: Node.Storage? = nil
      swap(&tempRoot, &self.root._storage)
      ownedRoot = unsafe tempRoot.unsafelyUnwrapped
    }
    
    var node: Unmanaged<Node.Storage> = unsafe .passUnretained(ownedRoot)

    // Initialize slot to some dummy value.
    var slot = -1
    var found: Bool = false
    
    // The depth containing the first instance of a shared
    var lastUniqueDepth = isKnownUniquelyReferenced(&ownedRoot) ? 0 : -1
    var isOnUniquePath = isKnownUniquelyReferenced(&ownedRoot)
    
    while true {
      let shouldStop: Bool = unsafe node._withUnsafeGuaranteedRef { storage in
        unsafe storage.read { handle in
          slot = unsafe handle.startSlot(forKey: key)

          if unsafe slot < handle.elementCount && handle[keyAt: slot] == key {
            found = true
            return true
          } else {
            if handle.isLeaf {
              return true
            } else {
              unsafe parents.append(node)
              slots.append(UInt16(slot))
              
              unsafe node = .passUnretained(handle[childAt: slot].storage)
              if unsafe isOnUniquePath && handle.isChildUnique(atSlot: slot) {
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
    
    assert(slot != -1)
    
    unsafe parents.append(node)
    slots.append(UInt16(slot))
    
    let cursor = unsafe UnsafeCursor(
      root: ownedRoot,
      slots: slots,
      path: parents,
      lastUniqueDepth: lastUniqueDepth)
    
    return unsafe (cursor, found)
  }
}

#endif
