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
  
  // TODO: look into O(1) implementation
  /// Locates the first element and returns a proper path to it, or nil if the BTree is empty.
  /// - Complexity: O(`log n`)
  @inlinable
  internal var startIndex: Index {
    if count == 0 { return Index(nil, forTree: self) }
    var depth: UInt8 = 0
    var currentNode = self.root
    while !currentNode.read({ $0.isLeaf }) {
      // TODO: figure out how to avoid the swift retain here
      currentNode = currentNode.read({ $0[childAt: 0] })
      depth += 1
    }
    
    let path = UnsafePath(
      node: currentNode,
      slot: 0,
      childSlots: FixedSizeArray(repeating: 0, depth: depth),
      offset: 0
    )
    
    return Index(path, forTree: self)
  }
  
  /// Returns a sentinel value for the last element
  /// - Complexity: O(1)
  @inlinable
  internal var endIndex: Index { Index(nil, forTree: self) }
  
  /// Gets the effective offset of an index
  /// - Warning: this does not
  @inlinable
  @inline(__always)
  internal func offset(of index: Index) -> Int {
    return index.path?.offset ?? self.count
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
    return self.offset(of: end) - self.offset(of: start)
  }
  
  /// Replaces the given index with its successor.
  /// - Parameter index: A valid index of the collection. i must be less than endIndex.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func formIndex(after index: inout Index) {
    guard var path = index.path else {
      preconditionFailure("Attempt to advance out of collection bounds.")
    }
    
    let shouldSeekWithinLeaf = path.readNode {
      $0.isLeaf && _fastPath(path.slot + 1 < $0.elementCount)
    }
    
    if shouldSeekWithinLeaf {
      // Continue searching within the same leaf
      path.slot += 1
      path.offset += 1
      index.path = path
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
    assert(!self.isEmpty && self.offset(of: index) != 0, "Attempt to advance out of collection bounds.")
    // TODO: implement more efficient logic to better move through the tree
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
    let newIndex = self.offset(of: i) + distance
    assert(0 <= newIndex && newIndex <= self.count, "Attempt to advance out of collection bounds.")
    
    if newIndex == self.count {
      i.path = nil
      return
    }
    
    // TODO: optimization for searching within children
    
    if var path = i.path, path.readNode({ $0.isLeaf }) {
      // Check if the target element will be in the same node
      let targetSlot = path.slot + distance
      if 0 <= targetSlot && targetSlot < path.readNode({ $0.elementCount }) {
        path.slot = targetSlot
        path.offset = newIndex
        i.path = path
        return
      }
    }
    
    // Otherwise, re-seek
    i = Index(self.path(atOffset: newIndex), forTree: self)
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
  
  /// Offsets the given index by the specified distance, or so that it equals the given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a limit that is
  ///       less than `i` has no effect. Likewise, if `distance < 0`, a limit that is greater than `i`
  ///       has no effect.
  /// - Returns: `true` if `i` has been offset by exactly `distance` steps without going beyond
  ///     `limit`; otherwise, `false`. When the return value is `false`, the value of `i` is equal
  ///     to `limit`.
  /// - Complexity: O(`log n`) in the worst-case.
  @inlinable
  internal func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Index) -> Bool {
    let distanceToLimit = self.distance(from: i, to: limit)
    if distance < 0 ? distanceToLimit > distance : distanceToLimit < distance {
      self.formIndex(&i, offsetBy: distanceToLimit)
      return false
    } else {
      self.formIndex(&i, offsetBy: distance)
      return true
    }
  }
  
  /// Returns an index that is the specified distance from the given index, unless that distance
  /// is beyond a given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a `limit`
  ///       that is less than `i` has no effect. Likewise, if `distance < 0`, a `limit` that is
  ///       greater twhan `i` has no effect.
  /// - Returns: An index offset by `distance` from the index `i`, unless that index would
  ///     be beyond `limit` in the direction of movement. In that case, the method returns `nil`.
  @inlinable
  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    let distanceToLimit = self.distance(from: i, to: limit)
    if distance < 0 ? distanceToLimit > distance : distanceToLimit < distance {
      return nil
    } else {
      var newIndex = i
      self.formIndex(&newIndex, offsetBy: distance)
      return newIndex
    }
  }
  
  @inlinable
  @inline(__always)
  internal subscript(index: Index) -> Element {
    assert(index.path != nil, "Attempt to subscript out of range index.")
    return index.path.unsafelyUnwrapped.element
  }
}

