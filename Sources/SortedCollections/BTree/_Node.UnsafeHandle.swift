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

extension _Node {
  /// A handle allowing potentially mutable operations to be performed.
  ///
  /// An ``UnsafeHandle`` should never be constructed directly. It is instead used when modifying a
  /// node through its closure APIs, such as:
  ///
  ///     let nodeMedian = node.read { handle in
  ///       let medianSlot = handle.elementCount
  ///       return handle[elementAt: medianSlot]
  ///     }
  ///
  /// The unsafe handle provides a variety of methods to ease operations on a node. This includes
  /// low-level operations such as `moveElement(_:atSlot:)` or `pointerToValue(at:)` and
  /// higher level operations such as `insertElement(_:)`.
  ///
  /// There are two variants of an ``UnsafeHandle``. A mutable and immuable one.
  /// ``_Node.update(_:)`` is an example of a method which vends a mutable unsafe handle. Only a
  /// mutable unsafe handle can performed unsafe operations. This exists to ensure CoW-unsafe
  /// operations are not performed.
  ///
  /// Whene performing operations relating to children, it is important to know that not all nodes have
  /// children, or a children buffer allocated. Check the ``isLeaf`` property before accessing any
  /// properties or calling any methods which may interact with children.
  ///
  /// Additionally, when performing operations on values, a value buffer may not always be allocated.
  /// Check ``_Node.hasValues`` before performing such operations. Note that element-wise
  /// operations of the handle already perform such value checks and this step is not necessary.
  @usableFromInline
  @unsafe
  package struct UnsafeHandle {
    @usableFromInline
    package let header: UnsafeMutablePointer<Header>

    @usableFromInline
    package let keys: UnsafeMutablePointer<Key>

    @usableFromInline
    package let values: UnsafeMutablePointer<Value>?

    @usableFromInline
    package let children: UnsafeMutablePointer<_Node<Key, Value>>?
    
#if COLLECTIONS_INTERNAL_CHECKS
    @usableFromInline
    @safe
    internal let _isMutable: Bool
#endif

    @inlinable
    @inline(__always)
    internal init(
      keys: UnsafeMutablePointer<Key>,
      values: UnsafeMutablePointer<Value>?,
      children: UnsafeMutablePointer<_Node<Key, Value>>?,
      header: UnsafeMutablePointer<Header>,
      isMutable: Bool
    ) {
      unsafe self.keys = keys
      unsafe self.values = values
      unsafe self.children = children
      unsafe self.header = header

      #if COLLECTIONS_INTERNAL_CHECKS
      self._isMutable = isMutable
      #endif
    }
    
    @inlinable
    @inline(__always)
    @safe
    internal var isMutable: Bool {
      #if COLLECTIONS_INTERNAL_CHECKS
      return _isMutable
      #else
      return true
      #endif
    }
    
    /// Check that this handle supports mutating operations.
    /// Every member that mutates node data must start by calling this function.
    /// This helps preventing COW violations.
    ///
    /// Note that this is a noop in release builds.
    @inlinable
    @inline(__always)
    @safe
    internal func assertMutable() {
      #if COLLECTIONS_INTERNAL_CHECKS
      assert(self._isMutable,
             "Attempt to mutate a node through a read-only handle")
      #endif
    }
    
    // MARK: Invariant Checks
    #if COLLECTIONS_INTERNAL_CHECKS
    @inline(never)
    @usableFromInline
    internal func checkInvariants() {
      assert(depth != 0 || self.isLeaf,
             "Cannot have non-leaf of zero depth")
    }
    #else
    @inlinable
    @inline(__always)
    internal func checkInvariants() {}
    #endif // COLLECTIONS_INTERNAL_CHECKS
    
    /// Creates a mutable version of this handle
    /// - Warning: Calling this circumvents the CoW checks. 
    @inlinable
    @inline(__always)
    internal init(mutating handle: UnsafeHandle) {
      unsafe self.init(
        keys: handle.keys,
        values: handle.values,
        children: handle.children,
        header: handle.header,
        isMutable: true
      )
    }
    
    // MARK: Convenience properties
    @inlinable
    @inline(__always)
    internal var capacity: Int { unsafe header.pointee.capacity }

    /// The number of elements immediately stored in the node
    @inlinable
    @inline(__always)
    package var elementCount: Int {
      get {
        unsafe header.pointee.count
      }
      nonmutating set {
        assertMutable()
        unsafe header.pointee.count = newValue
      }
    }
    
    /// The total number of elements that this node directly or indirectly stores
    @inlinable
    @inline(__always)
    package var subtreeCount: Int {
      get {
        unsafe header.pointee.subtreeCount
      }
      nonmutating set {
        assertMutable()
        unsafe header.pointee.subtreeCount = newValue
      }
    }
    
    /// The depth of the node represented as the number of nodes below the current one.
    @inlinable
    @inline(__always)
    package var depth: Int {
      get {
        unsafe header.pointee.depth
      }
      nonmutating set {
        assertMutable()
        unsafe header.pointee.depth = newValue
      }
    }
    
    /// The number of children this node directly contains
    /// - Warning: Do not access on a leaf, else will panic.
    @inlinable
    @inline(__always)
    package var childCount: Int {
      assert(!isLeaf, "Cannot access the child count on a leaf")
      return unsafe elementCount &+ 1
    }
    
    /// Whether the node is the bottom-most node (a leaf) within its tree.
    ///
    /// This is equivalent to whether or not the node contains any keys. For leaf nodes,
    /// calling certain operations which depend on children may trap.
    @inlinable
    @inline(__always)
    @safe
    package var isLeaf: Bool { unsafe children == nil }

    /// A lower bound on the amount of keys we would want a node to contain.
    ///
    /// Defined as `ceil(capacity/2) - 1`.
    @inlinable
    @inline(__always)
    package var minimumElementCount: Int { unsafe capacity / 2 }

    /// Whether an element can be removed without triggering a rebalance.
    @inlinable
    @inline(__always)
    package var isShrinkable: Bool { unsafe elementCount > minimumElementCount }

    /// Whether the node contains at least the minimum number of keys.
    @inlinable
    @inline(__always)
    package var isBalanced: Bool { unsafe elementCount >= minimumElementCount }

    /// Whether the immediate node does not have space for an additional element
    @inlinable
    @inline(__always)
    package var isFull: Bool { unsafe elementCount == capacity }

    
    /// Checks uniqueness of a child.
    ///
    /// - Warning: Will trap if executed on leaf nodes
    @inlinable
    @inline(__always)
    package func isChildUnique(atSlot slot: Int) -> Bool {
      assert(!self.isLeaf, "Cannot access children on leaf")
      return unsafe isKnownUniquelyReferenced(
        &self.pointerToChild(atSlot: slot).pointee._storage
      )
    }
    
    /// Indicates that the node has no more children and is ready for deallocation
    ///
    /// It is critical to ensure that there are absolutely no children or element references
    /// still owned by this node, or else it may result in a serious memory leak.
    @inlinable
    @inline(__always)
    package func drop() {
      assertMutable()
      assert(unsafe self.elementCount == 0, "Cannot drop non-empty node")
      unsafe self.header.pointee.children?.deallocate()
      unsafe self.header.pointee.children = nil
    }
  }
}

