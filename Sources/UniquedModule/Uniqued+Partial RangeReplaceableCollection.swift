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

// The parts of RangeReplaceableCollection that Uniqued is able to implement.

extension Uniqued where Base: RangeReplaceableCollection {
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    precondition(minimumCapacity >= 0, "Minimum capacity cannot be negative")
    _elements.reserveCapacity(minimumCapacity)
    let currentScale = _scale
    let newScale = _UnsafeHashTable.scale(forCapacity: minimumCapacity)
    let minScale = _UnsafeHashTable.scale(forCapacity: self.count)
    if currentScale < newScale {
      // Grow the table.
      _regenerateHashTable(scale: newScale, reservedScale: newScale)
    } else if newScale < currentScale, minScale < currentScale {
      // Shrink the table.
      _regenerateHashTable(scale: minScale, reservedScale: newScale)
    }
    if _reservedScale != newScale {
      // Remember reserved scale.
      _ensureUnique()
      _storage!.header.reservedScale = newScale
    }
    _checkInvariants()
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    _elements.removeAll(keepingCapacity: keepCapacity)
    guard keepCapacity else {
      _storage = nil
      return
    }
    _ensureUnique()
    _storage!.update { hashTable in
      hashTable.clear()
    }
  }

  public mutating func remove(at index: Index) -> Self.Element {
    _elements._failEarlyRangeCheck(index, bounds: startIndex ..< endIndex)
    let bucket = _bucket(for: index)
    return _removeExistingMember(at: index, bucket: bucket)
  }

  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _elements._failEarlyRangeCheck(bounds, bounds: _elements.startIndex ..< _elements.endIndex)
    guard _storage != nil else {
      _elements.removeSubrange(bounds)
      _checkInvariants()
      return
    }
    let startOffset = _elements._offset(of: bounds.lowerBound)
    let endOffset = _elements._offset(of: bounds.upperBound)
    let c = endOffset - startOffset
    guard c > 0 else { return }
    let remainingCount = _elements.count - c
    if remainingCount <= count / 2 || remainingCount < _minimumCapacity {
      // Just generate a new table from scratch.
      _elements.removeSubrange(bounds)
      _regenerateHashTable()
      _checkInvariants()
      return
    }

    _ensureUnique()
    _storage!.update { hashTable in
      // Delete the hash table entries for all members we're removing.
      for item in _elements[bounds] {
        let (offset, bucket) = hashTable._find(item, in: _elements)
        precondition(offset != nil, "Corrupt hash table")
        hashTable.delete(
          bucket: bucket,
          hashValueGenerator: { offset, seed in
            let index = _elements._index(at: offset)
            return _elements[index]._rawHashValue(seed: seed)
          })
      }
      hashTable.adjustContents(preparingForRemovalOf: bounds, in: _elements)
    }
    _elements.removeSubrange(bounds)
    _checkInvariants()
  }

  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty collection")
    return remove(at: self._index(at: count - 1))
  }

  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in the collection")
    removeSubrange(self._index(at: count - n) ..< self._index(at: count))
  }

  @discardableResult
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty collection")
    return remove(at: startIndex)
  }

  public mutating func removeFirst(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in the collection")
    removeSubrange(self._index(at: 0) ..< self._index(at: n))
  }
}