// MARK: Custom Indexing Operations
extension _BTree {
  /// Returns a path to the key at absolute offset `i`.
  /// - Parameter offset: 0-indexed offset within BTree bounds, else may panic.
  /// - Returns: the index of the appropriate element.
  /// - Complexity: O(`log n`)
  

  /// Obtains the start index for a key (or where it would exist).
  @inlinable
  internal func startIndex(forKey key: Key) -> Index {
    var childSlots = UnsafePath.Offsets(repeating: 0)
    var targetSlot: Int = 0
    var offset = 0
    
    func search(in node: Node) -> Unmanaged<Node.Storage>? {
      node.read({ handle in
        let slot = handle.startSlot(forKey: key)
        if slot < handle.elementCount {
          if handle.isLeaf {
            offset += slot
            targetSlot = slot
            return .passUnretained(node.storage)
          } else {
            // Calculate offset by summing previous subtrees
            for i in 0...slot {
              offset += handle[childAt: i].read({ $0.subtreeCount })
            }
            
            let currentOffset = offset
            let currentDepth = childSlots.depth
            childSlots.append(UInt16(slot))
            
            if let foundEarlier = search(in: handle[childAt: slot]) {
              return foundEarlier
            } else {
              childSlots.depth = currentDepth
              targetSlot = slot
              offset = currentOffset
              
              return .passUnretained(node.storage)
            }
          }
        } else {
          // Start index exceeds node and is therefore not in this.
          return nil
        }
      })
    }
    
    if let targetChild = search(in: self.root) {
      return Index(UnsafePath(
        node: targetChild,
        slot: targetSlot,
        childSlots: childSlots,
        offset: offset
      ), forTree: self)
    } else {
      return Index(nil, forTree: self)
    }
  }
  
  /// Obtains the last index at which a value less than or equal to the key appears.
  @inlinable
  internal func lastIndex(forKey key: Key) -> Index {
    var childSlots = UnsafePath.Offsets(repeating: 0)
    var targetSlot: Int = 0
    var offset = 0
    
    func search(in node: Node) -> Unmanaged<Node.Storage>? {
      node.read({ handle in
        let slot = handle.endSlot(forKey: key) - 1
        if slot > 0 {
          // Sanity Check
          assert(slot < handle.elementCount, "Slot out of bounds.")
          
          if handle.isLeaf {
            offset += slot
            targetSlot = slot
            return .passUnretained(node.storage)
          } else {
            for i in 0...slot {
              offset += handle[childAt: i].read({ $0.subtreeCount })
            }
            
            let currentOffset = offset
            let currentDepth = childSlots.depth
            childSlots.append(UInt16(slot + 1))
            
            if let foundLater = search(in: handle[childAt: slot + 1]) {
              return foundLater
            } else {
              childSlots.depth = currentDepth
              targetSlot = slot
              offset = currentOffset
              
              return .passUnretained(node.storage)
            }
          }
        } else {
          // Start index exceeds node and is therefore not in this.
          return nil
        }
      })
    }
    
    if let targetChild = search(in: self.root) {
      return Index(UnsafePath(
        node: targetChild,
        slot: targetSlot,
        childSlots: childSlots,
        offset: offset
      ), forTree: self)
    } else {
      return Index(nil, forTree: self)
    }
  }
  
}
