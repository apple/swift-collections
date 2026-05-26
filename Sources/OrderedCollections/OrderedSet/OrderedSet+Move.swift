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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

// Reordering implementation.
//
// Both `move` overloads relocate elements to a new offset, preserving the
// order they appear in the input. The work splits into two concerns:
//
//   1. Rearrange `_elements` so the moved values are contiguous at the
//      destination, with the surrounding elements compacted around them.
//   2. Update `_table` so each element's hash bucket points at its new
//      offset.
//
// The implementation dispatches to one of three buffer strategies depending
// on the input shape:
//
//   * Contiguous range source -> `_moveRange`: a three-reverse rotation of
//     `_elements`. O(*d* + *k*) element moves, where *d* is the distance
//     between source and destination and *k* is the source count.
//
//   * Contiguous range source in a different order -> `_moveContiguousReordered`:
//     rotation, followed by a cycle-following in-place permutation to
//     reorder the moved block.
//
//   * Scattered sources -> `_moveScattered`: a two-pointer compact-and-place
//     pass that removes the source positions and writes the moved values
//     into the resulting gap. O(*n*) element moves.
//
// For the hash table, each strategy further chooses between targeted
// per-element bucket updates and a coarse fallback (full-table scan in
// `_moveRange`, full rebuild in `_moveScattered`). The fallback is faster
// once the affected region grows beyond roughly a third of the table; see
// the `targetedUpdateLimit` comments at each branch.

extension OrderedSet {
  /// Moves the elements in the given range to the given offset, preserving
  /// their relative order.
  ///
  ///     var set: OrderedSet = [0, 1, 2, 3, 4, 5, 6]
  ///     set.move(4 ..< 6, toOffset: 1)
  ///     // set is now [0, 4, 5, 1, 2, 3, 6]
  ///
  /// - Parameters:
  ///    - range: The index range of elements to move.
  ///    - destination: The offset where the moved elements should start in
  ///       the resulting set. Must be in the range `0 ... count - range.count`.
  ///
  /// - Complexity: O(*d* + *k*) where *d* is the distance between the source
  ///    and destination, and *k* is the number of elements moved. Falls back
  ///    to O(`count`) for large moves.
  @inlinable
  public mutating func move(
    _ range: Range<Int>,
    toOffset destination: Int
  ) {
    let c = range.count
    guard c > 0 else { return }
    _failEarlyRangeCheck(range, bounds: startIndex ..< endIndex)
    precondition(
      destination >= 0 && destination <= count - c,
      "Destination offset \(destination) out of range 0 ... \(count - c)")
    guard range.lowerBound != destination else { return }
    _moveRange(range.lowerBound, count: c, toOffset: destination)
    _checkInvariants()
  }

  @inlinable
  internal mutating func _moveRange(
    _ src: Int,
    count: Int,
    toOffset destination: Int
  ) {
    _elements.withUnsafeMutableBufferPointer { buffer in
      buffer._moveSubrange(src ..< src + count, toOffset: destination)
    }

    guard _table != nil else { return }

    _ensureUnique()

    let distance: Int = destination < src ? src - destination : destination - src

    _table!.update { hashTable in
      // Targeted bucket updates touch O(count + distance) buckets, while a
      // full scan touches all of `hashTable.capacity`. With a 3/4 load
      // factor, scanning becomes cheaper once the affected region grows
      // beyond roughly a third of the table.
      let targetedUpdateLimit = hashTable.capacity / 3

      if count <= targetedUpdateLimit && distance <= targetedUpdateLimit {
        if destination < src {
          for newPos in destination ..< destination + count {
            var it = hashTable.bucketIterator(for: _elements[newPos])
            it.advance(until: newPos + distance)
            it.currentValue = newPos
          }
          for newPos in destination + count ..< src + count {
            var it = hashTable.bucketIterator(for: _elements[newPos])
            it.advance(until: newPos - count)
            it.currentValue = newPos
          }
        } else {
          for newPos in src ..< destination {
            var it = hashTable.bucketIterator(for: _elements[newPos])
            it.advance(until: newPos + count)
            it.currentValue = newPos
          }
          for newPos in destination ..< destination + count {
            var it = hashTable.bucketIterator(for: _elements[newPos])
            it.advance(until: newPos - distance)
            it.currentValue = newPos
          }
        }
      } else {
        var it = hashTable.bucketIterator(
          startingAt: _Bucket(offset: 0))
        repeat {
          if let value = it.currentValue {
            if value >= src && value < src + count {
              it.currentValue = destination < src
                ? value - distance : value + distance
            } else if destination < src
                        && value >= destination && value < src {
              it.currentValue = value + count
            } else if destination > src
                        && value >= src + count && value < destination + count {
              it.currentValue = value - count
            }
          }
          it.advance()
        } while it.currentBucket.offset != 0
      }
    }
  }
}

