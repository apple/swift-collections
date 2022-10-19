//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsUtilities

extension BitSet {
  public struct Counted {
    @usableFromInline
    internal var _bits: BitSet
    @usableFromInline
    internal var _count: Int

    internal init(_bits: BitSet, count: Int) {
      self._bits = _bits
      self._count = count
      _checkInvariants()
    }
  }
}

#if swift(>=5.5)
extension BitSet.Counted: Sendable {}
#endif

extension BitSet.Counted {
#if COLLECTIONS_INTERNAL_CHECKS
  @inline(never)
  @_effects(releasenone)
  public func _checkInvariants() {
    _bits._checkInvariants()
    precondition(_count == _bits.count)
  }
#else
  @inline(__always) @inlinable
  public func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

extension BitSet.Counted: _UniqueCollection {}

extension BitSet.Counted {
  public init() {
    self.init(BitSet())
  }

  @inlinable
  public init<S: Sequence>(words: S) where S.Element == UInt {
    self.init(BitSet(words: words))
  }

  @inlinable
  public init<I: BinaryInteger>(bitPattern x: I) {
    self.init(words: x.words)
  }

  public init(_ array: BitArray) {
    self.init(BitSet(array))
  }

  @inlinable
  public init<S: Sequence>(
    _ elements: __owned S
  ) where S.Element == Int {
    self.init(BitSet(elements))
  }

  public init(_ range: Range<Int>) {
    self.init(BitSet(range))
  }
}

extension BitSet.Counted {
  public init(_ bits: BitSet) {
    self.init(_bits: bits, count: bits.count)
  }

  public var uncounted: BitSet {
    get { _bits }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    _modify {
      defer {
        _count = _bits.count
      }
      yield &_bits
    }
  }
}

extension BitSet {
  public init(_ bits: BitSet.Counted) {
    self = bits._bits
  }

  var counted: BitSet.Counted {
    get {
      BitSet.Counted(_bits: self, count: self.count)
    }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    _modify {
      var value = BitSet.Counted(self)
      self = []
      defer { self = value._bits }
      yield &value
    }
  }
}

extension BitSet.Counted: Sequence {
  public typealias Iterator = BitSet.Iterator

  public var underestimatedCount: Int {
    _count
  }

  public func makeIterator() -> BitSet.Iterator {
    _bits.makeIterator()
  }

  public func _customContainsEquatableElement(
    _ element: Int
  ) -> Bool? {
    _bits._customContainsEquatableElement(element)
  }
}

extension BitSet.Counted: BidirectionalCollection {
  public typealias Index = BitSet.Index

  public var isEmpty: Bool { _count == 0 }

  public var count: Int { _count }

  public var startIndex: Index { _bits.startIndex }
  public var endIndex: Index { _bits.endIndex }

  public subscript(position: Index) -> Int {
    _bits[position]
  }

  public func index(after index: Index) -> Index {
    _bits.index(after: index)
  }

  public func index(before index: Index) -> Index {
    _bits.index(before: index)
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _bits.distance(from: start, to: end)
  }

  public func index(_ index: Index, offsetBy distance: Int) -> Index {
    _bits.index(index, offsetBy: distance)
  }

  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    _bits.index(i, offsetBy: distance, limitedBy: limit)
  }

  public func _customIndexOfEquatableElement(_ element: Int) -> Index?? {
    _bits._customIndexOfEquatableElement(element)
  }

  public func _customLastIndexOfEquatableElement(_ element: Int) -> Index?? {
    _bits._customLastIndexOfEquatableElement(element)
  }
}


extension BitSet.Counted: Codable {
  public func encode(to encoder: Encoder) throws {
    try _bits.encode(to: encoder)
  }

  public init(from decoder: Decoder) throws {
    self.init(try BitSet(from: decoder))
  }
}

extension BitSet.Counted: CustomStringConvertible {
  public var description: String {
    _bits.description
  }
}

extension BitSet.Counted: CustomDebugStringConvertible {
  public var debugDescription: String {
    _bits._debugDescription(typeName: "BitSet.Counted")
  }
}

extension BitSet.Counted: CustomReflectable {
  public var customMirror: Mirror {
    _bits.customMirror
  }
}

extension BitSet.Counted: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    guard left._count == right._count else { return false }
    return left._bits == right._bits
  }
}

extension BitSet.Counted: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_bits)
  }
}

extension BitSet.Counted: ExpressibleByArrayLiteral {
  @inlinable
  public init(arrayLiteral elements: Int...) {
    let bits = BitSet(elements)
    self.init(bits)
  }
}

