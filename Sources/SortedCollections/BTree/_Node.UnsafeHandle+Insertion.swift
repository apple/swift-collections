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
  internal enum InsertionResult {
    case updated(previousValue: Value)
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

  /// Inserts an element in the tree, starting at the current node, returning a possible
  /// splinter, or the previous value for any matching key if updating a node.
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
  /// - Returns: A representation of the possible results of the update/insertion.
  @inlinable
  @inline(__always)
  internal func setAnyValue(_ value: Value, forKey key: Key) -> InsertionResult {
    let insertionIndex = self.lastSlot(for: key)

    if 0 < insertionIndex && insertionIndex <= self.numElements &&
        self[keyAt: insertionIndex - 1] == key {
      // TODO: potential copy of `value`. See if there is a way to prevent this.
      let oldValue = self.values.advanced(by: insertionIndex - 1).move()
      self.values.advanced(by: insertionIndex - 1).initialize(to: value)
      return .updated(previousValue: oldValue)
    }

    // We need to try to insert as deep as possible as first, and have the splinter
    // bubble up.
    if self.isLeaf {
      let maybeSplinter = self.immediatelyInsert(
        element: (key, value),
        withRightChild: nil,
        at: insertionIndex
      )
      return InsertionResult(from: maybeSplinter)
    } else {
      let result = self[childAt: insertionIndex].update { $0.setAnyValue(value, forKey: key) }

      switch result {
      case .updated:
        return result
      case .splintered(let splinter):
        let maybeSplinter = self.immediatelyInsert(splinter: splinter, at: insertionIndex)
        return InsertionResult(from: maybeSplinter)
      case .inserted:
        self.numTotalElements += 1
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
  internal func immediatelyInsert(
    element: _Node.Element,
    withRightChild rightChild: _Node?,
    at insertionSlot: Int
  ) -> _Node.Splinter? {
    assertMutable()
    assert(self.isLeaf == (rightChild == nil), "A child can only be inserted iff the node is a leaf.")
    
    // If we have a full B-Tree, we'll need to splinter
    if self.numElements == self.capacity {
      // Right median == left median for BTrees with odd capacity
      let rightMedian = self.numElements / 2
      let leftMedian = (self.numElements - 1) / 2
      
      var splinterElement: _Node.Element
      var rightNode = _Node(withCapacity: self.capacity, isLeaf: self.isLeaf)
      
      if insertionSlot == rightMedian {
        splinterElement = element
        
        let numLeftElements = rightMedian
        let numRightElements = self.numElements - rightMedian
        
        rightNode.update { handle in
          self.moveElements(toHandle: handle, fromSlot: rightMedian, toSlot: 0, count: numRightElements)
          
          // TODO: also possible to do !self.isLeaf and force unwrap right child to
          // help the compiler avoid this branch.
          if !self.isLeaf {
            handle.children.unsafelyUnwrapped.initialize(to: rightChild.unsafelyUnwrapped)
            self.moveChildren(toHandle: handle, fromSlot: rightMedian + 1, toSlot: 1, count: numRightElements)
          }
          
          self.numElements = numLeftElements
          handle.numElements = numRightElements
          
          self.recomputeTotalElementCount(withRightSplit: handle)
        }
      } else if insertionSlot > rightMedian {
        // This branch is almost certainly correct
        splinterElement = self.moveElement(at: rightMedian)
        
        rightNode.update { handle in
          let insertionSlotInRightNode = insertionSlot - (rightMedian + 1)
          
          self.moveElements(
            toHandle: handle,
            fromSlot: rightMedian + 1,
            toSlot: 0,
            count: insertionSlotInRightNode
          )
          
          self.moveElements(
            toHandle: handle,
            fromSlot: insertionSlot,
            toSlot: insertionSlotInRightNode + 1,
            count: self.numElements - insertionSlot
          )
          
          if !self.isLeaf {
            self.moveChildren(
              toHandle: handle,
              fromSlot: rightMedian + 1,
              toSlot: 0,
              count: insertionSlot - rightMedian
            )
            
            self.moveChildren(
              toHandle: handle,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlotInRightNode + 2,
              count: self.numElements - insertionSlot
            )
          }
          
          handle.setElement(element, withRightChild: rightChild, at: insertionSlotInRightNode)
          
          handle.numElements = self.numElements - rightMedian
          self.numElements = rightMedian
          
          self.recomputeTotalElementCount(withRightSplit: handle)
        }
      } else {
        // insertionSlot < rightMedian
        splinterElement = self.moveElement(at: leftMedian)
        
        rightNode.update { handle in
          self.moveElements(
            toHandle: handle,
            fromSlot: leftMedian + 1,
            toSlot: 0,
            count: self.numElements - leftMedian - 1
          )
          
          self.moveElements(
            toHandle: self,
            fromSlot: insertionSlot,
            toSlot: insertionSlot + 1,
            count: leftMedian - insertionSlot
          )
          
          if !self.isLeaf {
            self.moveChildren(
              toHandle: handle,
              fromSlot: leftMedian + 1,
              toSlot: 0,
              count: self.numElements - leftMedian
            )
            
            self.moveChildren(
              toHandle: self,
              fromSlot: insertionSlot + 1,
              toSlot: insertionSlot + 2,
              count: leftMedian - insertionSlot
            )
          }
          
          self.setElement(element, withRightChild: rightChild, at: insertionSlot)
          
          handle.numElements = self.numElements - leftMedian - 1
          self.numElements = leftMedian + 1
          
          self.recomputeTotalElementCount(withRightSplit: handle)
        }
      }
      
      return _Node.Splinter(
        median: splinterElement,
        rightChild: rightNode
      )
    } else {
      // Shift over elements near the insertion slot.
      let numElemsToShift = self.numElements - insertionSlot
      self.moveElements(
        toHandle: self,
        fromSlot: insertionSlot,
        toSlot: insertionSlot + 1,
        count: numElemsToShift
      )
      
      if !self.isLeaf {
        let numChildrenToShift = self.numChildren - insertionSlot - 1
        self.moveChildren(
          toHandle: self,
          fromSlot: insertionSlot + 1,
          toSlot: insertionSlot + 2,
          count: numChildrenToShift
        )
      }
      
      self.setElement(element, withRightChild: rightChild, at: insertionSlot)
      self.numElements += 1
      self.numTotalElements += 1
      
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
  internal func immediatelyInsert(splinter: _Node.Splinter, at insertionSlot: Int) -> _Node.Splinter? {
    return self.immediatelyInsert(element: splinter.median, withRightChild: splinter.rightChild, at: insertionSlot)
  }
}