// MARK: Subscript
extension _Node.UnsafeHandle {
  @inlinable
  @inline(__always)
  package subscript(elementAt slot: Int) -> _Node.Element {
    get {
      assert(
        unsafe 0 <= slot && slot < self.elementCount,
        "Node element subscript out of bounds")
      if _Node.hasValues {
        return unsafe (key: self[keyAt: slot], value: self[valueAt: slot])
      } else {
        return unsafe (key: self[keyAt: slot], value: _Node.dummyValue)
      }
    }
  }
  
  
  @inlinable
  @inline(__always)
  package func pointerToKey(
    atSlot slot: Int
  ) -> UnsafeMutablePointer<Key> {
    assert(
      unsafe 0 <= slot && slot < self.elementCount,
      "Node key slot out of bounds")
    return unsafe self.keys.advanced(by: slot)
  }
  
  @inlinable
  @inline(__always)
  package subscript(keyAt slot: Int) -> Key {
    get {
      assert(
        unsafe 0 <= slot && slot < self.elementCount,
        "Node key subscript out of bounds")
      return unsafe self.keys[slot]
    }
  }
  
  
  @inlinable
  @inline(__always)
  package func pointerToValue(
    atSlot slot: Int
  ) -> UnsafeMutablePointer<Value> {
    assert(
      unsafe 0 <= slot && slot < elementCount,
      "Node value slot out of bounds")
    assert(_Node.hasValues, "Node does not have value buffer")
    return unsafe values.unsafelyUnwrapped.advanced(by: slot)
  }
  
