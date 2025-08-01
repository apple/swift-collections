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
  /// If the key is not found, the tree is not modified, although the version of the tree may change.
  ///
  /// - Parameter key: The key to remove in the tree
  /// - Returns: The key-value pair which was removed. `nil` if not removed.
  @inlinable
  @inline(__always)
  @discardableResult
  internal func removeAnyElement(forKey key: Key) -> _Node.Element? {
    assertMutable()
    
    let slot = self.startSlot(forKey: key)
    
    if slot < self.elementCount && self[keyAt: slot] == key {
      // We have found the key
      if self.isLeaf {
        // Deletion within a leaf
        // removeElement(atSlot:) automatically adjusts node counts.
        return self.removeElement(atSlot: slot)
      } else {
        // Deletion within an internal node
        
        // TODO: potentially be smarter about using the predecessor or successor.
        let predecessor = self[childAt: slot].update { $0.popLastElement() }
        
        // Reduce the element count.
        self.subtreeCount -= 1
        
        // Replace the current element with the predecessor.
        let element = self.exchangeElement(atSlot: slot, with: predecessor)
        
        // Balance the predecessor child slot, as the pop operation may have
        // brought it out of balance.
        self.balance(atSlot: slot)
        
        return element
      }
    } else {
      if self.isLeaf {
        // If we're in a leaf node and didn't find the key, it does
        // not exist.
        return nil
      } else {
        assert(slot < self.childCount, "Attempt to remove from invalid child")
        
        let removedElement = self[childAt: slot].update({
          $0.removeAnyElement(forKey: key)
        })
        
        guard let removedElement = removedElement else {
          // Could not find the key
          return nil
        }
        
        self.subtreeCount -= 1
        
        // TODO: performing the remove and then balancing may result in an
        // extra memmove being performed.
        
        // Determine if the child needs to be rebalanced
        self.balance(atSlot: slot)
        
        return removedElement
      }
    }
  }
  
  /// Removes the element of the tree rooted at this node, at a given offset.
  ///
  /// This may leave the node it is called upon unbalanced so it is important to
  /// ensure the tree above this is balanced. This does adjust child counts
  ///
  /// - Parameter offset: the offset which must be in-bounds.
  /// - Returns: The moved element of the tree
  @inlinable
  @inline(__always)
  internal func remove(at offset: Int) -> _Node.Element {
    assertMutable()
    assert(0 <= offset && offset < self.subtreeCount,
           "Cannot remove with out-of-bounds offset.")
    
    if self.isLeaf {
      return self.removeElement(atSlot: offset)
    }
    
    // Removing from within an internal node
    var startIndex = 0
    for childSlot in 0..<self.childCount {
      let endIndex =
        startIndex + self[childAt: childSlot].read { $0.subtreeCount }
      
      if offset < endIndex {
        let element = self[childAt: childSlot].update {
          $0.remove(at: offset - startIndex)
        }
        
        // Reduce the subtree count.
        self.subtreeCount -= 1
        
        return element
      } else if offset == endIndex {
        let predecessor = self[childAt: childSlot].update {
          $0.popLastElement()
        }
        
        self.subtreeCount -= 1
        
        // Replace the current element with the predecessor.
        let element = self.exchangeElement(atSlot: childSlot, with: predecessor)
        
        // Balance the predecessor child slot, as the pop operation may have
        // brought it out of balance.
        self.balance(atSlot: childSlot)
        
        return element
      } else {
        startIndex = endIndex + 1
      }
    }
    
    preconditionFailure("B-Tree in invalid state.")
  }
  
  /// Removes the first element of a tree, balancing the tree.
  ///
  /// This may leave the node it is called upon unbalanced so it is important to
  /// ensure the tree above this is balanced. This does adjust child counts
  ///
  /// - Returns: The moved first element of the tree.
  @inlinable
  @inline(__always)
  internal func popFirstElement() -> _Node.Element {
    assertMutable()
    
    if self.isLeaf {
      // At a leaf, it is trivial to pop the last element
      // removeElement(atSlot:) automatically updates the counts.
      return self.removeElement(atSlot: 0)
    }
    
    // Remove the subtree's element
    let poppedElement = self[childAt: 0].update { $0.popFirstElement() }
    
    self.subtreeCount -= 1
    
    self.balance(atSlot: 0)
    return poppedElement
  }
  
  /// Removes the last element of a tree, balancing the tree.
  ///
  /// This may leave the node it is called upon unbalanced so it is important to
  /// ensure the tree above this is balanced. This does adjust child counts
  ///
  /// - Returns: The moved last element of the tree.
  @inlinable
  @inline(__always)
  internal func popLastElement() -> _Node.Element {
    assertMutable()
    
    if self.isLeaf {
      // At a leaf, it is trivial to pop the last element
      // popLastElement(at:) automatically updates the counts.
      return self.removeElement(atSlot: self.elementCount - 1)
    }
    
    // Remove the subtree's element
    let poppedElement = self[childAt: self.childCount - 1].update {
      $0.popLastElement()
    }
    
    self.subtreeCount -= 1
    
    self.balance(atSlot: self.childCount - 1)
    return poppedElement
  }
}

