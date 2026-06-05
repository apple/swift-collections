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
// A move rearranges `_elements` so the moved elements become consecutive at
// the destination, then repoints the affected hash-table buckets. The element
// rearrangement is factored into generic `UnsafeMutableBufferPointer`
// operations; `OrderedDictionary` reuses them through the `applyingTo` closure
// to relocate its values in lockstep with the keys.

extension OrderedSet {
  /// Moves the elements in the given range to the given index, preserving
  /// their relative order.
  ///
  ///     var set: OrderedSet = [0, 1, 2, 3, 4, 5, 6]
  ///     set.moveSubrange(4 ..< 6, to: 1)
  ///     // set is now [0, 4, 5, 1, 2, 3, 6]
  ///
  /// - Parameters:
  ///    - range: The range of indices addressing the elements to move.
  ///    - destination: The index at which the moved elements should start in
  ///       the resulting set. Must be in the range `0 ... count - range.count`.
  ///
  /// - Complexity: O(*d* + *k*) where *d* is the distance between the source
  ///    and destination, and *k* is the number of elements moved. Falls back
  ///    to O(`count`) for large moves.
  #if compiler(>=6.3)
  @inline(always)
  #else
  @inline(__always)
  #endif
  @inlinable
  public mutating func moveSubrange(
    _ range: some RangeExpression<Index>,
    to destination: Index
  ) {
    _moveSubrange(range.relative(to: self), to: destination)
  }

  @inlinable
  internal mutating func _moveSubrange(
    _ range: Range<Index>,
    to destination: Index
  ) {
    let c = range.count
    guard c > 0 else { return }
    _failEarlyRangeCheck(range, bounds: startIndex ..< endIndex)
    precondition(
      destination >= 0 && destination <= count - c,
      "Destination index \(destination) out of range 0 ... \(count - c)")
    guard range.lowerBound != destination else { return }
    _elements.withUnsafeMutableBufferPointer { buffer in
      buffer._moveSubrange(
        range.lowerBound ..< range.lowerBound + c, toOffset: destination)
    }
    _updateHashAfterContiguousMove(
      src: range.lowerBound, count: c, to: destination)
    _checkInvariants()
  }

  /// Moves the given elements to the given index, keeping them in the
  /// order they appear in `members`.
  ///
  /// Elements that are not members of the set are ignored; only the members
  /// are relocated. `members` must not contain duplicate elements.
  ///
  ///     var set: OrderedSet = [0, 1, 2, 3, 4, 5, 6]
  ///     set.move(members: [4, 1], to: 2)
  ///     // set is now [0, 2, 4, 1, 3, 5, 6]
  ///
  /// - Parameters:
  ///    - members: The elements to move. Values that are not members of the
  ///       set are ignored.
  ///    - destination: The index at which the moved elements should start in
  ///       the resulting set. Must be in the range `0 ... count - k`, where
  ///       `k` is the number of `members` that are present in the set.
  ///
  /// - Complexity: O(`count`) in the worst case. When the elements form a
  ///    contiguous range or are moved a short distance, the operation is
  ///    proportional to the distance moved.
  @inlinable
  public mutating func move(
    members elements: some Sequence<Element>,
    to destination: Index
  ) {
    _move(members: elements, to: destination)
  }

  /// Moves the elements at the given indices to the given index, keeping them
  /// in the order the indices appear in `indices`.
  ///
  /// `indices` must contain distinct, valid indices of the set.
  ///
  ///     var set: OrderedSet = [0, 1, 2, 3, 4]
  ///     set.move(indices: [4, 1], to: 0)
  ///     // set is now [4, 1, 0, 2, 3]
  ///
  /// - Parameters:
  ///    - indices: The indices of the elements to move.
  ///    - destination: The index at which the moved elements should start in
  ///       the resulting set. Must be in the range `0 ... count - k`, where
  ///       `k` is the number of elements being moved.
  ///
  /// - Complexity: O(`count`) in the worst case. When the elements form a
  ///    contiguous range or are moved a short distance, the operation is
  ///    proportional to the distance moved.
  @inlinable
  public mutating func move(
    indices: some Sequence<Index>,
    to destination: Index
  ) {
    _move(indices: indices, to: destination)
  }
}