  @inlinable
  @inline(__always)
  package subscript(valueAt slot: Int) -> Value {
    get {
      assert(unsafe 0 <= slot && slot < self.elementCount,
             "Node values subscript out of bounds")
      assert(_Node.hasValues, "Node does not have value buffer")
      return unsafe self.pointerToValue(atSlot: slot).pointee
    }
    
    nonmutating _modify {
      assertMutable()
      assert(unsafe 0 <= slot && slot < self.elementCount,
             "Node values subscript out of bounds")
      assert(_Node.hasValues, "Node does not have value buffer")
      var value = unsafe self.pointerToValue(atSlot: slot).move()
      defer { unsafe self.pointerToValue(atSlot: slot).initialize(to: value) }
      yield &value
    }
  }
  
  @inlinable
  @inline(__always)
  package func pointerToChild(
    atSlot slot: Int
  ) -> UnsafeMutablePointer<_Node> {
    assert(unsafe 0 <= slot && slot < self.childCount,
           "Node child slot out of bounds")
    assert(!isLeaf, "Cannot access children of leaf node")
    return unsafe self.children.unsafelyUnwrapped.advanced(by: slot)
  }
  
  /// Returns the child at a given slot as a Node object
  /// - Warning: During mutations, re-accessing the same child slot is invalid.
  @inlinable
  @inline(__always)
  package subscript(childAt slot: Int) -> _Node {
    get {
      assert(!isLeaf, "Cannot access children of leaf node")
      assert(unsafe 0 <= slot && slot < self.childCount,
             "Node child subscript out of bounds")
      return unsafe self.children.unsafelyUnwrapped[slot]
    }
    
    nonmutating _modify {
      assertMutable()
      assert(!isLeaf, "Cannot modify children of leaf node")
      assert(unsafe 0 <= slot && slot < self.childCount,
             "Node child subscript out of bounds")
      var child = unsafe self.children.unsafelyUnwrapped.advanced(by: slot).move()
      defer {
        unsafe self.children.unsafelyUnwrapped.advanced(by: slot).initialize(to: child)
      }
      yield &child
    }
  }
}

// MARK: Binary Search
extension _Node.UnsafeHandle {
  /// Performs O(log n) search for a key, returning the first instance when duplicates exist. This
  /// returns the first possible insertion point for `key`.
  /// - Parameter key: The key to search for within the node.
  /// - Returns: Either the slot if the first instance of the key, otherwise
  ///     the valid insertion point for the key.
  @inlinable
  package func startSlot(forKey key: Key) -> Int {
    var start: Int = 0
    var end: Int = unsafe self.elementCount

    while end > start {
      let mid = (end &- start) / 2 &+ start
      
      // TODO: make this info a conditional_mov
      if unsafe key <= self.keys[mid] {
        end = mid
      } else {
        start = mid &+ 1
      }
    }
    
    return end
  }
  
  /// Performs O(log n) search for a key, returning the last instance when duplicates exist. This
  /// returns the last possible valid insertion point for `key`.
  /// - Parameter key: The key to search for within the node.
  /// - Returns: Either the slot after the last instance of the key, otherwise
  ///     the valid insertion point for the key.
  @inlinable
  package func endSlot(forKey key: Key) -> Int {
    var start: Int = 0
    var end: Int = unsafe self.elementCount

    while end > start {
      let mid = (end &- start) / 2 &+ start
      
      if unsafe key >= self.keys[mid] {
        start = mid &+ 1
      } else {
        end = mid
      }
    }
    
    return end
  }
}

