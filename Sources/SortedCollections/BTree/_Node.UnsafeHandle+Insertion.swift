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

// MARK: Tree Insertions
extension _Node.UnsafeHandle {
  @usableFromInline
  @frozen
  package enum UpdateResult {
    case updated(previousElement: _Node.Element)
    case splintered(_Node.Splinter)
    case inserted

    @inlinable
    @inline(__always)
    internal init(from splinter: _Node.Splinter?) {
      if let splinter = splinter {
        self = .splintered(splinter)
      } else {
        self = .inserted
      }
    }
  }

  /// Insert or update an element in the tree. Starts at the current node, returning a
  /// possible splinter, or the previous value for any matching key if updating a node.
  ///
  /// In the case of duplicates, this is marginally more efficient, however, this may update
  /// any element with a key equal to the provided one in the tree. For this reason, refrain
  /// from using this unless the tree is guaranteed to have unique keys, else it may have
  /// inconsistent behavior.
  ///
  /// If a matching key is found, only the value will be updated.
  ///
  /// - Parameters:
  ///   - value: The value to insert or update.
  ///   - key: The key to equate.
  ///   - updatingKey: If the key is found, whether it should be updated.
  /// - Returns: A representation of the possible results of the update/insertion.
  @inlinable
  @inline(__always)
  package func updateAnyValue(
    _ value: Value,
    forKey key: Key,
    updatingKey: Bool
  ) -> UpdateResult {
    assertMutable()
    
    let insertionIndex = unsafe self.endSlot(forKey: key)

    if unsafe 0 < insertionIndex && insertionIndex <= self.elementCount &&
        self[keyAt: insertionIndex - 1] == key {
      if updatingKey {
        // TODO: Potential transient ARC traffic here.
        let oldKey = unsafe self.keys.advanced(by: insertionIndex - 1).pointee

        let oldValue: Value
        if _Node.hasValues {
          oldValue = unsafe self.pointerToValue(atSlot: insertionIndex - 1).move()
          unsafe self.pointerToValue(atSlot: insertionIndex - 1).initialize(to: value)
        } else {
          oldValue = _Node.dummyValue
        }
        
        return .updated(previousElement: (oldKey, oldValue))
      } else {
        let oldElement = unsafe self.exchangeElement(
          atSlot: insertionIndex - 1,
          with: (key, value)
        )
        
        return .updated(previousElement: oldElement)
      }
    }

    // We need to try to insert as deep as possible as first, and have the splinter
    // bubble up.
    if self.isLeaf {
      let maybeSplinter = unsafe self.insertElement(
        (key, value),
        withRightChild: nil,
        atSlot: insertionIndex
      )
      return UpdateResult(from: maybeSplinter)
    } else {
      let result = unsafe self[childAt: insertionIndex].update {
        unsafe $0.updateAnyValue(value, forKey: key, updatingKey: updatingKey)
      }

      switch result {
      case .updated:
        return result
      case .splintered(let splinter):
        let splinter = unsafe self.insertSplinter(splinter, atSlot: insertionIndex)
        return UpdateResult(from: splinter)
      case .inserted:
        unsafe self.subtreeCount += 1
        return .inserted
      }
    }
  }
}