extension OrderedSet {
  /// Moves the specified elements to the given offset, keeping them in the
  /// order they appear in `elements`.
  ///
  /// Every value in `elements` must be a member of the set, and `elements`
  /// must not contain duplicates.
  ///
  ///     var set: OrderedSet = [0, 1, 2, 3, 4, 5, 6]
  ///     set.move([4, 1], toOffset: 2)
  ///     // set is now [0, 2, 4, 1, 3, 5, 6]
  ///
  /// - Parameters:
  ///    - elements: The elements to move.
  ///    - destination: The offset where the moved elements should start in
  ///       the resulting set. Must be in the range `0 ... count - k`, where
  ///       `k` is the number of elements being moved.
  ///
  /// - Complexity: O(`count`) in the worst case. When the elements form a
  ///    contiguous range or are moved a short distance, the operation is
  ///    proportional to the distance moved.
  @inlinable
  public mutating func move(
    _ elements: some Sequence<Element>,
    toOffset destination: Int
  ) {
    let toMove = ContiguousArray(elements)
    let c = toMove.count
    guard c > 0 else { return }
    precondition(
      destination >= 0 && destination <= count - c,
      "Destination offset \(destination) out of range 0 ... \(count - c)")

    withUnsafeTemporaryAllocation(of: Int.self, capacity: c) { sourceOffsets in
      var isContiguousRange = true
      var isSorted = true
      for i in 0 ..< c {
        guard let index = _find(toMove[i]).index else {
          preconditionFailure(
            "Attempted to move an element that is not a member of the set")
        }
        if i > 0 {
          let prev = sourceOffsets[i - 1]
          if index <= prev {
            isSorted = false
            isContiguousRange = false
          } else if index != prev + 1 {
            isContiguousRange = false
          }
        }
        sourceOffsets[i] = index
      }

      var isNoOp = true
      for i in 0 ..< c {
        if sourceOffsets[i] != destination + i {
          isNoOp = false
          break
        }
      }
      guard !isNoOp else { return }

      if isContiguousRange {
        _moveRange(sourceOffsets[0], count: c, toOffset: destination)
        _checkInvariants()
        return
      }

      _moveScattered(
        sourceOffsets: sourceOffsets,
        isSorted: isSorted,
        count: c,
        toOffset: destination)
    }
  }