// MARK: Element-wise Buffer Operations
extension _Node.UnsafeHandle {
  /// Moves elements from the current handle to a new handle.
  ///
  /// This moves initialized elements to an sequence of initialized element slots in the target handle.
  ///
  /// - Parameters:
  ///   - target: The destination handle to write to which could be the same
  ///       as the source to move within a handle.
  ///   - sourceSlot: The offset of the source handle to move from.
  ///   - destinationSlot: The offset of the destination handle to write to.
  ///   - count: The count of values to move
  /// - Warning: This does not adjust the buffer counts.
  @inlinable
  @inline(__always)
  package func moveInitializeElements(
    count: Int,
    fromSlot sourceSlot: Int,
    toSlot destinationSlot: Int,
    of target: _Node.UnsafeHandle
  ) {
    assert(sourceSlot >= 0, "Move source slot must be positive")
    assert(destinationSlot >= 0, "Move destination slot must be positive")
    assert(count >= 0, "Amount of elements to move be positive")
    assert(unsafe sourceSlot + count <= self.capacity,
           "Cannot move elements beyond source buffer capacity")
    assert(unsafe destinationSlot + count <= target.capacity,
           "Cannot move elements beyond destination buffer capacity")
    
    self.assertMutable()
    target.assertMutable()
    
    unsafe target.keys.advanced(by: destinationSlot)
      .moveInitialize(from: self.keys.advanced(by: sourceSlot), count: count)
    
    if _Node.hasValues {
      unsafe target.values.unsafelyUnwrapped.advanced(by: destinationSlot)
        .moveInitialize(
          from: self.values.unsafelyUnwrapped.advanced(by: sourceSlot),
          count: count
        )
    }
  }
  
  /// Moves children from the current handle to a new handle
  ///
  /// This moves initialized children to an sequence of initialized element slots in the target handle.
  ///
  /// - Parameters:
  ///   - target: The destination handle to write to which could be the same
  ///       as the source to move within a handle.
  ///   - sourceSlot: The offset of the source handle to move from.
  ///   - destinationSlot: The offset of the destination handle to write to.
  ///   - count: The amount of values to move
  /// - Warning: This does not adjust the buffer counts.
  /// - Warning: This will trap if either the source and destination handles are leaves.
  @inlinable
  @inline(__always)
  package func moveInitializeChildren(
    count: Int,
    fromSlot sourceSlot: Int,
    toSlot destinationSlot: Int,
    of target: _Node.UnsafeHandle
  ) {
    assert(sourceSlot >= 0, "Move source slot must be positive")
    assert(destinationSlot >= 0, "Move destination slot must be positive")
    assert(count >= 0, "Amount of children to move be positive")
    assert(unsafe sourceSlot + count <= self.capacity + 1,
           "Cannot move children beyond source buffer capacity")
    assert(unsafe destinationSlot + count <= target.capacity + 1,
           "Cannot move children beyond destination buffer capacity")
    assert(!target.isLeaf, "Cannot move children to a leaf node")
    assert(!self.isLeaf, "Cannot move children from a leaf node")
    
    self.assertMutable()
    target.assertMutable()
    
    let sourcePointer =
      unsafe self.children.unsafelyUnwrapped.advanced(by: sourceSlot)

    unsafe target.children.unsafelyUnwrapped.advanced(by: destinationSlot)
      .moveInitialize(from: sourcePointer, count: count)
  }
  
  /// Inserts a new element into an uninitialized slot in node.
  ///
  /// This ensures that a child is provided where appropriate and may trap if a right
  /// child is not provided iff the node is a leaf.
  ///
  /// - Parameters:
  ///   - slot: An uninitialized slot in the buffer to insert the element into.
  ///   - element: The element to insert which the node will take ownership of.
  ///   - rightChild: The right child of the newly initialized element. Should be `nil` iff
  ///       node is a leaf.
  /// - Warning: This does not adjust the buffer counts.
  @inlinable
  @inline(__always)
  package func initializeElement(
    atSlot slot: Int,
    to element: _Node.Element,
    withRightChild rightChild: _Node?
  ) {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.capacity,
           "Cannot insert beyond node capacity")
    assert(self.isLeaf == (rightChild == nil),
           "A child can only be inserted iff the node is a leaf")
    
    unsafe self.initializeElement(atSlot: slot, to: element)