extension BitSet.Counted { // Extras
  public init(reservingCapacity maximumValue: Int) {
    self.init(_bits: BitSet(reservingCapacity: maximumValue), count: 0)
  }

  public mutating func reserveCapacity(_ maximumValue: Int) {
    _bits.reserveCapacity(maximumValue)
  }

  public subscript(member member: Int) -> Bool {
    get { contains(member) }
    set {
      if newValue {
        insert(member)
      } else {
        remove(member)
      }
    }
  }

  public subscript(members bounds: Range<Int>) -> Slice<BitSet> {
    _bits[members: bounds]
  }

  public subscript<R: RangeExpression>(members bounds: R) -> Slice<BitSet>
  where R.Bound == Int
  {
    _bits[members: bounds]
  }

  public func sorted() -> BitSet.Counted { self }
}

extension BitSet.Counted {
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    BitSet.Counted(try _bits.filter(isIncluded))
  }
}

extension BitSet.Counted {
  public static func random(upTo limit: Int) -> BitSet.Counted {
    BitSet.Counted(BitSet.random(upTo: limit))
  }

  public static func random<R: RandomNumberGenerator>(
    upTo limit: Int,
    using rng: inout R
  ) -> BitSet.Counted {
    BitSet.Counted(BitSet.random(upTo: limit, using: &rng))
  }
}

extension BitSet.Counted: SetAlgebra {
  public func contains(_ member: Int) -> Bool {
    _bits.contains(member)
  }

  @discardableResult
  public mutating func insert(
    _ newMember: Int
  ) -> (inserted: Bool, memberAfterInsert: Int) {
    let r = _bits.insert(newMember)
    if r.inserted { _count += 1 }
    return r
  }

  @discardableResult
  public mutating func update(with newMember: Int) -> Int? {
    _bits.update(with: newMember)
  }

  @discardableResult
  public mutating func remove(_ member: Int) -> Int? {
    let old = _bits.remove(member)
    if old != nil { _count -= 1 }
    return old
  }
}

extension BitSet.Counted {
  public func union(_ other: __owned BitSet.Counted) -> BitSet.Counted {
    Self(_bits.union(other))
  }

  public func union(_ other: __owned BitSet) -> BitSet.Counted {
    Self(_bits.union(other))
  }

  public func union(_ other: Range<Int>) -> BitSet.Counted {
    Self(_bits.union(other))
  }

  @inlinable
  public __consuming func union<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int {
    Self(_bits.union(other))
  }
}

extension BitSet.Counted {
  public func intersection(_ other: BitSet.Counted) -> BitSet.Counted {
    Self(_bits.intersection(other))
  }

  public func intersection(_ other: __owned BitSet) -> BitSet.Counted {
    Self(_bits.intersection(other))
  }

  public func intersection(_ other: Range<Int>) -> BitSet.Counted {
    Self(_bits.intersection(other))
  }

  @inlinable
  public __consuming func intersection<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int {
    Self(_bits.intersection(other))
  }
}

extension BitSet.Counted {
  public func symmetricDifference(_ other: __owned BitSet.Counted) -> BitSet.Counted {
    Self(_bits.symmetricDifference(other))
  }

  public func symmetricDifference(_ other: __owned BitSet) -> BitSet.Counted {
    Self(_bits.symmetricDifference(other))
  }

  public func symmetricDifference(_ other: Range<Int>) -> BitSet.Counted {
    Self(_bits.symmetricDifference(other))
  }

  @inlinable
  public __consuming func symmetricDifference<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int {
    Self(_bits.symmetricDifference(other))
  }
}

extension BitSet.Counted {
  public func subtracting(_ other: __owned BitSet.Counted) -> BitSet.Counted {
    Self(_bits.subtracting(other))
  }

  public func subtracting(_ other: __owned BitSet) -> BitSet.Counted {
    Self(_bits.subtracting(other))
  }

  public func subtracting(_ other: Range<Int>) -> BitSet.Counted {
    Self(_bits.subtracting(other))
  }

  @inlinable
  public __consuming func subtracting<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int {
    Self(_bits.subtracting(other))
  }
}