extension OrderedSet {
  @inlinable
  internal mutating func _move(
    indices: some Sequence<Index>,
    to destination: Index,
    applyingTo body: (
      UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, Bool
    ) -> Void = { _, _, _ in }
  ) {
    // Fast path: operate directly on the sequence's storage when available.
    let handled: Void? = indices.withContiguousStorageIfAvailable { buffer in
      _move(fromIndices: buffer, to: destination, applyingTo: body)
    }
    if handled != nil { return }

    // Fallback: collect the indices into an array, checking bounds and
    // detecting order as we go.
    var isContiguousRange = true
    var isSorted = true
    var prev = -1
    var sourceOffsets: [Int] = []
    sourceOffsets.reserveCapacity(indices.underestimatedCount)
    for index in indices {
      precondition(
        index >= 0 && index < count,
        "Index \(index) at \(sourceOffsets.count) out of bounds 0 ..< \(count)")
      if prev >= 0 {
        if index <= prev {
          isSorted = false
          isContiguousRange = false
        } else if index != prev + 1 {
          isContiguousRange = false
        }
      }
      prev = index
      sourceOffsets.append(index)
    }
    sourceOffsets.withUnsafeBufferPointer { sourceOffsets in
      _move(
        sourceOffsets: sourceOffsets,
        isContiguousRange: isContiguousRange,
        isSorted: isSorted,
        to: destination,
        applyingTo: body)
    }
  }

  @inlinable
  internal mutating func _move(
    fromIndices sourceOffsets: UnsafeBufferPointer<Int>,
    to destination: Index,
    applyingTo body: (
      UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, Bool
    ) -> Void = { _, _, _ in }
  ) {
    var isContiguousRange = true
    var isSorted = true
    for i in 0 ..< sourceOffsets.count {
      let index = sourceOffsets[i]
      precondition(
        index >= 0 && index < count,
        "Index \(index) at \(i) out of bounds 0 ..< \(count)")
      if i > 0 {
        let prev = sourceOffsets[i - 1]
        if index <= prev {
          isSorted = false
          isContiguousRange = false
        } else if index != prev + 1 {
          isContiguousRange = false
        }
      }
    }
    _move(
      sourceOffsets: sourceOffsets,
      isContiguousRange: isContiguousRange,
      isSorted: isSorted,
      to: destination,
      applyingTo: body)
  }

  @inlinable
  internal mutating func _move(
    members elements: some Sequence<Element>,
    to destination: Index,
    applyingTo body: (
      UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, Bool
    ) -> Void = { _, _, _ in }
  ) {
    // Fast path: resolve member indices into a stack buffer, no heap copy.
    // Elements that aren't members of the set are skipped.
    let handled: Void? = elements.withContiguousStorageIfAvailable { source in
      guard source.count > 0 else { return }
      withUnsafeTemporaryAllocation(
        of: Int.self, capacity: source.count
      ) { sourceOffsets in
        var isContiguousRange = true
        var isSorted = true
        var c = 0
        for i in 0 ..< source.count {
          guard let index = _find(source[i]).index else { continue }
          if c > 0 {
            let prev = sourceOffsets[c - 1]
            if index <= prev {
              isSorted = false
              isContiguousRange = false
            } else if index != prev + 1 {
              isContiguousRange = false
            }
          }
          sourceOffsets[c] = index
          c += 1
        }
        _move(
          sourceOffsets: UnsafeBufferPointer(rebasing: sourceOffsets[..<c]),
          isContiguousRange: isContiguousRange,
          isSorted: isSorted,
          to: destination,
          applyingTo: body)
      }
    }
    if handled != nil { return }

    // Fallback: resolve member indices into an array, skipping non-members.
    var isContiguousRange = true
    var isSorted = true
    var prev = -1
    var sourceOffsets: [Int] = []
    sourceOffsets.reserveCapacity(elements.underestimatedCount)
    for element in elements {
      guard let index = _find(element).index else { continue }
      if prev >= 0 {
        if index <= prev {
          isSorted = false
          isContiguousRange = false
        } else if index != prev + 1 {
          isContiguousRange = false
        }
      }
      prev = index
      sourceOffsets.append(index)
    }
    sourceOffsets.withUnsafeBufferPointer { sourceOffsets in
      _move(
        sourceOffsets: sourceOffsets,
        isContiguousRange: isContiguousRange,
        isSorted: isSorted,
        to: destination,
        applyingTo: body)
    }
  }