// MARK: Balancing
extension _Node.UnsafeHandle {
  
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
  internal func balance(atSlot slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.childCount,
           "Cannot balance out-of-bounds slot.")
    assert(!self.isLeaf, "Cannot balance leaf.")
    
    // No need to balance if the node is already balanced
    if self[childAt: slot].read({ $0.isBalanced }) { return }
    
    if slot > 0 && self[childAt: slot - 1].read({ $0.isShrinkable }) {
      // We can rotate from the left node to the right node
      self.rotateRight(atSlot: slot - 1)
    } else if slot < self.childCount - 1 &&
                self[childAt: slot + 1].read({ $0.isShrinkable }) {
      // We can rotate from the right node to the left node
      self.rotateLeft(atSlot: slot)
    } else if slot == self.childCount - 1 {
      // In the special case the deficient child at the end,
      // it'll be merged with it's left sibling.
      self.collapse(atSlot: slot - 1)
    } else {
      // Otherwise collapse the child with its right sibling.
      self.collapse(atSlot: slot)
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
  internal func rotateRight(atSlot slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.elementCount,
           "Cannot rotate out-of-bounds slot.")
    
    self[childAt: slot].update { leftChild in
      assert(leftChild.elementCount > 0, "Cannot rotate from empty node.")
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightChild in
        assert(rightChild.elementCount < rightChild.capacity,
               "Rotating into full node.")
        assert(leftChild.isLeaf == rightChild.isLeaf,
               "Encountered subtrees of conflicting depth.")
        
        // Shift the rest of the elements right
        rightChild.moveInitializeElements(
          count: rightChild.elementCount,
          fromSlot: 0,
          toSlot: 1, of: rightChild
        )
        
        // Extract the parent's current element and move it down to the right
        // node
        let oldParentElement = self.moveElement(atSlot: slot)
        if !rightChild.isLeaf {
          // Move the corresponding children to the right
          rightChild.moveInitializeChildren(
            count: rightChild.childCount,
            fromSlot: 0,
            toSlot: 1, of: rightChild
          )
          
          // We'll extract the last child of the left node, if it exists,
          // in order to cycle it.
          // removeChild(atSlot:) takes care of adjusting the total element
          // counts.
          let newLeftChild: _Node =
            leftChild.removeChild(atSlot: leftChild.childCount - 1)
          
          // Move the left child if applicable to the right node.
          rightChild.initializeElement(
            atSlot: 0, to: oldParentElement, withLeftChild: newLeftChild
          )
          
          rightChild.subtreeCount += newLeftChild.read({ $0.subtreeCount })
        } else {
          // Move the left child if applicable to the right node.
          rightChild.initializeElement(atSlot: 0, to: oldParentElement)
        }
        
        // Move the left node's key up to the parent
        // removeElement(atSlot:) takes care of adjusting the node counts.
        let newParentElement =
          leftChild.removeElement(atSlot: leftChild.elementCount - 1)
        self.initializeElement(atSlot: slot, to: newParentElement)
        
        // Adjust the element counts as applicable
        rightChild.elementCount += 1
        rightChild.subtreeCount += 1
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
  internal func rotateLeft(atSlot slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.elementCount,
           "Cannot rotate out-of-bounds slot.")
    
    self[childAt: slot].update { leftChild in
      assert(leftChild.elementCount < leftChild.capacity,
             "Rotating into full node.")
      
      // Move the old parent down to the right node
      self[childAt: slot + 1].update { rightChild in
        assert(rightChild.elementCount > 0, "Cannot rotate from empty node.")
        assert(leftChild.isLeaf == rightChild.isLeaf,
               "Encountered subtrees of conflicting depth.")
        
        // Move the right child if applicable to the left node.
        // We'll extract the first child of the right node, if it exists,
        // in order to cycle it.
        // Then, cycle the parent's element down to the left child
        let oldParentElement = self.moveElement(atSlot: slot)
        if !leftChild.isLeaf {
          // removeChild(atSlot:) takes care of adjusting the node counts.
          let newRightChild = rightChild.removeChild(atSlot: 0)
          
          leftChild.initializeElement(
            atSlot: leftChild.elementCount,
            to: oldParentElement,
            withRightChild: newRightChild
          )
          
          // Adjust the total element counts
          leftChild.subtreeCount += newRightChild.read({ $0.subtreeCount })
        } else {
          leftChild.initializeElement(
            atSlot: leftChild.elementCount, to: oldParentElement
          )
        }
        
        // Cycle the right child's element up to the parent.
        // removeElement(atSlot:) takes care of adjusting the node counts.
        let newParentElement = rightChild.removeElement(atSlot: 0)
        self.initializeElement(atSlot: slot, to: newParentElement)
        
        leftChild.elementCount += 1
        leftChild.subtreeCount += 1
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
  internal func collapse(atSlot slot: Int) {
    assertMutable()
    assert(0 <= slot && slot < self.elementCount,
           "Cannot collapse out-of-bounds slot")
    assert(!self.isLeaf, "Cannot collapse a slot of a leaf node.")
    
    self[childAt: slot].update { leftChild in
      var rightChild = self.moveChild(atSlot: slot + 1)
      
      // TODO: create optimized version that avoids a CoW copy for when the
      // right child is shared.
      rightChild.update { rightChild in
        // Ensure the left handle is large enough to contain all the items
        assert(
          leftChild.capacity >=
            leftChild.elementCount + rightChild.elementCount + 1,
          "Left child undersized to contain collapsed subtree."
        )
        assert(leftChild.isLeaf == rightChild.isLeaf,
               "Encountered subtrees of conflicting depth.")
        
        // Move the remaining children
        //   ┌─┬─┬─┬─┐
        //   │1│X│5│7│
        //   └─┴─┴┬┴─┘
        //      ▲ │
        //      └─┘
        self.moveInitializeChildren(
          count: self.elementCount - slot - 1,
          fromSlot: slot + 2,
          toSlot: slot + 1, of: self
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
        // The removeElement(atSlot:) takes care of adjusting the element
        // count on the parent.
        leftChild.initializeElement(
          atSlot: leftChild.elementCount,
          to: self.removeElement(atSlot: slot)
        )
        
        // Increment the total element count since we merely moved the
        // parent element within the same subtree
        self.subtreeCount += 1
        
        // TODO: might be more optimal to memcpy the right child, and avoid
        // potentially creating a CoW copy of it. 
        
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
        rightChild.moveInitializeElements(
          count: rightChild.elementCount,
          fromSlot: 0,
          toSlot: leftChild.elementCount + 1, of: leftChild
        )
        
        // Move the children of the right node to the left node
        if !rightChild.isLeaf {
          rightChild.moveInitializeChildren(
            count: rightChild.childCount,
            fromSlot: 0,
            toSlot: leftChild.elementCount + 1, of: leftChild
          )
        }
        
        // Adjust the child counts
        leftChild.elementCount += rightChild.elementCount + 1
        leftChild.subtreeCount += rightChild.subtreeCount + 1
        
        // Clear out the child counts for the right handle
        // TODO: As part of deletion, we probably already visited the right
        // node, so it's possible we just created a CoW copy of it, only do
        // deallocate it. Not a big deal but an inefficiency to note.
        rightChild.elementCount = 0
        rightChild.drop()
      }
    }
  }
}
