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

// `Uniqued` does not directly conform to `SetAlgebra` because its definition
// of equality conflicts with `SetAlgebra` requirements. However, it still
// implements most `SetAlgebra` requirements (except `insert`, which is replaced
// by `append`).
//
// `Uniqued` also provides an `unordered` view that explicitly conforms to
// `SetAlgebra`. That view implements `Equatable` by ignoring element order,
// so it can satisfy `SetAlgebra` requirements.

extension Uniqued where Base: RangeReplaceableCollection {
  public init() {
    _storage = nil
    _elements = Base()
  }

  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    if S.self == Self.self {
      self = elements as! Self
      return
    }
    if S.self == Set<Element>.self {
      // Fast path for when we know elements are all unique
      self.init(uncheckedUniqueElements: Base(elements))
      return
    }

    self.init()
    append(contentsOf: elements)
  }

  // Specializations

  public init(_ elements: Self) {
    self = elements
  }

  public init(_ elements: SubSequence) {
    self.init(uncheckedUniqueElements: Base(elements._slice))
  }

  public init(_ elements: Set<Element>) {
    self.init(uncheckedUniqueElements: Base(elements))
  }

  public init(_ elements: Base) {
    let (storage, firstDupe) = _HashTableStorage.create(
      from: elements,
      stoppingOnFirstDuplicateValue: true)
    if firstDupe == elements.endIndex {
      // Fast path: `elements` consists of unique values.
      self.init(_uniqueElements: elements, storage: storage)
      return
    }

    // Otherwise keep the elements we've processed and add the rest one by one.
    var contents = elements
    contents.removeLast(elements.count - elements._offset(of: firstDupe))
    self.init(_uniqueElements: contents, storage: storage)
    self.append(contentsOf: elements[firstDupe...])
  }

  public init<Value>(_ elements: Dictionary<Element, Value>.Keys) {
    self._elements = Base(elements)
    _regenerateHashTable()
    _checkInvariants()
  }
}

extension Uniqued {
  public func contains(_ element: Element) -> Bool {
    guard let storage = _storage else {
      return _elements.contains(element)
    }
    return storage.read { hashTable in
      hashTable._find(element, in: _elements).offset != nil
    }
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    let (idx, bucket) = _find(member)
    guard let index = idx else { return nil }
    return _removeExistingMember(at: index, bucket: bucket)
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  public mutating func formUnion(_ other: __owned Self) {
    for item in other {
      append(item)
    }
  }

  public __consuming func union(_ other: __owned Self) -> Self {
    var result = self
    result.formUnion(other)
    return result
  }

  // Generalizations

  @inline(__always)
  public mutating func formUnion(_ other: __owned UnorderedView) {
    formUnion(other._base)
  }

  @inline(__always)
  public __consuming func union(_ other: __owned UnorderedView) -> Self {
    union(other._base)
  }

  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    for item in other {
      append(item)
    }
  }

  public __consuming func union<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    var result = self
    result.formUnion(other)
    return result
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  public __consuming func intersection(_ other: Self) -> Self {
    var result = Self()
    for item in self {
      if other.contains(item) {
        result._appendNew(item)
      }
    }
    return result
  }

  public mutating func formIntersection(_ other: Self) {
    self = self.intersection(other)
  }

  // Generalizations

  @inline(__always)
  public __consuming func intersection(_ other: UnorderedView) -> Self {
    intersection(other._base)
  }

  @inline(__always)
  public mutating func formIntersection(_ other: UnorderedView) {
    formIntersection(other._base)
  }

  public __consuming func intersection<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset in
      for item in other {
        if let index = self.firstIndex(of: item) {
          bitset.insert(_elements._offset(of: index))
        }
      }
      return self._extractSubset(using: bitset)
    }
  }

  public mutating func formIntersection<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    self = self.intersection(other)
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  public __consuming func symmetricDifference(_ other: __owned Self) -> Self {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset1 in
      _UnsafeBitset.withTemporaryBitset(capacity: other.count) { bitset2 in
        bitset1.insertAll(upTo: self.count)
        for item in other {
          if let offset = self._offset(of: item) {
            bitset1.remove(offset)
          }
        }
        bitset2.insertAll(upTo: other.count)
        for item in self {
          if let offset = other._offset(of: item) {
            bitset2.remove(offset)
          }
        }
        var result = self._extractSubset(using: bitset1,
                                         extraCapacity: bitset2.count)
        for offset in bitset2 {
          let index = other._elements._index(at: offset)
          result._appendNew(other._elements[index])
        }
        return result
      }
    }
  }

  public mutating func formSymmetricDifference(_ other: __owned Self) {
    self = self.symmetricDifference(other)
  }

  // Generalizations

  @inline(__always)
  public __consuming func symmetricDifference(_ other: __owned UnorderedView) -> Self {
    symmetricDifference(other._base)
  }

  @inline(__always)
  public mutating func formSymmetricDifference(_ other: __owned UnorderedView) {
    formSymmetricDifference(other._base)
  }

  public __consuming func symmetricDifference<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset in
      var new = Self()
      bitset.insertAll(upTo: self.count)
      for item in other {
        if let offset = self._offset(of: item) {
          bitset.remove(offset)
        } else {
          new.append(item)
        }
      }
      var result = Self(minimumCapacity: bitset.count + new.count)
      for offset in bitset {
        let index = self._elements._index(at: offset)
        result._appendNew(self._elements[index])
      }
      for item in new._elements {
        result._appendNew(item)
      }
      return result
    }
  }

  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    self = self.symmetricDifference(other)
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  @inline(__always)
  public __consuming func subtracting(_ other: Self) -> Self {
    _subtracting(other)
  }

  @inline(__always)
  public mutating func subtract(_ other: Self) {
    self = subtracting(other)
  }

  // Generalizations

  @inline(__always)
  public __consuming func subtracting(_ other: UnorderedView) -> Self {
    subtracting(other._base)
  }

  @inline(__always)
  public mutating func subtract(_ other: UnorderedView) {
    subtract(other._base)
  }

  @inline(__always)
  public __consuming func subtracting<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _subtracting(other)
  }

  @inline(__always)
  public mutating func subtract<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    self = _subtracting(other)
  }

  __consuming func _subtracting<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    guard count > 0 else { return Self() }
    return _UnsafeBitset.withTemporaryBitset(capacity: count) { difference in
      difference.insertAll(upTo: count)
      for item in other {
        if let offset = self._offset(of: item) {
          if difference.remove(offset), difference.count == 0 {
            return Self()
          }
        }
      }
      assert(difference.count > 0)
      return _extractSubset(using: difference)
    }
  }
}

