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

// This contains `_BTree`'s general implementation of BidirectionalCollection.
// These operations are bounds in contrast to most other methods on _BTree as
// they are designed to be easily propagated to a higher-level data type.
// However, they still do not perform index validation

extension _BTree: BidirectionalCollection {
  /// The total number of elements contained within the BTree
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  internal var count: Int { self.root.storage.header.subtreeCount }
  
  /// A Boolean value that indicates whether the BTree is empty.
  @inlinable
  @inline(__always)
  internal var isEmpty: Bool { self.count == 0 }
  
  // TODO: further consider O(1) implementation
  /// Locates the first element and returns a proper path to it, or nil if the BTree is empty.
  /// - Complexity: O(`log n`)
  @inlinable
  internal var startIndex: Index {
    if count == 0 { return endIndex }
    var depth: Int8 = 0
    var currentNode: Unmanaged = .passUnretained(self.root.storage)
    while true {
      let shouldStop: Bool = currentNode._withUnsafeGuaranteedRef {
        $0.read { handle in
          if handle.isLeaf {
            return true
          } else {
            depth += 1
            currentNode = .passUnretained(handle[childAt: 0].storage)
            return false
          }
        }
      }
      
      if shouldStop { break }
    }
    
    return Index(
      node: currentNode,
      slot: 0,
      childSlots: _FixedSizeArray(repeating: 0, depth: depth),
      offset: 0,
      forTree: self
    )
  }
  
  /// Returns a sentinel value for the last element
  /// - Complexity: O(1)
  @inlinable
  internal var endIndex: Index {
    Index(
      node: .passUnretained(self.root.storage),
      slot: -1,
      childSlots: Index.Offsets(repeating: 0),
      offset: self.count,
      forTree: self
    )
  }
  
  /// Returns the distance between two indices.
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If end is equal to start, the result is zero.
  /// - Returns: The distance between start and end. The result can be negative only if the collection
  ///     conforms to the BidirectionalCollection protocol.
  /// - Complexity: O(1)
  @inlinable
  internal func distance(from start: Index, to end: Index) -> Int {
    return end.offset - start.offset
  }
  
  /// Replaces the given index with its successor.
  /// - Parameter index: A valid index of the collection. i must be less than endIndex.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func formIndex(after index: inout Index) {
    precondition(index.offset < self.count,
                 "Attempt to advance out of collection bounds.")
    
    // TODO: this might be redundant given the fact the same (but generalized)
    // logic is implemented in offsetBy
    let shouldSeekWithinLeaf = index.readNode {
      $0.isLeaf && _fastPath(index.slot + 1 < $0.elementCount)
    }
    
    if shouldSeekWithinLeaf {
      // Continue searching within the same leaf
      index.slot += 1
      index.offset += 1
    } else {
      self.formIndex(&index, offsetBy: 1)
    }
  }
  
  /// Returns the position immediately after the given index.
  /// - Parameter i: A valid index of the collection. i must be less than endIndex.
  /// - Returns: The index value immediately after i.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func index(after i: Index) -> Index {
    var newIndex = i
    self.formIndex(after: &newIndex)
    return newIndex
  }
  
  /// Replaces the given index with its predecessor.
  /// - Parameter index: A valid index of the collection. i must be greater than startIndex.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func formIndex(before index: inout Index) {
    precondition(!self.isEmpty && index.offset != 0,
                 "Attempt to advance out of collection bounds.")
    self.formIndex(&index, offsetBy: -1)
  }
  
  /// Returns the position immediately before the given index.
  /// - Parameter i: A valid index of the collection. i must be greater than startIndex.
  /// - Returns: The index value immediately before i.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func index(before i: Index) -> Index {
    var newIndex = i
    self.formIndex(before: &newIndex)
    return newIndex
  }
  
  /// Offsets the given index by the specified distance.
  ///
  /// The value passed as distance must not offset i beyond the bounds of the collection.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func formIndex(_ i: inout Index, offsetBy distance: Int) {
    let newIndex = i.offset + distance
    precondition(0 <= newIndex && newIndex <= self.count,
                 "Attempt to advance out of collection bounds.")
    
    if newIndex == self.count {
      i = endIndex
      return
    }
    
    // TODO: optimization for searching within children
    
    if i != endIndex && i.readNode({ $0.isLeaf }) {
      // Check if the target element will be in the same node
      let targetSlot = i.slot + distance
      if 0 <= targetSlot && targetSlot < i.readNode({ $0.elementCount }) {
        i.slot = targetSlot
        i.offset = newIndex
        return
      }
    }
    
    // Otherwise, re-seek
    i = self.index(atOffset: newIndex)
  }
  
  /// Returns an index that is the specified distance from the given index.
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///     is positive, this is the same value as the result of `distance` calls to
  ///     `index(after:)`. If `distance` is negative, this is the same value as the
  ///     result of `abs(distance)` calls to `index(before:)`.
  @inlinable
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    var newIndex = i
    self.formIndex(&newIndex, offsetBy: distance)
    return newIndex
  }
  
  @inlinable
  @inline(__always)
  internal subscript(index: Index) -> Element {
    // Ensure we don't attempt to dereference the endIndex
    precondition(index != endIndex, "Attempt to subscript out of range index.")
    return index.element
  }
  
  @inlinable
  @inline(__always)
  internal subscript(bounds: Range<Index>) -> SubSequence {
    return SubSequence(base: self, bounds: bounds)
  }
}
