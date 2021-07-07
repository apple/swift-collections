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

extension _Node.UnsafeHandle {
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
  @inline(__always)
  @discardableResult
  internal func removeAny(key: Key) -> _Node.Element? {
    assertMutable()
    
    let slot = self.firstSlot(for: key)
    
    if slot < self.numElements && self[keyAt: slot] == key {
      // We have found the key
      if self.isLeaf {
        // Deletion within a leaf
        
        return self.removeElement(at: slot)
      } else {
        // Deletion within an internal node
        
        // TODO: implement
        
        if self.numElements <= self.minCapacity {
          // Removing the element will make the element undersized
        } else {
          // Swap with the
        }
      }
    } else {
      if self.isLeaf {
        // If we're in a leaf node and didn't find the key, it does
        // not exist.
        return nil
      } else {
        // Sanity-check
        assert(slot < self.numChildren, "Attempt to remove from invalid child.")
        assert(self.isLeaf || self.numElements >= self.minCapacity, "Encountered unbalanced subtree.")
        
        return self[childAt: slot].update { handle in
          // Continue searching and attempting to remove the key
          // from the appropriate subtree.
          
          if let result = handle.removeAny(key: key) {
            // TODO: performing the remove and then balancing may result in an
            // extra memmove being performed.
            
            // Determine if the child needs to be rebalanced
            self.balance(at: slot)
            
            return result
          } else {
            // Could not find the key
            return nil
          }
        }
      }
    }
    
    return nil
  }
}

// MARK: Balancing
extension _Node.UnsafeHandle {
  
  // TODO: Explore inline vs no inline
  /// Balances a node's child at a specific slot to maintain the BTree invariants
  /// and ensure none of its children underflows.
  ///
  /// Calling this method may make the current node underflow. Therefore,  this
  /// should be called upwards on the entire tree.
  ///
  /// If no balancing needs to occur, then this method leaves the tree unchanged.
  ///
  /// - Parameter slot: The slot containing the child to balance.
  @inlinable
  @inline(__always)
  internal func balance(at slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.numChildren, "Cannot balance out-of-bounds slot.")
    assert(!self.isLeaf, "Cannot balance leaf.")
    
    // No need to balance if the node is already balanced
    if self.isBalanced { return }
    