  @inlinable
  internal mutating func _move(
    sourceOffsets: UnsafeBufferPointer<Int>,
    isContiguousRange: Bool,
    isSorted: Bool,
    to destination: Index,
    applyingTo body: (
      UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, Bool
    ) -> Void
  ) {
    let c = sourceOffsets.count
    guard c > 0 else { return }
    precondition(
      destination >= 0 && destination <= count - c,
      "Destination index \(destination) out of range 0 ... \(count - c)")

    // A no-op is exactly an in-order contiguous run already sitting at
    // `destination`. `isContiguousRange` (computed while scanning the input)
    // already guarantees `sourceOffsets[i] == sourceOffsets[0] + i`, so it
    // only remains to check that the run starts at `destination`.
    if isContiguousRange && sourceOffsets[0] == destination { return }

    if isSorted {
      // Already ascending: the sorted view is the input view, no copy needed.
      _applyMove(
        sourceOffsets: sourceOffsets,
        sortedSources: sourceOffsets,
        isContiguousRange: isContiguousRange,
        to: destination,
        applyingTo: body)
    } else {
      withUnsafeTemporaryAllocation(of: Int.self, capacity: c) { sortedBuffer in
        sortedBuffer.baseAddress!.initialize(
          from: sourceOffsets.baseAddress!, count: c)
        var sorted = sortedBuffer
        sorted.sort()
        for i in 1 ..< c {
          precondition(
            sortedBuffer[i] != sortedBuffer[i - 1],
            "Duplicate element in move list")
        }
        _applyMove(
          sourceOffsets: sourceOffsets,
          sortedSources: UnsafeBufferPointer(sortedBuffer),
          isContiguousRange: isContiguousRange,
          to: destination,
          applyingTo: body)
      }
    }
    _checkInvariants()
  }

  @inlinable
  internal mutating func _applyMove(
    sourceOffsets: UnsafeBufferPointer<Int>,
    sortedSources: UnsafeBufferPointer<Int>,
    isContiguousRange: Bool,
    to destination: Index,
    applyingTo body: (
      UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>, Bool
    ) -> Void
  ) {
    _elements.withUnsafeMutableBufferPointer { buffer in
      buffer._move(
        sourceOffsets: sourceOffsets,
        sortedSources: sortedSources,
        isContiguousRange: isContiguousRange,
        to: destination)
    }
    _updateHashAfterMove(
      sourceOffsets: sourceOffsets,
      sortedSources: sortedSources,
      isContiguousRange: isContiguousRange,
      to: destination)
    body(sourceOffsets, sortedSources, isContiguousRange)
  }
}