// MARK: Immediate Node Insertions
extension _Node.UnsafeHandle {
  /// Inserts a value into this node without considering the children. Be careful when using
  /// this as you can violate the BTree invariants if not careful.
  /// 
  /// - Parameters:
  ///   - element: The new key-value pair to insert in the node.
  ///   - rightChild: The new element's corresponding right-child provided iff the
  ///       node is not a leaf, otherwise `nil`.
  ///   - insertionSlot: The slot to insert the new element.
  /// - Returns: A splinter object if node splintered during the insert, otherwise `nil`
  /// - Warning: Ensure you insert the node in a valid order as to not break the node's
  ///     sorted invariant.
  @inlinable
  package func insertElement(
    _ element: _Node.Element,
    withRightChild rightChild: _Node?,
    atSlot insertionSlot: Int
  ) -> _Node.Splinter? {
    assertMutable()
    assert(self.isLeaf == (rightChild == nil),
           "A child can only be inserted iff the node is a leaf")
    
    // If we have a full B-Tree, we'll need to splinter
    if unsafe self.elementCount == self.capacity {
      // Right median == left median for BTrees with odd capacity
      let rightMedian = unsafe self.elementCount / 2
      let leftMedian = unsafe (self.elementCount - 1) / 2

      var splinterElement: _Node.Element
      var rightNode = _Node(withCapacity: unsafe self.capacity, isLeaf: self.isLeaf)

      if insertionSlot == rightMedian {
        splinterElement = element
        
        let leftElementCount = rightMedian
        let rightElementCount = unsafe self.elementCount - rightMedian
        
        unsafe rightNode.update { rightHandle in
          unsafe self.moveInitializeElements(
            count: rightElementCount,
            fromSlot: rightMedian,
            toSlot: 0, of: rightHandle)
          
          if !self.isLeaf {
            unsafe rightHandle.children.unsafelyUnwrapped
              .initialize(to: rightChild.unsafelyUnwrapped)
            
            unsafe self.moveInitializeChildren(
              count: rightElementCount,
              fromSlot: rightMedian + 1,
              toSlot: 1, of: rightHandle)
          }
          
          unsafe self.elementCount = leftElementCount
          unsafe rightHandle.elementCount = rightElementCount
          unsafe rightHandle.depth = self.depth

          unsafe self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      } else if insertionSlot > rightMedian {
        // This branch is almost certainly correct
        splinterElement = unsafe self.moveElement(atSlot: rightMedian)

        let insertionSlotInRightNode = insertionSlot - (rightMedian + 1)
        
        unsafe rightNode.update { rightHandle in
          unsafe self.moveInitializeElements(
            count: insertionSlotInRightNode,
            fromSlot: rightMedian + 1,
            toSlot: 0, of: rightHandle)
          
          unsafe self.moveInitializeElements(
            count: self.elementCount - insertionSlot,
            fromSlot: insertionSlot,
            toSlot: insertionSlotInRightNode + 1, of: rightHandle)
          
          if !self.isLeaf {
            unsafe self.moveInitializeChildren(
              count: insertionSlot - rightMedian,
              fromSlot: rightMedian + 1,
              toSlot: 0, of: rightHandle)
            
            unsafe self.moveInitializeChildren(
              count: self.elementCount - insertionSlot,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlotInRightNode + 2, of: rightHandle)
          }
          
          unsafe rightHandle.initializeElement(
            atSlot: insertionSlotInRightNode,
            to: element,
            withRightChild: rightChild)
          
          unsafe rightHandle.elementCount = self.elementCount - rightMedian
          unsafe self.elementCount = rightMedian
          unsafe rightHandle.depth = self.depth

          unsafe self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      } else {
        // insertionSlot < rightMedian
        splinterElement = unsafe self.moveElement(atSlot: leftMedian)

        unsafe rightNode.update { rightHandle in
          unsafe self.moveInitializeElements(
            count: self.elementCount - leftMedian - 1,
            fromSlot: leftMedian + 1,
            toSlot: 0, of : rightHandle)
          
          unsafe self.moveInitializeElements(
            count: leftMedian - insertionSlot,
            fromSlot: insertionSlot,
            toSlot: insertionSlot + 1, of: self)
          
          if !self.isLeaf {
            unsafe self.moveInitializeChildren(
              count: self.elementCount - leftMedian,
              fromSlot: leftMedian + 1,
              toSlot: 0, of: rightHandle)
            
            unsafe self.moveInitializeChildren(
              count: leftMedian - insertionSlot,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlot + 2, of: self)
          }
          
          unsafe self.initializeElement(
            atSlot: insertionSlot,
            to: element, withRightChild: rightChild)
          
          unsafe rightHandle.elementCount = self.elementCount - leftMedian - 1
          unsafe self.elementCount = leftMedian + 1
          unsafe rightHandle.depth = self.depth

          unsafe self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      }
      
      return _Node.Splinter(
        element: splinterElement,
        rightChild: rightNode)
    } else {
      // TODO: potentially extract out this logic to reduce code duplication.
      // Shift over elements near the insertion slot.
      unsafe self.moveInitializeElements(
        count: self.elementCount - insertionSlot,
        fromSlot: insertionSlot,
        toSlot: insertionSlot + 1, of: self)
      
      if !self.isLeaf {
        unsafe self.moveInitializeChildren(
          count: self.childCount - insertionSlot - 1,
          fromSlot: insertionSlot + 1,
          toSlot: insertionSlot + 2, of: self)
      }
      
      unsafe self.initializeElement(
        atSlot: insertionSlot,
        to: element, withRightChild: rightChild)
      
      unsafe self.elementCount += 1
      unsafe self.subtreeCount += 1

      return nil
    }
  }
  
  /// Inserts a splinter, attaching the children appropriately.
  ///
  /// This only updates the count properties by one (for the separator). If the splinter's right child contains a
  /// different amount of elements than previously existed in the tree, explicitly handle those count changes.
  /// See ``_Node.UnsafeHandle._adjustSubtreeCount(afterSplittingTo:)`` to
  /// potentially ease this task.
  ///
  /// - Parameters:
  ///   - splinter: The splinter object from a child
  ///   - insertionSlot: The slot of the child which produced the splinter
  /// - Returns: Another splinter which may need to be propagated upward
  @inlinable
  @inline(__always)
  package func insertSplinter(
    _ splinter: _Node.Splinter,
    atSlot insertionSlot: Int
  ) -> _Node.Splinter? {
    return unsafe self.insertElement(
      splinter.element,
      withRightChild: splinter.rightChild,
      atSlot: insertionSlot)
  }
  
  /// Recomputes the total amount of elements in two nodes.
  ///
  /// This updates the subtree counts for both the current handle and also the provided `rightHandle`.
  ///
  /// Use this to recompute the tracked total element counts for the current node when it
  /// splits. This performs a shallow recalculation, assuming that its children's counts are
  /// already accurate.
  ///
  /// - Parameter rightHandle: A handle to the right-half of the split.
  @inlinable
  @inline(__always)
  package func _adjustSubtreeCount(
    afterSplittingTo rightHandle: _Node.UnsafeHandle
  ) {
    assertMutable()
    rightHandle.assertMutable()
    
    let originalTotalElements = unsafe self.subtreeCount + rightHandle.subtreeCount
    var totalChildElements = 0
    
    if !self.isLeaf {
      // Calculate total amount of child elements
      // TODO: potentially evaluate min(left.children, right.children),
      // but the cost of the branch will likely exceed the cost of 1 comparison
      for i in unsafe 0 ..< self.childCount {
        unsafe totalChildElements += self[childAt: i].storage.header.subtreeCount
      }
    }
    
    assert(totalChildElements >= 0,
           "Cannot have negative number of child elements")
    
    unsafe self.subtreeCount = self.elementCount + totalChildElements
    unsafe rightHandle.subtreeCount = originalTotalElements - self.subtreeCount
  }
  
  /// Concatenates a node of the same depth to end of the current node, potentially splintering.
  ///
  /// This only supports a single-level of splinter, therefore
  /// `node.elementCount + self.elementCount + 1` must not exceed
  /// `2 * self.capacity`.
  ///
  /// Additionally, this **consumes** the source node which will marked to be deallocated.
  ///
  /// - Parameters:
  ///   - rightNode: A consumed node with keys greater than or equal to the separator.
  ///   - separatedBy: A separator greater than or equal to all keys in the current node.
  /// - Returns: A splinter if the node could not contain both elements.
  @inlinable
  package func concatenateWith(
    node rightNode: inout _Node,
    separatedBy separator: __owned _Node.Element
  ) -> _Node.Splinter? {
    assertMutable()
    let separator: _Node.Element? = unsafe rightNode.update { rightHandle in
      assert(unsafe self.elementCount + rightHandle.elementCount <= 2 * self.capacity,
             "Parameters are too large to concatenate")
      assert(unsafe self.depth == rightHandle.depth,
             "Cannot concatenate nodes of varying depths. See appendNode(_:separatedBy:)")
      
      let totalElementCount = unsafe self.elementCount + rightHandle.elementCount + 1

      // Identify if a splinter needs to occur
      if unsafe totalElementCount > self.capacity {
        // A splinter needs to occur
        
        // Split evenly (right biased).
        let separatorSlot = totalElementCount / 2
        
        // Identify who needs to splinter
        if unsafe separatorSlot == self.elementCount {
          // The nice case when the separator is the splinter
          return separator
        } else if unsafe separatorSlot < self.elementCount {
          // Move elements from the left node to the right node
          let splinterSeparator = unsafe self.moveElement(atSlot: separatorSlot)

          let shiftedElementCount = unsafe self.elementCount - separatorSlot - 1

          unsafe rightHandle.moveInitializeElements(
            count: rightHandle.elementCount,
            fromSlot: 0,
            toSlot: shiftedElementCount + 1,
            of: rightHandle)
          
          unsafe rightHandle.initializeElement(
            atSlot: shiftedElementCount,
            to: separator)
          
          unsafe self.moveInitializeElements(
            count: shiftedElementCount,
            fromSlot: separatorSlot + 1,
            toSlot: 0,
            of: rightHandle)
          
          if !self.isLeaf {
            unsafe rightHandle.moveInitializeChildren(
              count: rightHandle.childCount,
              fromSlot: 0,
              toSlot: shiftedElementCount + 1,
              of: rightHandle)
            
            unsafe self.moveInitializeChildren(
              count: shiftedElementCount + 1,
              fromSlot: separatorSlot + 1,
              toSlot: 0,
              of: rightHandle)
          }
          
          // TODO: adjust counts
          unsafe self.elementCount = separatorSlot
          unsafe rightHandle.elementCount = totalElementCount - separatorSlot - 1

          unsafe self._adjustSubtreeCount(afterSplittingTo: rightHandle)

          return splinterSeparator
        } else {
          // separatorSlot > self.elementCount
          // Move elements from the right node to the left node
          let separatorSlotInRightHandle = unsafe separatorSlot - self.elementCount - 1
          let splinterSeparator =
            unsafe rightHandle.moveElement(atSlot: separatorSlotInRightHandle)

          unsafe self.initializeElement(
            atSlot: self.elementCount,
            to: separator)
          
          unsafe rightHandle.moveInitializeElements(
            count: separatorSlotInRightHandle,
            fromSlot: 0,
            toSlot: self.elementCount + 1,
            of: self)
          
          unsafe rightHandle.moveInitializeElements(
            count: rightHandle.elementCount - (separatorSlotInRightHandle + 1),
            fromSlot: separatorSlotInRightHandle + 1,
            toSlot: 0,
            of: rightHandle)
          
          if !self.isLeaf {
            unsafe rightHandle.moveInitializeChildren(
              count: separatorSlotInRightHandle + 1,
              fromSlot: 0,
              toSlot: self.childCount,
              of: self)
          }
          
          unsafe self.elementCount = separatorSlot
          unsafe rightHandle.elementCount = totalElementCount - separatorSlot - 1

          unsafe self._adjustSubtreeCount(afterSplittingTo: rightHandle)

          return splinterSeparator
        }
      } else {
        // A simple merge can be performed
        unsafe self.initializeElement(
          atSlot: self.elementCount,
          to: separator)

        unsafe rightHandle.moveInitializeElements(
          count: rightHandle.elementCount,
          fromSlot: 0,
          toSlot: self.elementCount + 1,
          of: self)
        
        if !self.isLeaf {
          unsafe rightHandle.moveInitializeChildren(
            count: rightHandle.childCount,
            fromSlot: 0,
            toSlot: self.childCount,
            of: self)
        }
        
        unsafe self.elementCount += rightHandle.elementCount + 1
        unsafe self.subtreeCount += rightHandle.subtreeCount + 1

        unsafe rightHandle.elementCount = 0
        unsafe rightHandle.drop()

        return nil
      }
    }
    
    // Check if it splintered
    if let separator = separator {
      return _Node.Splinter(element: separator, rightChild: rightNode)
    } else {
      return nil
    }
  }
}

#endif