  @inlinable
  internal mutating func _moveScattered(
    sourceOffsets: UnsafeMutableBufferPointer<Int>,
    isSorted: Bool,
    count: Int,
    toOffset destination: Int
  ) {
    let totalCount = self.count

    withUnsafeTemporaryAllocation(of: Int.self, capacity: count) { sortedCopy in
      if !isSorted {
        for i in 0 ..< count { sortedCopy[i] = sourceOffsets[i] }
        var mutableSortedCopy = sortedCopy
        mutableSortedCopy.sort()
      }
      let sortedSources = isSorted ? sourceOffsets : sortedCopy

      if !isSorted {
        for i in 1 ..< count {
          precondition(
            sortedSources[i] != sortedSources[i - 1],
            "Duplicate element in move list")
        }
      }

      // Contiguous indices in a different order: rotate, then permute.
      if sortedSources[count - 1] - sortedSources[0] == count - 1 {
        _moveContiguousReordered(
          sourceOffsets: sourceOffsets,
          minSource: sortedSources[0],
          count: count,
          toOffset: destination)
        return
      }

      withUnsafeTemporaryAllocation(
        of: Element.self, capacity: count
      ) { saved in
        for i in 0 ..< count {
          saved.initializeElement(at: i, to: _elements[sourceOffsets[i]])
        }
        defer { saved.baseAddress!.deinitialize(count: count) }

        _elements.withUnsafeMutableBufferPointer { buffer in
          buffer._compactAndPlace(
            removing: sortedSources,
            inserting: saved,
            at: destination,
            totalCount: totalCount)
        }
      }

      guard _table != nil else {
        _checkInvariants()
        return
      }

      _ensureUnique()

      let minSource: Int = sortedSources[0]
      let maxSource: Int = sortedSources[count - 1]
      let affectedStart: Int = Swift.min(minSource, destination)
      let affectedEnd: Int = Swift.max(maxSource, destination + count - 1)
      let affectedCount: Int = affectedEnd - affectedStart + 1

      // Same heuristic as in `_moveRange`: when the affected region is small
      // relative to the table, per-bucket updates beat a full-table rebuild.
      let targetedUpdateLimit = _capacity / 3

      if affectedCount <= targetedUpdateLimit {
        _table!.update { hashTable in
          for i in 0 ..< count {
            let oldPos = sourceOffsets[i]
            let newPos = destination + i
            if oldPos != newPos {
              var it = hashTable.bucketIterator(for: _elements[newPos])
              it.advance(until: oldPos)
              it.currentValue = newPos
            }
          }

          if affectedStart < destination {
            var oldPos = affectedStart
              + sortedSources._sortedCount(below: affectedStart)
            var si = oldPos - affectedStart
            for newPos in affectedStart ..< destination {
              // Mirrors the catch-up loop after the gap; see there.
              while si < count && sortedSources[si] <= oldPos {
                oldPos += 1
                si += 1
              }
              if oldPos != newPos {
                var it = hashTable.bucketIterator(for: _elements[newPos])
                it.advance(until: oldPos)
                it.currentValue = newPos
              }
              oldPos += 1
            }
          }

          if destination + count <= affectedEnd {
            let firstNSIndex = destination
            var oldPos = firstNSIndex
              + sortedSources._sortedCount(below: firstNSIndex)
            var si = oldPos - firstNSIndex
            for newPos in (destination + count) ... affectedEnd {
              // `<=` (not `==`): the initial `oldPos` counts sources
              // strictly below `firstNSIndex`, so any source in
              // `[firstNSIndex, oldPos]` still needs folding in here.
              while si < count && sortedSources[si] <= oldPos {
                oldPos += 1
                si += 1
              }
              if oldPos != newPos {
                var it = hashTable.bucketIterator(for: _elements[newPos])
                it.advance(until: oldPos)
                it.currentValue = newPos
              }
              oldPos += 1
            }
          }
        }
      } else {
        _table!.update { hashTable in
          hashTable.clear()
          hashTable.fill(uncheckedUniqueElements: _elements)
        }
      }

      _checkInvariants()
    }
  }

  @inlinable
  internal mutating func _moveContiguousReordered(
    sourceOffsets: UnsafeMutableBufferPointer<Int>,
    minSource: Int,
    count: Int,
    toOffset destination: Int
  ) {
    _moveRange(minSource, count: count, toOffset: destination)

    withUnsafeTemporaryAllocation(of: Int.self, capacity: count) { perm in
      for i in 0 ..< count {
        perm[i] = sourceOffsets[i] - minSource
      }

      _elements.withUnsafeMutableBufferPointer { buffer in
        buffer._applyPermutation(perm, offset: destination)
      }
    }

    if _table != nil {
      _ensureUnique()
      _table!.update { hashTable in
        for i in 0 ..< count {
          let oldLocalPos = sourceOffsets[i] - minSource
          guard oldLocalPos != i else { continue }
          var it = hashTable.bucketIterator(
            for: _elements[destination + i])
          it.advance(until: destination + oldLocalPos)
          it.currentValue = destination + i
        }
      }
    }

    _checkInvariants()
  }
}