    if let rightChild = rightChild {
      unsafe self.children.unsafelyUnwrapped
        .advanced(by: slot + 1)
        .initialize(to: rightChild)
    }
  }
  
  /// Inserts a new element into an uninitialized slot in node.
  ///
  /// This ensures that a child is provided where appropriate and may trap if a left
  /// child is not provided iff the node is a leaf.
  ///
  /// - Parameters:
  ///   - element: The element to insert which the node will take ownership of.
  ///   - slot: An uninitialized slot in the buffer to insert the element into.
  ///   - leftChild: The left child of the newly initialized element. Should be `nil` iff
  ///       node is a leaf.
  /// - Warning: This does not adjust the buffer counts.
  @inlinable
  @inline(__always)
  package func initializeElement(
    atSlot slot: Int,
    to element: _Node.Element,
    withLeftChild leftChild: _Node?
  ) {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.capacity,
           "Cannot insert beyond node capacity")
    assert(self.isLeaf == (leftChild == nil),
           "A child can only be inserted iff the node is a leaf")
    
    unsafe self.initializeElement(atSlot: slot, to: element)

    if let leftChild = leftChild {
      unsafe self.children.unsafelyUnwrapped
        .advanced(by: slot)
        .initialize(to: leftChild)
    }
  }
  
  /// Inserts a new element into an uninitialized slot in node.
  ///
  /// - Parameters:
  ///   - element: The element to insert which the node will take ownership of.
  ///   - slot: An uninitialized slot in the buffer to insert the element into.
  /// - Warning: This does not adjust the buffer counts.
  @inlinable
  @inline(__always)
  package func initializeElement(atSlot slot: Int, to element: _Node.Element) {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.capacity,
           "Cannot insert beyond node capacity")
    
    unsafe self.keys.advanced(by: slot).initialize(to: element.key)
    if _Node.hasValues {
      unsafe self.values.unsafelyUnwrapped.advanced(by: slot).initialize(to: element.value)
    }
  }
  
  /// Moves an element out of the handle and returns it.
  ///
  /// This may leave a hold within the node's buffer so it is critical to ensure that
  /// it is filled, either by inserting a new element or some other operation.
  ///
  /// Additionally, this does not touch the children of the node, so it is important to
  /// ensure those are correctly handled.
  ///
  /// - Parameter slot: The in-bounds slot of an element to move out
  /// - Returns: A tuple of the key and value.
  /// - Warning: This does not adjust buffer counts
  @inlinable
  @inline(__always)
  package func moveElement(atSlot slot: Int) -> _Node.Element {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.elementCount,
           "Attempted to move out-of-bounds element")
    
    return unsafe (
      key: self.pointerToKey(atSlot: slot).move(),
      value: _Node.hasValues
        ? self.pointerToValue(atSlot: slot).move()
        : _Node.dummyValue
    )
  }
  
  /// Moves an element out of the handle and returns it.
  ///
  /// This may leave a hold within the node's buffer so it is critical to ensure that
  /// it is filled, either by inserting a new child or some other operation.
  ///
  /// - Parameter slot: The in-bounds slot of an chile to move out
  /// - Returns: The child node object.
  /// - Warning: This does not adjust buffer counts
  @inlinable
  @inline(__always)
  package func moveChild(atSlot slot: Int) -> _Node {
    assertMutable()
    assert(!self.isLeaf, "Can only move a child on a non-leaf node")
    assert(unsafe 0 <= slot && slot < self.childCount,
           "Attempted to move out-of-bounds child")
    
    return unsafe self.children.unsafelyUnwrapped.advanced(by: slot).move()
  }
  
  /// Appends a new element.
  @inlinable
  @inline(__always)
  package func appendElement(_ element: _Node.Element) {
    assertMutable()
    assert(unsafe elementCount < capacity, "Cannot append into full node")
    assert(unsafe elementCount == 0 || self[keyAt: elementCount - 1] <= element.key,
           "Cannot append out-of-order element")
    
    unsafe initializeElement(atSlot: elementCount, to: element)

    unsafe elementCount += 1
    unsafe subtreeCount += 1
  }
  
  
  /// Appends a new element with a provided right child.
  @inlinable
  @inline(__always)
  package func appendElement(
    _ element: _Node.Element,
    withRightChild rightChild: _Node
  ) {
    assertMutable()
    assert(!self.isLeaf, "Cannot append on leaf")
    assert(unsafe elementCount < capacity, "Cannot append into full node")
    assert(unsafe elementCount == 0 || self[keyAt: elementCount - 1] <= element.key,
           "Cannot append out-of-order element")
    
    unsafe initializeElement(
      atSlot: elementCount,
      to: element,
      withRightChild: rightChild
    )
    
    unsafe elementCount += 1
    unsafe subtreeCount += 1 + rightChild.storage.header.subtreeCount
  }
  
  /// Swaps the element at a given slot, returning the old one.
  /// - Parameters:
  ///   - slot: The initialized slot at which to swap the element
  ///   - newElement: The new element to insert
  /// - Returns: The old element from the slot.
  @inlinable
  @inline(__always)
  @discardableResult
  package func exchangeElement(
    atSlot slot: Int,
    with newElement: _Node.Element
  ) -> _Node.Element {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.elementCount,
           "Attempted to swap out-of-bounds element")
    
    let oldElement = unsafe self.moveElement(atSlot: slot)
    unsafe self.initializeElement(atSlot: slot, to: newElement)
    return oldElement
  }
  
  /// Swaps the child at a given slot, returning the old one
  /// - Parameters:
  ///   - slot: The initialized slot at which to swap the child
  ///   - newChild: The new child to insert
  /// - Returns: The old child from the slot.
  @inlinable
  @inline(__always)
  @discardableResult
  package func exchangeChild(
    atSlot slot: Int,
    with newChild: _Node
  ) -> _Node {
    assertMutable()
    assert(!self.isLeaf, "Cannot exchange children on a leaf node")
    assert(unsafe 0 <= slot && slot < self.childCount,
           "Attempted to swap out-of-bounds element")
    
    let oldChild = unsafe self.moveChild(atSlot: slot)
    unsafe self.pointerToChild(atSlot: slot).initialize(to: newChild)
    return oldChild
  }
  
  /// Removes a child node pair from a given slot within the node. This is assumed to
  /// run on a leaf.
  ///
  /// This is effectively the same as ``_Node.UnsafeHandle.moveChild(atSlot:)``
  /// however, this also moves surrounding elements as to prevent gaps from appearing
  /// within the buffer.
  ///
  /// This does not touch the elements in the node, so it is important to ensure those are
  /// correctly handled.
  ///
  /// This operation does adjust the stored subtree count on the node as appropriate.
  ///
  /// - Parameter slot: The slot to remove which must be in-bounds.
  /// - Returns: The child that was removed.
  /// - Warning: This performs neither balancing, rotation, or count updates.
  @inlinable
  @inline(__always)
  package func removeChild(atSlot slot: Int) -> _Node {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.childCount,
           "Attempt to remove out-of-bounds child")
    
    let child = unsafe self.moveChild(atSlot: slot)

    // Shift everything else over to the left
    unsafe self.moveInitializeChildren(
      count: self.childCount - slot - 1,
      fromSlot: slot + 1,
      toSlot: slot, of: self)
    
    unsafe self.subtreeCount -= child._subtreeCount

    return child
  }
  
  /// Removes a key-value pair from a given slot within the node.
  ///
  /// This does not touch the children of the node, so it is important to ensure those are
  /// correctly handled.
  ///
  /// This operation adjusts the stored counts on the node as appropriate.
  ///
  /// - Parameter slot: The slot to remove which must be in-bounds.
  /// - Returns: The element that was removed.
  /// - Warning: This does not perform any balancing or rotation.
  @inlinable
  @inline(__always)
  @discardableResult
  package func removeElement(atSlot slot: Int) -> _Node.Element {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.elementCount,
           "Attempt to remove out-of-bounds element")
    
    let element = unsafe self.moveElement(atSlot: slot)

    // Shift everything else over to the left
    unsafe self.moveInitializeElements(
      count: self.elementCount - slot - 1,
      fromSlot: slot + 1,
      toSlot: slot, of: self
    )
    
    unsafe self.elementCount -= 1
    unsafe self.subtreeCount -= 1

    return element
  }
  
  /// Removes a **key** from a given slot within the node.
  ///
  /// This does not touch the children of the node, so it is important to ensure those are
  /// correctly handled.
  ///
  /// This assumes the value buffer at the slot is deallocated
  ///
  /// This operation adjusts the stored counts on the node as appropriate.
  ///
  /// - Parameter slot: The slot to remove which must be in-bounds.
  /// - Returns: The element that was removed.
  /// - Warning: This does not perform any balancing or rotation.
  @inlinable
  @inline(__always)
  @discardableResult
  package func removeElementWithoutValue(atSlot slot: Int) -> Key {
    assertMutable()
    assert(unsafe 0 <= slot && slot < self.elementCount,
           "Attempt to remove out-of-bounds element")
    
    let key = unsafe self.pointerToKey(atSlot: slot).move()

    // Shift everything else over to the left
    unsafe self.moveInitializeElements(
      count: self.elementCount - slot - 1,
      fromSlot: slot + 1,
      toSlot: slot, of: self
    )
    
    unsafe self.elementCount -= 1
    unsafe self.subtreeCount -= 1

    return key
  }
}

#endif