extension Uniqued {
  public func isSubset(of other: Self) -> Bool {
    guard other.count >= self.count else { return false }
    for item in self {
      guard other.contains(item) else { return false }
    }
    return true
  }

  // Generalizations

  @inline(__always)
  public func isSubset(of other: UnorderedView) -> Bool {
    isSubset(of: other._base)
  }

  public func isSubset(of other: Set<Element>) -> Bool {
    guard other.count >= self.count else { return false }
    for item in self {
      guard other.contains(item) else { return false }
    }
    return true
  }

  public func isSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    guard !isEmpty else { return true }
    return _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      for item in other {
        if let offset = _offset(of: item) {
          if seen.insert(offset), seen.count == self.count {
            // We've seen enough.
            return true
          }
        }
      }
      return false
    }
  }
}

extension Uniqued {
  public func isSuperset(of other: Self) -> Bool {
    other.isSubset(of: self)
  }

  // Generalizations

  public func isSuperset(of other: UnorderedView) -> Bool {
    isSuperset(of: other._base)
  }

  public func isSuperset(of other: Set<Element>) -> Bool {
    guard self.count >= other.count else { return false }
    return _isSuperset(of: other)
  }

  public func isSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _isSuperset(of: other)
  }

  internal func _isSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    for item in other {
      guard self.contains(item) else { return false }
    }
    return true
  }
}

extension Uniqued {
  public func isStrictSubset(of other: Self) -> Bool {
    self.count < other.count && self.isSubset(of: other)
  }

  // Generalizations

  @inline(__always)
  public func isStrictSubset(of other: UnorderedView) -> Bool {
    isStrictSubset(of: other._base)
  }

  public func isStrictSubset(of other: Set<Element>) -> Bool {
    self.count < other.count && self.isSubset(of: other)
  }

  public func isStrictSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      var isKnownStrict = false
      for item in other {
        if let offset = _offset(of: item) {
          if seen.insert(offset), seen.count == self.count, isKnownStrict {
            // We've seen enough.
            return true
          }
        } else {
          if !isKnownStrict, seen.count == self.count { return true }
          isKnownStrict = true
        }
      }
      return false
    }
  }
}

extension Uniqued {
  public func isStrictSuperset(of other: Self) -> Bool {
    self.count > other.count && other.isSubset(of: self)
  }

  // Generalizations

  @inline(__always)
  public func isStrictSuperset(of other: UnorderedView) -> Bool {
    isStrictSuperset(of: other._base)
  }

  public func isStrictSuperset(of other: Set<Element>) -> Bool {
    self.count > other.count && other.isSubset(of: self)
  }

  public func isStrictSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      for item in other {
        guard let offset = _offset(of: item) else {
          return false
        }
        if seen.insert(offset), seen.count == self.count {
          // We've seen enough.
          return false
        }
      }
      return seen.count < self.count
    }
  }
}

extension Uniqued {
  public func isDisjoint(with other: Self) -> Bool {
    guard !self.isEmpty && !other.isEmpty else { return true }
    if self.count <= other.count {
      for item in self {
        if other.contains(item) { return false }
      }
    } else {
      for item in other {
        if self.contains(item) { return false }
      }
    }
    return true
  }

  // Generalizations

  @inline(__always)
  public func isDisjoint(with other: UnorderedView) -> Bool {
    isDisjoint(with: other._base)
  }

  public func isDisjoint(with other: Set<Element>) -> Bool {
    guard !self.isEmpty && !other.isEmpty else { return true }
    if self.count <= other.count {
      for item in self {
        if other.contains(item) { return false }
      }
    } else {
      for item in other {
        if self.contains(item) { return false }
      }
    }
    return true
  }

  public func isDisjoint<S: Sequence>(
    with other: S
  ) -> Bool where S.Element == Element {
    guard !self.isEmpty else { return true }
    for item in other {
      if self.contains(item) { return false }
    }
    return true
  }
}