extension OrderedSet {
  /// Repoints buckets after a contiguous block of `count` elements starting at
  /// `src` was rotated to start at `destination`. `_elements` is already
  /// rearranged.
  @inlinable
  internal mutating func _updateHashAfterContiguousMove(
    src: Int,
    count: Int,
    to destination: Int
  ) {
    guard _table != nil else { return }
    _ensureUnique()

    let distance: Int =
      destination < src ? src - destination : destination - src

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
        var it = hashTable.bucketIterator(startingAt: _Bucket(offset: 0))
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

  /// Repoints buckets after the elements at `sourceOffsets` were relocated to
  /// start at `destination`. `_elements` is already rearranged.
  @inlinable
  internal mutating func _updateHashAfterMove(
    sourceOffsets: UnsafeBufferPointer<Int>,
    sortedSources: UnsafeBufferPointer<Int>,
    isContiguousRange: Bool,
    to destination: Int
  ) {
    let count = sourceOffsets.count
    let minSource = sortedSources[0]

    if isContiguousRange {
      _updateHashAfterContiguousMove(
        src: minSource, count: count, to: destination)
      return
    }

    guard _table != nil else { return }

    let maxSource = sortedSources[count - 1]
    let affectedStart: Int = Swift.min(minSource, destination)
    let affectedEnd: Int = Swift.max(maxSource, destination + count - 1)
    let affectedCount: Int = affectedEnd - affectedStart + 1

    // Same heuristic as in `_updateHashAfterContiguousMove`: when the affected
    // region is small relative to the table, per-bucket updates beat a
    // full-table rebuild.
    let targetedUpdateLimit = _capacity / 3

    if affectedCount <= targetedUpdateLimit {
      _ensureUnique()
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
      // Full rebuild: build fresh storage when shared, rather than copying the
      // old table only to clear it.
      if _isUnique() {
        _table!.update { hashTable in
          hashTable.clear()
          hashTable.fill(uncheckedUniqueElements: _elements)
        }
      } else {
        _regenerateHashTable(scale: _scale, reservedScale: _reservedScale)
      }
    }
  }
}

extension UnsafeMutableBufferPointer {
  /// Relocates the elements at `sourceOffsets` (in that order) into consecutive
  /// slots starting at `destination`, dispatching to the cheapest applicable
  /// strategy. `sortedSources` lists the same offsets ascending;
  /// `isContiguousRange` is true when they form a gap-free ascending run.
  @inlinable
  internal func _move(
    sourceOffsets: UnsafeBufferPointer<Int>,
    sortedSources: UnsafeBufferPointer<Int>,
    isContiguousRange: Bool,
    to destination: Int
  ) {
    let c = sourceOffsets.count
    let minSource = sortedSources[0]

    if isContiguousRange {
      _moveSubrange(minSource ..< minSource + c, toOffset: destination)
      return
    }

    if sortedSources[c - 1] - minSource == c - 1 {
      // Contiguous indices in a different order: rotate, then permute.
      _moveSubrange(minSource ..< minSource + c, toOffset: destination)
      withUnsafeTemporaryAllocation(of: Int.self, capacity: c) { perm in
        for i in 0 ..< c {
          perm[i] = sourceOffsets[i] - minSource
        }
        _applyPermutation(perm, offset: destination)
      }
      return
    }

    _moveScattered(
      movingFrom: sourceOffsets,
      sortedSources: sortedSources,
      to: destination,
      totalCount: count)
  }

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

  /// Relocates the elements at `movingFrom` (in that order) into consecutive
  /// slots starting at `destination`, compacting the rest around them.
  /// `sortedSources` lists the same positions ascending; `totalCount` is the
  /// number of initialized elements in the buffer.
  @inlinable
  internal func _moveScattered(
    movingFrom sourceOffsets: UnsafeBufferPointer<Int>,
    sortedSources: UnsafeBufferPointer<Int>,
    to destination: Int,
    totalCount: Int
  ) {
    let count = sourceOffsets.count
    withUnsafeTemporaryAllocation(
      of: Element.self, capacity: count
    ) { saved in
      for i in 0 ..< count {
        saved.initializeElement(at: i, to: self[sourceOffsets[i]])
      }
      defer { saved.baseAddress!.deinitialize(count: count) }

      _compactAndPlace(
        removing: sortedSources,
        inserting: saved,
        at: destination,
        totalCount: totalCount)
    }
  }

  /// Removes elements at the positions in `sortedRemovals` (which must be
  /// sorted and within bounds), compacts the remaining elements to leave a
  /// gap at `destination`, and fills the gap from `insertions`.
  ///
  /// `totalCount` is the number of initialized elements in the buffer.
  @inlinable
  internal func _compactAndPlace(
    removing sortedRemovals: UnsafeBufferPointer<Int>,
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

extension UnsafeBufferPointer where Element == Int {
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