extension UnsafeMutableBufferPointer {
  /// Moves a contiguous subrange to a new position using three-reverse
  /// rotation.
  @inlinable
  internal func _moveSubrange(
    _ source: Range<Int>,
    toOffset destination: Int
  ) {
    let src = source.lowerBound
    let count = source.count
    if destination < src {
      _reverse(destination ..< src)
      _reverse(src ..< src + count)
      _reverse(destination ..< src + count)
    } else {
      _reverse(src ..< src + count)
      _reverse(src + count ..< destination + count)
      _reverse(src ..< destination + count)
    }
  }

  /// Reverses elements in the given index range.
  @inlinable
  internal func _reverse(_ range: Range<Int>) {
    var lo = range.lowerBound
    var hi = range.upperBound - 1
    while lo < hi {
      swapAt(lo, hi)
      lo += 1
      hi -= 1
    }
  }

  /// Removes elements at the positions in `sortedRemovals` (which must be
  /// sorted and within bounds), compacts the remaining elements to leave a
  /// gap at `destination`, and fills the gap from `insertions`.
  ///
  /// `totalCount` is the number of initialized elements in the buffer.
  @inlinable
  internal func _compactAndPlace(
    removing sortedRemovals: UnsafeMutableBufferPointer<Int>,
    inserting insertions: UnsafeMutableBufferPointer<Element>,
    at destination: Int,
    totalCount: Int
  ) {
    let removalCount = sortedRemovals.count

    // Forward pass: compact non-removed elements into 0..<destination.
    var writeLeft = 0
    var readLeft = 0
    var si = 0
    while writeLeft < destination {
      if si < removalCount && sortedRemovals[si] == readLeft {
        si += 1
        readLeft += 1
      } else {
        if writeLeft != readLeft {
          self[writeLeft] = self[readLeft]
        }
        writeLeft += 1
        readLeft += 1
      }
    }

    // Backward pass: compact non-removed elements into
    // (destination + removalCount) ..< totalCount.
    var writeRight = totalCount - 1
    var readRight = totalCount - 1
    var sj = removalCount - 1
    while writeRight >= destination + removalCount {
      if sj >= 0 && sortedRemovals[sj] == readRight {
        sj -= 1
        readRight -= 1
      } else {
        if writeRight != readRight {
          self[writeRight] = self[readRight]
        }
        writeRight -= 1
        readRight -= 1
      }
    }

    // Place inserted elements in the gap.
    for i in 0 ..< removalCount {
      self[destination + i] = insertions[i]
    }
  }

  /// Applies a permutation to elements at `offset ..< offset + perm.count`.
  /// After this call, the element that was at `offset + perm[i]` will be at
  /// `offset + i`. The `perm` buffer is consumed (its contents are
  /// undefined on return).
  @inlinable
  internal func _applyPermutation(
    _ perm: UnsafeMutableBufferPointer<Int>,
    offset: Int
  ) {
    for start in 0 ..< perm.count {
      guard perm[start] != start else { continue }
      var j = start
      let temp = self[offset + j]
      while perm[j] != start {
        let from = perm[j]
        self[offset + j] = self[offset + from]
        perm[j] = j
        j = from
      }
      self[offset + j] = temp
      perm[j] = j
    }
  }
}

extension UnsafeMutableBufferPointer where Element == Int {
  /// Returns the number of elements strictly less than `value` in this
  /// sorted buffer (i.e., the lower bound index).
  @inlinable
  internal func _sortedCount(below value: Int) -> Int {
    var lo = 0
    var hi = count
    while lo < hi {
      let mid = lo + (hi - lo) / 2
      if self[mid] < value {
        lo = mid + 1
      } else {
        hi = mid
      }
    }
    return lo
  }
}