extension BitSet.Counted {
  public mutating func formUnion(_ other: __owned BitSet.Counted) {
    _bits.formUnion(other._bits)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formUnion(_ other: __owned BitSet) {
    _bits.formUnion(other)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formUnion(_ other: Range<Int>) {
    _bits.formUnion(other)
    _count = _bits.count
    _checkInvariants()
  }

  @inlinable
  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    _bits.formUnion(other)
    _count = _bits.count
    _checkInvariants()
  }
}

extension BitSet.Counted {
  public mutating func formIntersection(_ other: BitSet.Counted) {
    _bits.formIntersection(other._bits)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formIntersection(_ other: __owned BitSet) {
    _bits.formIntersection(other)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formIntersection(_ other: Range<Int>) {
    _bits.formIntersection(other)
    _count = _bits.count
    _checkInvariants()
  }

  @inlinable
  public mutating func formIntersection<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    _bits.formIntersection(other)
    _count = _bits.count
    _checkInvariants()
  }
}

extension BitSet.Counted {
  public mutating func formSymmetricDifference(_ other: __owned BitSet.Counted) {
    _bits.formSymmetricDifference(other._bits)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formSymmetricDifference(_ other: __owned BitSet) {
    _bits.formSymmetricDifference(other)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func formSymmetricDifference(_ other: Range<Int>) {
    _bits.formSymmetricDifference(other)
    _count = _bits.count
    _checkInvariants()
  }

  @inlinable
  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    _bits.formSymmetricDifference(other)
    _count = _bits.count
    _checkInvariants()
  }
}

extension BitSet.Counted {
  public mutating func subtract(_ other: __owned BitSet.Counted) {
    _bits.subtract(other._bits)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func subtract(_ other: __owned BitSet) {
    _bits.subtract(other)
    _count = _bits.count
    _checkInvariants()
  }

  public mutating func subtract(_ other: Range<Int>) {
    _bits.subtract(other)
    _count = _bits.count
    _checkInvariants()
  }

  @inlinable
  public mutating func subtract<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    _bits.subtract(other)
    _count = _bits.count
    _checkInvariants()
  }
}

extension BitSet.Counted {
  public func isSubset(of other: Self) -> Bool {
    if self.count > other.count { return false }
    return self._bits.isSubset(of: other._bits)
  }

  public func isSubset(of other: BitSet) -> Bool {
    self._bits.isSubset(of: other)
  }

  public func isSubset(of other: Range<Int>) -> Bool {
    guard !isEmpty else { return true }
    return _bits.isSubset(of: other)
  }

  @inlinable
  public func isSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    guard !isEmpty else { return true }
    return _bits.isSubset(of: other)
  }
}

extension BitSet.Counted {
  public func isSuperset(of other: Self) -> Bool {
    other.isSubset(of: self)
  }

  public func isSuperset(of other: BitSet) -> Bool {
    other.isSubset(of: self)
  }

  public func isSuperset(of other: Range<Int>) -> Bool {
    return _bits.isSuperset(of: other)
  }

  @inlinable
  public func isSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    return _bits.isSubset(of: other)
  }
}

extension BitSet.Counted {
  public func isStrictSubset(of other: Self) -> Bool {
    guard self.count < other.count else { return false }
    return _bits.isStrictSubset(of: other._bits)
  }

  public func isStrictSubset(of other: BitSet) -> Bool {
    _bits.isStrictSubset(of: other)
  }

  public func isStrictSubset(of other: Range<Int>) -> Bool {
    guard self.count < other.count else { return false }
    return _bits.isStrictSubset(of: other)
  }

  @inlinable
  public func isStrictSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    _bits.isStrictSubset(of: other)
  }
}

extension BitSet.Counted {
  public func isStrictSuperset(of other: Self) -> Bool {
    other.isStrictSubset(of: self)
  }

  public func isStrictSuperset(of other: BitSet) -> Bool {
    other.isStrictSubset(of: self)
  }

  public func isStrictSuperset(of other: Range<Int>) -> Bool {
    _bits.isStrictSuperset(of: other)
  }

  @inlinable
  public func isStrictSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    _bits.isStrictSuperset(of: other)
  }
}

extension BitSet.Counted {
  public func isDisjoint(with other: Self) -> Bool {
    _bits.isDisjoint(with: other._bits)
  }

  public func isDisjoint(with other: BitSet) -> Bool {
    _bits.isDisjoint(with: other)
  }

  public func isDisjoint(with other: Range<Int>) -> Bool {
    _bits.isDisjoint(with: other)
  }

  @inlinable
  public func isDisjoint<S: Sequence>(with other: S) -> Bool
  where S.Element == Int
  {
    _bits.isDisjoint(with: other)
  }
}
