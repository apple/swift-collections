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

/// An ordered collection of unique elements.
public struct Uniqued<Base>
where Base: RandomAccessCollection, Base.Element: Hashable
{
  internal var _storage: _HashTableStorage?
  internal var _elements: Base

  internal init(_uniqueElements: Base, storage: _HashTableStorage? = nil) {
    self._storage = storage
    self._elements = _uniqueElements
  }
}

extension Uniqued {
  public var contents: Base {
    _elements
  }
}

extension Uniqued {
  /// The maximum number of elements this instance can store before it needs
  /// to resize its hash table.
  @_spi(Testing) public var _capacity: Int {
    _storage?.header.capacity ?? _UnsafeHashTable.maximumUnhashedCount
  }

  @_spi(Testing) public var _minimumCapacity: Int {
    if _scale == _reservedScale { return 0 }
    return _UnsafeHashTable.minimumCapacity(forScale: _scale)
  }

  @_spi(Testing) public var _scale: Int {
    _storage?.header.scale ?? 0
  }

  @_spi(Testing) public var _reservedScale: Int {
    _storage?.header.reservedScale ?? 0
  }

  @_spi(Testing) public var _bias: Int {
    _storage?.header.bias ?? 0
  }
}

extension Uniqued {
  internal mutating func _regenerateHashTable(scale: Int, reservedScale: Int) {
    assert(_UnsafeHashTable.maximumCapacity(forScale: scale) >= _elements.count)
    assert(reservedScale == 0 || reservedScale >= _UnsafeHashTable.minimumScale)
    if scale < _UnsafeHashTable.minimumScale && reservedScale == 0 {
      _storage = nil
      return
    }
    _storage = _HashTableStorage.create(
      from: _elements,
      scale: Swift.max(scale, reservedScale),
      reservedScale: reservedScale,
      stoppingOnFirstDuplicateValue: false).storage
  }

  internal mutating func _regenerateHashTable() {
    let reservedScale = _reservedScale
    guard
      _elements.count > _UnsafeHashTable.maximumUnhashedCount || reservedScale != 0
    else {
      // We have too few elements; disable hashing.
      _storage = nil
      return
    }
    let scale = _UnsafeHashTable.scale(forCapacity: _elements.count)
    _regenerateHashTable(scale: scale, reservedScale: reservedScale)
  }

  internal mutating func _regenerateExistingHashTable() {
    assert(_capacity >= _elements.count)
    guard _storage != nil else {
      return
    }
    _ensureUnique()
    _storage!.update { hashTable in
      hashTable.clear()
      hashTable.fill(from: _elements, stoppingOnFirstDuplicateValue: false)
    }
  }

  internal mutating func _isUnique() -> Bool {
    isKnownUniquelyReferenced(&_storage)
  }

  internal mutating func _ensureUnique() {
    if isKnownUniquelyReferenced(&_storage) { return }
    _storage = _storage!.copy()
  }

  internal mutating func _uniqueStorage() -> _HashTableStorage? {
    if _storage == nil { return nil }
    _ensureUnique()
    return _storage
  }
}

extension Uniqued {
  @_spi(UnsafeInternals)
  public func _find(_ item: Element) -> (index: Index?, bucket: _Bucket) {
    guard let storage = _storage else {
      return (_elements.firstIndex(of: item), _Bucket(offset: 0))
    }
    return storage.read { hashTable in
      let (offset, bucket) = hashTable._find(item, in: _elements)
      return (offset.map { _elements._index(at: $0) }, bucket)
    }
  }

  internal func _offset(of element: Element) -> Int? {
    guard let storage = _storage else {
      return _elements.firstIndex(of: element).map { _elements._offset(of: $0) }
    }
    return storage.read { hashTable in
      hashTable._find(element, in: _elements).offset
    }
  }

  internal func _bucket(for index: Index) -> _Bucket {
    guard let storage = _storage else { return _Bucket(offset: 0) }
    return storage.read { hashTable in
      var it = hashTable.bucketIterator(for: _elements[index])
      let offset = _elements._offset(of: index)
      it.advance(until: offset)
      precondition(it.isOccupied, "Corrupt hash table")
      return it.currentBucket
    }
  }

  public func firstIndex(of element: Element) -> Index? {
    _find(element).index
  }

  public func lastIndex(of element: Element) -> Index? {
    _find(element).index
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  internal __consuming func _extractSubset(
    using bitset: _UnsafeBitset,
    extraCapacity: Int = 0
  ) -> Self {
    assert(bitset.count == 0 || bitset.max()! <= count)
    if bitset.count == 0 { return Self() }
    if bitset.count == self.count { return self }
    var result = Self()
    result.reserveCapacity(bitset.count + extraCapacity)
    result._storage?.header.reservedScale = 0
    for offset in bitset {
      let index = _elements._index(at: offset)
      result._appendNew(_elements[index])
    }
    assert(result.count == bitset.count)
    return result
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  @_spi(UnsafeInternals)
  @discardableResult
  public mutating func _removeExistingMember(
    at index: Index,
    bucket: _Bucket
  ) -> Element {
    guard _elements.count - 1 >= _minimumCapacity else {
      let old = _elements.remove(at: index)
      _regenerateHashTable()
      return old
    }
    guard _storage != nil else {
      return _elements.remove(at: index)
    }

    defer { _checkInvariants() }
    _ensureUnique()
    _storage!.update { hashTable in
      // Delete the entry for the removed member.
      hashTable.delete(
        bucket: bucket,
        hashValueGenerator: { offset, seed in
          let index = _elements._index(at: offset)
          return _elements[index]._rawHashValue(seed: seed)
        })
      hashTable.adjustContents(preparingForRemovalOf: index, in: _elements)
    }
    return _elements.remove(at: index)
  }
}
