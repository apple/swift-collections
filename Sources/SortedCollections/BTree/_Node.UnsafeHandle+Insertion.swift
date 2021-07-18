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

// MARK: Tree Insertions
extension _Node.UnsafeHandle {
  @usableFromInline
  @frozen
  internal enum InsertionResult {
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
  // updateAnyValue(_ value:, forKey key:, updatingKey:)
  internal func setAnyValue(_ value: Value, forKey key: Key, updatingKey: Bool) -> InsertionResult {
    assertMutable()
    
    let insertionIndex = self.endSlot(forKey: key)

    if 0 < insertionIndex && insertionIndex <= self.elementCount &&
        self[keyAt: insertionIndex - 1] == key {
      if updatingKey {
        // TODO: concerned about copy here
        let oldKey = self.keys.advanced(by: insertionIndex - 1).pointee
        
        let oldValue = self.values.advanced(by: insertionIndex - 1).move()
        self.values.advanced(by: insertionIndex - 1).initialize(to: value)
        
        return .updated(previousElement: (oldKey, oldValue))
      } else {
        let oldElement = self.exchangeElement(atSlot: insertionIndex - 1, with: (key, value))
        return .updated(previousElement: oldElement)
      }
    }

    // We need to try to insert as deep as possible as first, and have the splinter
    // bubble up.
    if self.isLeaf {
      let maybeSplinter = self.insertElement(
        (key, value),
        withRightChild: nil,
        atSlot: insertionIndex
      )
      return InsertionResult(from: maybeSplinter)
    } else {
      let result = self[childAt: insertionIndex].update { $0.setAnyValue(value, forKey: key, updatingKey: updatingKey) }

      switch result {
      case .updated:
        return result
      case .splintered(let splinter):
        let maybeSplinter = self.insertSplinter(splinter, atSlot: insertionIndex)
        return InsertionResult(from: maybeSplinter)
      case .inserted:
        self.subtreeCount += 1
        return .inserted
      }
    }
  }
}

// MARK: Immediate Node Insertions
extension _Node.UnsafeHandle {
  /// Inserts a value into this node without considering the children. Be careful when using
  /// this as you can violate the BTree invariants if not careful.
  /// - Parameters:
  ///   - element: The new key-value pair to insert in the node.
  ///   - rightChild: The new element's corresponding right-child provided iff the
  ///       node is not a leaf, otherwise `nil`.
  ///   - insertionSlot: The slot to insert the new element.
  /// - Returns: A splinter object if node splintered during the insert, otherwise `nil`
  /// - Warning: Ensure you insert the node in a valid order as to not break the node's
  ///     sorted invariant.
  @inlinable
  internal func insertElement(
    _ element: _Node.Element,
    withRightChild rightChild: _Node?,
    atSlot insertionSlot: Int
  ) -> _Node.Splinter? {
    assertMutable()
    assert(self.isLeaf == (rightChild == nil),
           "A child can only be inserted iff the node is a leaf.")
    
    // If we have a full B-Tree, we'll need to splinter
    if self.elementCount == self.capacity {
      // Right median == left median for BTrees with odd capacity
      let rightMedian = self.elementCount / 2
      let leftMedian = (self.elementCount - 1) / 2
      
      var splinterElement: _Node.Element
      var rightNode = _Node(withCapacity: self.capacity, isLeaf: self.isLeaf)
      
      if insertionSlot == rightMedian {
        splinterElement = element
        
        let leftElementCount = rightMedian
        let rightElementCount = self.elementCount - rightMedian
        
        rightNode.update { rightHandle in
          self.moveInitializeElements(
            count: rightElementCount,
            fromSlot: rightMedian,
            toSlot: 0, of: rightHandle
          )
          
          if !self.isLeaf {
            rightHandle.children.unsafelyUnwrapped
              .initialize(to: rightChild.unsafelyUnwrapped)
            
            self.moveInitializeChildren(
              count: rightElementCount,
              fromSlot: rightMedian + 1,
              toSlot: 1, of: rightHandle
            )
          }
          
          self.elementCount = leftElementCount
          rightHandle.elementCount = rightElementCount
          
          self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      } else if insertionSlot > rightMedian {
        // This branch is almost certainly correct
        splinterElement = self.moveElement(atSlot: rightMedian)
        
        rightNode.update { rightHandle in
          let insertionSlotInRightNode = insertionSlot - (rightMedian + 1)
          
          self.moveInitializeElements(
            count: insertionSlotInRightNode,
            fromSlot: rightMedian + 1,
            toSlot: 0, of: rightHandle
          )
          
          self.moveInitializeElements(
            count: self.elementCount - insertionSlot,
            fromSlot: insertionSlot,
            toSlot: insertionSlotInRightNode + 1, of: rightHandle
          )
          
          if !self.isLeaf {
            self.moveInitializeChildren(
              count: insertionSlot - rightMedian,
              fromSlot: rightMedian + 1,
              toSlot: 0, of: rightHandle
            )
            
            self.moveInitializeChildren(
              count: self.elementCount - insertionSlot,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlotInRightNode + 2, of: rightHandle
            )
          }
          
          rightHandle.initializeElement(
            atSlot: insertionSlotInRightNode,
            to: element,
            withRightChild: rightChild
          )
          
          rightHandle.elementCount = self.elementCount - rightMedian
          self.elementCount = rightMedian
          
          self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      } else {
        // insertionSlot < rightMedian
        splinterElement = self.moveElement(atSlot: leftMedian)
        
        rightNode.update { rightHandle in
          self.moveInitializeElements(
            count: self.elementCount - leftMedian - 1,
            fromSlot: leftMedian + 1,
            toSlot: 0, of : rightHandle
          )
          
          self.moveInitializeElements(
            count: leftMedian - insertionSlot,
            fromSlot: insertionSlot,
            toSlot: insertionSlot + 1, of: self
          )
          
          if !self.isLeaf {
            self.moveInitializeChildren(
              count: self.elementCount - leftMedian,
              fromSlot: leftMedian + 1,
              toSlot: 0, of: rightHandle
            )
            
            self.moveInitializeChildren(
              count: leftMedian - insertionSlot,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlot + 2, of: self
            )
          }
          
          self.initializeElement(
            atSlot: insertionSlot,
            to: element, withRightChild: rightChild
          )
          
          rightHandle.elementCount = self.elementCount - leftMedian - 1
          self.elementCount = leftMedian + 1
          
          self._adjustSubtreeCount(afterSplittingTo: rightHandle)
        }
      }
      
      return _Node.Splinter(
        element: splinterElement,
        rightChild: rightNode
      )
    } else {
      // TODO: see if this can be simplified
      // Shift over elements near the insertion slot.
      self.moveInitializeElements(
        count: self.elementCount - insertionSlot,
        fromSlot: insertionSlot,
        toSlot: insertionSlot + 1, of: self
      )
      
      if !self.isLeaf {
        self.moveInitializeChildren(
          count: self.childCount - insertionSlot - 1,
          fromSlot: insertionSlot + 1,
          toSlot: insertionSlot + 2, of: self
        )
      }
      
      self.initializeElement(
        atSlot: insertionSlot,
        to: element, withRightChild: rightChild
      )
      
      self.elementCount += 1
      self.subtreeCount += 1
      
      return nil
    }
  }
  
  /// Inserts a splinter, attaching the children appropriately
  /// - Parameters:
  ///   - splinter: The splinter object from a child
  ///   - insertionSlot: The slot of the child which produced the splinter
  /// - Returns: Another splinter which may need to be propagated upward
  @inlinable
  @inline(__always)
  internal func insertSplinter(
    _ splinter: _Node.Splinter,
    atSlot insertionSlot: Int
  ) -> _Node.Splinter? {
    return self.insertElement(
      splinter.element,
      withRightChild: splinter.rightChild,
      atSlot: insertionSlot
    )
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
  internal func _adjustSubtreeCount(
    afterSplittingTo rightHandle: _Node.UnsafeHandle
  ) {
    assertMutable()
    rightHandle.assertMutable()
    
    let originalTotalElements = self.subtreeCount
    var totalChildElements = 0
    
    if !self.isLeaf {
      // Calculate total amount of child elements
      // TODO: potentially evaluate min(left.children, right.children),
      // but the cost of the branch will likely exceed the cost of 1 comparison
      for i in 0..<self.childCount {
        totalChildElements += self[childAt: i].storage.header.totalElements
      }
    }
    
    assert(totalChildElements >= 0,
           "Cannot have negative number of child elements.")
    
    self.subtreeCount = self.elementCount + totalChildElements
    rightHandle.subtreeCount = originalTotalElements - self.subtreeCount
  }
}
