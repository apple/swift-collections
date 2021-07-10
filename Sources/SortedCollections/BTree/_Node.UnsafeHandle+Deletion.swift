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
        // removeElement(at:) automatically adjusts node counts.
        return self.removeElement(at: slot)
      } else {
        // Deletion within an internal node
        
        // TODO: potentially be smarter about using the predecessor or successor.0
        let predecessor = self[childAt: slot].update { $0.popElement() }
        
        // Reduce the element count.
        self.numTotalElements -= 1
        
        // Replace the current element with the predecessor.
        let element = self.moveElement(at: slot)
        self.setElement(predecessor, at: slot)
        
        // Balance the predecessor child slot, as the pop operation may have
        // brought it out of balance.
        self.balance(at: slot)
        
        return element
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
        
        let removedElement = self[childAt: slot].update({ $0.removeAny(key: key) })
        
        if let removedElement = removedElement {
          self.numTotalElements -= 1
          
          // TODO: performing the remove and then balancing may result in an
          // extra memmove being performed.
          
          // TODO: avoid the branch and perhaps unconditionally balance the tree.
          
          // Determine if the child needs to be rebalanced
          self.balance(at: slot)
          
          return removedElement
        } else {
          // Could not find the key
          return nil
        }
      }
    }
  }
  
  /// Removes the last element of a tree, balancing the tree.
  ///
  /// This may leave the node it is called upon unbalanced so it is important to
  /// ensure the tree above this is balanced. This does adjust child counts
  ///
  /// - Returns: The moved last element of the tree.
  @inlinable
  @inline(__always)
  internal func popElement() -> _Node.Element {
    assertMutable()
    
    if self.isLeaf {
      // At a leaf, it is trivial to pop the last element
      // removeElement(at:) automatically updates the counts.
      return self.removeElement(at: self.numElements - 1)
    } else {
      // Remove the subtree's element
      let poppedElement = self[childAt: self.numChildren - 1].update { $0.popElement() }
      
      self.numTotalElements -= 1
      
      self.balance(at: self.numChildren - 1)
      return poppedElement
    }
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
    if self[childAt: slot].read({ $0.isBalanced }) { return }
    
    if slot > 0 && self[childAt: slot - 1].read({ $0.isAboveMinCapacity }) {
      // We can rotate from the left node to the right node
      self.rotateRight(at: slot - 1)
    } else if slot < self.numChildren - 1 && self[childAt: slot + 1].read({ $0.isAboveMinCapacity }) {
      // We can rotate from the right node to the left node
      self.rotateLeft(at: slot)
    } else if slot == self.numChildren - 1 {
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
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightHandle in
        assert(rightHandle.numElements < rightHandle.capacity, "Rotating into full node.")
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        
        // Shift the rest of the elements right
        rightHandle.moveElements(toHandle: rightHandle, fromSlot: 0, toSlot: 1, count: rightHandle.numElements)
        
        // Extract the parent's current element and move it down to the right node
        let oldParentElement = self.moveElement(at: slot)
        if !rightHandle.isLeaf {
          // Move the corresponding children to the right
          rightHandle.moveChildren(toHandle: rightHandle, fromSlot: 0, toSlot: 1, count: rightHandle.numChildren)
          
          // We'll extract the last child of the left node, if it exists,
          // in order to cycle it.
          // removeChild(at:) takes care of adjusting the total element counts.
          let newLeftChild: _Node = leftHandle.removeChild(at: leftHandle.numChildren - 1)
          
          // Move the left child if applicable to the right node.
          rightHandle.setElement(oldParentElement, withLeftChild: newLeftChild, at: 0)
          
          rightHandle.numTotalElements += newLeftChild.read({ $0.numTotalElements })
        } else {
          // Move the left child if applicable to the right node.
          rightHandle.setElement(oldParentElement, at: 0)
        }
        
        // Move the left node's key up to the parent
        // removeElement(at:) takes care of adjusting the node counts.
        let newParentElement = leftHandle.removeElement(at: leftHandle.numElements - 1)
        self.setElement(newParentElement, at: slot)
        
        // Adjust the element counts as applicable
        rightHandle.numElements += 1
        rightHandle.numTotalElements += 1
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
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightHandle in
        assert(rightHandle.numElements > 0, "Cannot rotate from empty node.")
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        
        // Move the right child if applicable to the left node.
        // We'll extract the first child of the right node, if it exists,
        // in order to cycle it.
        // Then, cycle the parent's element down to the left child
        let oldParentElement = self.moveElement(at: slot)
        if !leftHandle.isLeaf {
          // removeChild(at:) takes care of adjusting the node counts.
          let newRightChild = rightHandle.removeChild(at: 0)
          
          leftHandle.setElement(
            oldParentElement,
            withRightChild: newRightChild,
            at: leftHandle.numElements
          )
          
          // Adjust the total element counts
          leftHandle.numTotalElements += newRightChild.read({ $0.numTotalElements })
        } else {
          leftHandle.setElement(oldParentElement, at: leftHandle.numElements)
        }
        
        // Cycle the right child's element up to the parent.
        // removeElement(at:) takes care of adjusting the node counts.
        let newParentElement = rightHandle.removeElement(at: 0)
        self.setElement(newParentElement, at: slot)
        
        leftHandle.numElements += 1
        leftHandle.numTotalElements += 1
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
  /// - Note: This method is only valid on a non-leaf nodes.
  /// - Warning: Calling this may result in empty nodes and a state which breaks the
  ///     B-Tree invariants, ensure the tree is further balanced after this.`
  @inlinable
  @inline(__always)
  internal func collapse(at slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.numElements, "Cannot collapse out-of-bounds slot")
    assert(!self.isLeaf, "Cannot collapse a slot of a leaf node.")
    
    self[childAt: slot].update { leftHandle in
      var rightChild = self.moveChild(at: slot + 1)
      
      // TODO: create optimized version that avoids a CoW copy for when the
      // right child is shared.
      rightChild.update { rightHandle in
        // Ensure the left handle is large enough to contain all the items
        assert(
          leftHandle.capacity >= leftHandle.numElements + rightHandle.numElements + 1,
          "Left child undersized to contain collapsed subtree."
        )
        assert(leftHandle.isLeaf == rightHandle.isLeaf, "Encountered subtrees of conflicting depth.")
        
        // Move the remaining children
        //   ┌─┬─┬─┬─┐
        //   │1│X│5│7│
        //   └─┴─┴┬┴─┘
        //      ▲ │
        //      └─┘
        self.moveChildren(
          toHandle: self,
          fromSlot: slot + 2,
          toSlot: slot + 1,
          count: self.numElements - slot - 1
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
        // The removeElement(at:) takes care of adjusting the element
        // count on the parent.
        leftHandle.setElement(
          self.removeElement(at: slot),
          at: leftHandle.numElements
        )
        
        // Increment the total element count since we merely moved the
        // parent element within the same subtree
        self.numTotalElements += 1
        
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
        
        // Move the children of the right node to the left node
        if !rightHandle.isLeaf {
          rightHandle.moveChildren(
            toHandle: leftHandle,
            fromSlot: 0,
            toSlot: leftHandle.numElements + 1,
            count: rightHandle.numChildren
          )
        }
        
        // Adjust the child counts
        leftHandle.numElements += rightHandle.numElements + 1
        leftHandle.numTotalElements += rightHandle.numTotalElements + 1
        
        // Clear out the child counts for the right handle
        // TODO: As part of deletion, we probably already visited the right
        // node, so it's possible we just created a CoW copy of it, only do
        // deallocate it. Not a big deal but an inefficiency to note.
        rightHandle.numElements = 0
        rightHandle.drop()
      }
    }
  }
}
