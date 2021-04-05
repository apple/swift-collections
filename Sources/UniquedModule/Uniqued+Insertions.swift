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

extension Uniqued where Base: RangeReplaceableCollection {
  @_spi(UnsafeInternals)
  public mutating func _appendNew(_ item: Element) {
    assert(!contains(item))
    _elements.append(item)
    guard _elements.count <= _capacity else {
      _regenerateHashTable()
      return
    }
    guard _storage != nil else { return }
    _ensureUnique()
    _storage!.update { hashTable in
      var it = hashTable.bucketIterator(for: item)
      it.advanceToNextUnoccupiedBucket()
      it.currentValue = _elements.count - 1
    }
  }

  @_spi(UnsafeInternals)
  public mutating func _appendNew(_ item: Element, in bucket: _Bucket) {
    _elements.append(item)

    guard _elements.count < _capacity else {
      _regenerateHashTable()
      return
    }
    guard _storage != nil else { return }
    _ensureUnique()
    _storage!.update { hashTable in
      hashTable[bucket] = _elements.count - 1
    }
  }

  @_spi(UnsafeInternals)
  @discardableResult
  public mutating func _append(_ item: Element) -> (inserted: Bool, index: Base.Index) {
    let (index, bucket) = _find(item)
    if let index = index { return (false, index) }
    _appendNew(item, in: bucket)
    return (true, _elements.index(before: _elements.endIndex))
  }

  @discardableResult
  public mutating func append(_ item: Element) -> (inserted: Bool, index: Base.Index) {
    let result = _append(item)
    _checkInvariants()
    return result
  }

  public mutating func append<S: Sequence>(
    contentsOf elements: S
  ) where S.Element == Element {
    for item in elements {
      _append(item)
    }
    _checkInvariants()
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  internal mutating func _prependNew(_ item: Element, in bucket: _Bucket) {
    _elements.insert(item, at: _elements.startIndex)

    guard _elements.count < _capacity else {
      _regenerateHashTable()
      return
    }
    guard _storage != nil else { return }
    _ensureUnique()
    _storage!.update { hashTable in
      hashTable.bias &+= 1
      hashTable[bucket] = 0
    }
  }

  @discardableResult
  public mutating func prepend(_ item: Element) -> (inserted: Bool, index: Base.Index) {
    let (index, bucket) = _find(item)
    if let index = index { return (false, index) }

    _prependNew(item, in: bucket)
    return (true, _elements.startIndex)
  }

  public mutating func prepend<S: Sequence>(
    contentsOf elements: S
  ) where S.Element == Element {
    var new = Self()
    for item in elements {
      guard !self.contains(item) else { continue }
      new._append(item)
    }
    let inserted = new._elements.count
    guard inserted > 0 else { return }
    _elements.insert(contentsOf: new._elements, at: _elements.startIndex)
    defer { _checkInvariants() }
    if _elements.count > _capacity {
      _regenerateHashTable()
      return
    }
    if _storage == nil {
      return
    }
    _ensureUnique()
    _storage!.update { hashTable in
      hashTable.bias += inserted
      var i = 0
      while i != inserted {
        var it = hashTable.bucketIterator(for: _elements[_elements._index(at: i)])
        it.advanceToNextUnoccupiedBucket()
        it.currentValue = i
        i += 1
      }
    }
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  internal mutating func _insertNew(
    _ item: Element,
    at index: Index,
    bucket: _Bucket
  ) -> Int {
    let offset = _elements._offset(of: index)
    guard _elements.count < _capacity else {
      _elements.insert(item, at: index)
      _regenerateHashTable()
      return offset
    }
    guard _storage != nil else {
      _elements.insert(item, at: index)
      return offset
    }

    _storage!.update { hashTable in
      hashTable.adjustContents(preparingForInsertionOfElementAtOffset: offset, in: _elements)
      hashTable[bucket] = offset
    }
    _elements.insert(item, at: index)
    _checkInvariants()
    return offset
  }

  public mutating func insert(
    _ item: Element, at index: Index
  ) -> (inserted: Bool, index: Index) {
    let (existing, bucket) = _find(item)
    if let existing = existing { return (false, existing) }

    let offset = _insertNew(item, at: index, bucket: bucket)
    return (true, _elements._index(at: offset))
  }
}

extension Uniqued where Base: MutableCollection {
  /// Replace the member at the given index with a new value that compares equal
  /// to it.
  ///
  /// This is useful when equal elements can be distinguished by identity
  /// comparison or some other means.
  ///
  /// This method does not invalidate any indices in `self`.
  ///
  /// - Complexity: O(1) if the collection instance has no outstanding copies.
  ///     Otherwise O(n) where _n_ is `self.count`.
  ///
  /// - Parameter index: The index of the element to be replaced.
  /// - Parameter item: The new value that should replace the original element.
  ///     `item` must compare equal to the original value.
  /// - Returns: The original element that was replaced.
  @discardableResult
  public mutating func update(at index: Index, with item: Element) -> Element {
    let old = _elements[index]
    precondition(item == old, "The replacement item must compare equal to the original")
    _elements[index] = item
    return old
  }
}

extension Uniqued where Base: RangeReplaceableCollection & MutableCollection {
  /// Inserts the given element into the set unconditionally, either appending
  /// it to the set, or replacing an existing value if it's already present.
  ///
  /// This is useful when equal elements can be distinguished by identity
  /// comparison or some other means.
  ///
  /// This method does not invalidate indices when the return value is non-`nil`.
  /// Otherwise indices in `self` may get invalidated, depending on the
  /// behavior of the `append` method of the underlying `Base` collection.
  ///
  /// - Complexity: O(1) on average, amortized over many calls on the same collection.
  ///
  /// - Parameter item: The value to append or replace.
  /// - Returns: The original element that was replaced by this operation, or `nil` if the value was appended to the end of the collection.
  public mutating func updateOrAppend(_ item: Element) -> Element? {
    let (inserted, index) = _append(item)
    if inserted { return nil }
    let old = _elements[index]
    _elements[index] = item
    _checkInvariants()
    return old
  }
}
