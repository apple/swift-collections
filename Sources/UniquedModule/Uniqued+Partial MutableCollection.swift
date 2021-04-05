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

// The parts of MutableCollection that Uniqued is able to implement.

extension Uniqued where Base: MutableCollection {
  public mutating func swapAt(_ i: Index, _ j: Index) {
    guard i != j else { return }
    _elements.swapAt(i, j)
    guard _storage != nil else { return }
    _ensureUnique()
    _storage!.update { hashTable in
      let iOffset = _elements._offset(of: i)
      let jOffset = _elements._offset(of: j)
      hashTable.swapBucketValues(for: _elements[i], withCurrentValue: jOffset,
                                 and: _elements[j], withCurrentValue: iOffset)
    }
    _checkInvariants()
  }

  public mutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index {
    try _partition(by: belongsInSecondPartition, callback: { a, b in })
  }
}

extension Uniqued where Base: MutableCollection {
  public mutating func _partition(
    by belongsInSecondPartition: (Element) throws -> Bool,
    callback: (Int, Int) -> Void
  ) rethrows -> Index {
    guard _storage != nil else {
      return try _elements.partition(by: belongsInSecondPartition)
    }
    _ensureUnique()
    let result: Index = try _storage!.update { hashTable in
      let maybeOffset: Int? = try _elements.withContiguousMutableStorageIfAvailable { buffer in
        let pivot = try buffer._partition(
          with: hashTable,
          by: belongsInSecondPartition,
          callback: callback)
        return pivot - buffer.startIndex
      }
      if let offset = maybeOffset {
        return _elements.index(startIndex, offsetBy: offset)
      }
      return try _elements._partition(
        with: hashTable,
        by: belongsInSecondPartition,
        callback: callback)
    }
    _checkInvariants()
    return result
  }
}

extension MutableCollection where Self: RandomAccessCollection, Element: Hashable {
  internal mutating func _partition(
    with hashTable: _UnsafeHashTable,
    by belongsInSecondPartition: (Element) throws -> Bool,
    callback: (Int, Int) -> Void
  ) rethrows -> Index {
    var low = startIndex
    var high = endIndex

    while true {
      // Invariants at this point:
      // - low <= high
      // - all elements in `startIndex ..< low` belong in the first partition
      // - all elements in `high ..< endIndex` belong in the second partition

      // Find next element from `lo` that may not be in the right place.
      while true {
        if low == high { return low }
        if try belongsInSecondPartition(self[low]) { break }
        formIndex(after: &low)
      }

      // Find next element down from `hi` that we can swap `lo` with.
      while true {
        formIndex(before: &high)
        if low == high { return low }
        if try !belongsInSecondPartition(self[high]) { break }
      }

      // Swap the two elements as well as their associated hash table buckets.
      swapAt(low, high)
      hashTable.swapBucketValues(for: self[low], withCurrentValue: _offset(of: high),
                                 and: self[high], withCurrentValue: _offset(of: low))
      callback(_offset(of: low), _offset(of: high))

      formIndex(after: &low)
    }
  }
}

extension _UnsafeHashTable {
  func swapBucketValues<Element: Hashable>(
    for left: Element, withCurrentValue leftValue: Int,
    and right: Element, withCurrentValue rightValue: Int
  ) {
    var it = bucketIterator(for: left)
    it.advance(until: leftValue)
    assert(it.isOccupied)
    it.currentValue = rightValue

    it = bucketIterator(for: right)
    it.advance(until: rightValue)
    assert(it.isOccupied)
    // Note: this second update may mistake the bucket for `right` with the
    // bucket for `left` whose value we just updated. The second update will
    // restore the original hash table contents in this case. This is okay!
    // When this happens, the lookup chains for both elements include each
    // other, so leaving the hash table unchanged still leaves us with a
    // working hash table.
    it.currentValue = leftValue
  }
}

extension Uniqued where Base: MutableCollection {
  public mutating func sort(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows {
    defer {
      // Note: This assumes that `sort(by:)` won't leave duplicate/missing
      // elements in the table when the closure throws. This matches the
      // stdlib's behavior in Swift 5.3, and it seems like a reasonable
      // long-term assumption.
      _regenerateExistingHashTable()
      _checkInvariants()
    }
    try _elements.sort(by: areInIncreasingOrder)
  }
}

extension Uniqued where Base: MutableCollection, Element: Comparable {
  public mutating func sort() {
    sort(by: <)
  }
}

extension Uniqued where Base: MutableCollection {
  public mutating func shuffle() {
    var generator = SystemRandomNumberGenerator()
    shuffle(using: &generator)
  }

  public mutating func shuffle<T: RandomNumberGenerator>(
    using generator: inout T
  ) {
    _elements.shuffle(using: &generator)
    _regenerateHashTable()
    _checkInvariants()
  }
}

extension Uniqued {
  @_spi(UnsafeInternals)
  public mutating func _partition<Key, Value>(
    values: UnsafeMutableBufferPointer<Value>,
    by belongsInSecondPartition: ((key: Key, value: Value)) throws -> Bool
  ) rethrows -> Int
  where Base == ContiguousArray<Key> {
    let storage = _uniqueStorage()
    return try _elements.withUnsafeMutableBufferPointer { keys in
      assert(keys.count == values.count)
      var low = keys.startIndex
      var high = keys.endIndex

      while true {
        // Invariants at this point:
        // - low <= high
        // - all elements in `startIndex ..< low` belong in the first partition
        // - all elements in `high ..< endIndex` belong in the second partition

        // Find next element from `lo` that may not be in the right place.
        while true {
          if low == high { return low }
          if try belongsInSecondPartition((keys[low], values[low])) { break }
          low += 1
        }

        // Find next element down from `hi` that we can swap `lo` with.
        while true {
          high -= 1
          if low == high { return low }
          if try !belongsInSecondPartition((keys[high], values[high])) { break }
        }

        // Swap the two elements as well as their associated hash table buckets.
        keys.swapAt(low, high)
        values.swapAt(low, high)
        storage?.update { hashTable in
          hashTable.swapBucketValues(for: keys[low], withCurrentValue: high,
                                     and: keys[high], withCurrentValue: low)
        }
        low += 1
      }
    }
  }
}