    if slot > 0 && self[childAt: slot - 1].read({ $0.isAboveMinCapacity }) {
      // We can rotate from the left node to the right node
      self.rotateRight(at: slot - 1)
    } else if slot < self.numElements - 1 && self[childAt: slot - 1].read({ $0.isAboveMinCapacity }) {
      // We can rotate from the right node to the left node
      self.rotateLeft(at: slot - 1)
    } else if slot == self.numElements - 1 {
      // In the special case the deficient child at the end,
      // it'll be merged with it's left sibling.
      self.collapse(at: slot - 1)
    } else {
      // Otherwise collapse the child with its right sibling.
      self.collapse(at: slot)
    }
  }
  
  /// Performs a right-rotation of the key at a given slot.
  ///
  /// The rotation occurs among the keys corresponding left and right child. This
  /// does not perform any checks to ensure underflow does not occur.
  ///
  /// - Parameter slot: The slot containing the child to balance.
  @inlinable
  @inline(__always)
  internal func rotateRight(at slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.numElements, "Cannot rotate out-of-bounds slot.")
    
    self[childAt: slot].update { leftHandle in
      assert(leftHandle.numElements > 0, "Cannot rotate from empty node.")
      
      // Extract the key from the old parent
      let oldElement = self.moveElement(at: slot)
      
      // Pull up the left child's element. This automatically adjusts the counts.
      let newElement = leftHandle.removeElement(at: leftHandle.numElements - 1)
      
      // And place it into the parent
      self.setElement(newElement, withRightChild: nil, at: slot)
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightHandle in
        assert(rightHandle.numElements < rightHandle.capacity, "Rotating into full node.")
        
        // Shift the rest of the elements right
        rightHandle.moveElements(toHandle: rightHandle, fromSlot: 0, toSlot: 1, count: rightHandle.numChildren)
        
        // Insert the old parent element into the right child
        rightHandle.setElement(oldElement, withRightChild: nil, at: 0)
        
        // Adjust the element counts as applicable
        rightHandle.numElements += 1
        rightHandle.numTotalElements += 1
        
        // Move the children if applicable
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        if !leftHandle.isLeaf {
          rightHandle.moveChildren(toHandle: rightHandle, fromSlot: 0, toSlot: 1, count: rightHandle.numChildren)
          leftHandle.moveChildren(toHandle: rightHandle, fromSlot: leftHandle.numChildren - 1, toSlot: 0, count: 1)
        }
      }
    }
  }
  
  /// Performs a left-rotation of the key at a given slot.
  ///
  /// The rotation occurs among the keys corresponding left and right child. This
  /// does not perform any checks to ensure underflow does not occur.
  ///
  /// - Parameter slot: The slot containing the child to balance.
  @inlinable
  @inline(__always)
  internal func rotateLeft(at slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.numElements, "Cannot rotate out-of-bounds slot.")
    
    self[childAt: slot].update { leftHandle in
      assert(leftHandle.numElements < leftHandle.capacity, "Rotating into full node.")
      
      // Cycle the parent's element down to the left child
      self.moveElements(
        toHandle: leftHandle,
        fromSlot: slot,
        toSlot: leftHandle.numElements,
        count: 1
      )
      
      // Adjust left handle counts
      leftHandle.numElements += 1
      leftHandle.numTotalElements += 1
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightHandle in
        assert(rightHandle.numElements > 0, "Cannot rotate from empty node.")
        
        // Cycle the right child's element up to the parent.
        rightHandle.moveElements(
          toHandle: self,
          fromSlot: 0,
          toSlot: slot,
          count: 1
        )
        
        // Adjust the right handle's children
        rightHandle.moveElements(
          toHandle: rightHandle,
          fromSlot: 1,
          toSlot: 0,
          count: rightHandle.numElements - 1
        )
        
        // Adjust the right handle counts
        rightHandle.numElements -= 1
        rightHandle.numTotalElements -= 1
        
        // Move the children if applicable
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        if !leftHandle.isLeaf {
          // Move the (formerly) right child to the correct position.
          rightHandle.moveChildren(
            toHandle: leftHandle,
            fromSlot: 0,
            toSlot: leftHandle.numChildren,
            count: 1
          )
        }
      }
    }
  }
  
  /// Collapses a slot and its children into a single child.
  ///
  /// This will reuse the left childs node for the new node. As a result, ensure
  /// that the left node is large enough to contain both the parent and the
  /// right child's contents, else this method may trap.
  ///
  /// As an example, calling this method on a tree such as:
  ///
  ///         ┌─┐
  ///         │5│
  ///       ┌─┴─┴─┐
  ///       │     │
  ///     ┌─┼─┐ ┌─┼─┐
  ///     │1│3│ │7│9│
  ///     └─┴─┘ └─┴─┘
  ///
  /// will result in a single collapsed node such as:
  ///
  ///     ┌─┬─┬─┬─┬─┐
  ///     │1│3│5│7│9│
  ///     └─┴─┴─┴─┴─┘
  ///
  /// - Parameter slot: The slot at which to collapse its children.
  /// - Note: This method is only valid on a non-leaf node.
  @inlinable
  @inline(__always)
  internal func collapse(at slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.numElements, "Cannot collapse out-of-bounds slot")
    assert(!self.isLeaf, "Cannot collapse a slot of a leaf node.")
    // TODO: rethink this assertion
    assert(self.numElements > 1, "Cannot collapse a slot that is the only element.")
    
    self[childAt: slot].update { leftHandle in
      self[childAt: slot + 1].update { rightHandle in
        // Ensure the left handle is large enough to contain all the items
        assert(
          leftHandle.capacity >= leftHandle.numElements + rightHandle.numElements + 1,
          "Left child undersized to contain collapsed subtree."
        )
        
        // Move the element from the parent into the the left child
        //
        //        ┌─┐
        //        │5│
        //     ┌──┴─┴──┐
        //     │   │   │
        //   ┌─┼─┐ │ ┌─┼─┐
        //   │1│3│ │ │7│9│
        //   └─┴─┘ │ └─┴─┘
        //         ▼
        //    ┌─┬─┬─┬─┬─┐
        //    │1│3│5│7│9│
        //    └─┴─┴─┴─┴─┘
        self.moveElements(
          toHandle: leftHandle,
          fromSlot: slot,
          toSlot: leftHandle.numElements,
          count: 1
        )
        
        
        // TODO: might be more optimal to memcpy the right child, and avoid
        // potentially creating a CoW copy of it. This will require more
        // thinking
        
        // Move the right child's elements into the left child
        //        ┌─┐
        //        │5│
        //      ┌─┴─┴─┐
        //      │     │
        //    ┌─┼─┐ ┌─┼─┐
        //    │1│3│ │7│9│
        //    └─┴─┘ └─┴─┘
        //            │
        //            ▼
        //    ┌─┬─┬─┬─┬─┐
        //    │1│3│5│7│9│
        //    └─┴─┴─┴─┴─┘
        rightHandle.moveElements(
          toHandle: leftHandle,
          fromSlot: 0,
          toSlot: leftHandle.numElements + 1,
          count: rightHandle.numElements
        )
        
        // Move the remaining elements and their children
        //   ┌─┬─┬─┬─┐
        //   │1│X│5│7│
        //   └─┴─┴┬┴─┘
        //      ▲ │
        //      └─┘
        self.moveElements(
          toHandle: self,
          fromSlot: slot + 1,
          toSlot: slot,
          count: self.numElements - slot - 1
        )
        self.moveChildren(
          toHandle: self,
          fromSlot: slot + 2,
          toSlot: slot + 1,
          count: self.numElements - slot - 1
        )
        
        // Move the children of the right node to the left node
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        if !rightHandle.isLeaf {
          rightHandle.moveChildren(
            toHandle: leftHandle,
            fromSlot: 0,
            toSlot: leftHandle.numElements + 1,
            count: rightHandle.numChildren
          )
        }
        
        // The total elements of the node stays constant, however one of them
        // moved to the child, so only the current node's element count needs
        // to change
        self.numElements -= 1
        
        // Adjust the child counts
        leftHandle.numElements += rightHandle.numElements + 1
        leftHandle.numTotalElements += rightHandle.numElements + 1
        
        // Clear out the child counts for the right handle
        // TODO: As part of deletion, we probably already visited the right
        // node, so it's possible we just created a CoW copy of it, only do
        // deallocate it. Not a big deal but an inefficiency to note.
        rightHandle.numElements = 0
        rightHandle.numTotalElements = 0
      }
    }
  }
}
