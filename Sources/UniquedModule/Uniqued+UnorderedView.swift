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

extension Uniqued {
  public struct UnorderedView {
    public typealias Element = Base.Element

    internal var _base: Uniqued

    internal init(_base: Uniqued) {
      self._base = _base
    }
  }

  @inline(__always)
  public init(_ view: UnorderedView) {
    self = view._base
  }

  public var unordered: UnorderedView {
    _read {
      yield UnorderedView(_base: self)
    }
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  public var unordered: UnorderedView {
    get {
      UnorderedView(_base: self)
    }
    _modify {
      var view = UnorderedView(_base: self)
      self = Uniqued()
      defer { self = view._base }
      yield &view
    }
  }
}

extension Uniqued.UnorderedView: CustomStringConvertible {
  public var description: String {
    _base.description
  }
}

extension Uniqued.UnorderedView: CustomDebugStringConvertible {
  public var debugDescription: String {
    _base._debugDescription(typeName: "\(_base._debugTypeName()).UnorderedView")
  }
}

extension Uniqued.UnorderedView: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    if left._base._hasHashTable && left._base._storage === right._base._storage {
      return true
    }
    guard left._base.count == right._base.count else { return false }

    for item in left._base {
      if !right._base.contains(item) { return false }
    }
    return true
  }
}

extension Uniqued.UnorderedView: Hashable {
  public func hash(into hasher: inout Hasher) {
    // Generate a seed from a snapshot of the hasher.  This makes members' hash
    // values depend on the state of the hasher, which improves hashing
    // quality. (E.g., it makes it possible to resolve collisions by passing in
    // a different hasher.)
    let copy = hasher
    let seed = copy.finalize()

    var hash = 0
    for member in _base {
      hash ^= member._rawHashValue(seed: seed)
    }
    hasher.combine(hash)
  }
}

extension Uniqued.UnorderedView: ExpressibleByArrayLiteral where Base: RangeReplaceableCollection {
  @inline(__always)
  public init(arrayLiteral elements: Element...) {
    _base = Uniqued(elements)
  }
}

extension Uniqued.UnorderedView: SetAlgebra
where Base: RangeReplaceableCollection & MutableCollection {
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  public init() {
    _base = Uniqued()
  }

  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    _base = Uniqued(elements)
  }

  // Specializations

  public init(_ elements: Self) {
    self = elements
  }

  public init(_ elements: Set<Element>) {
    self._base = Uniqued(elements)
  }

  public init<Value>(_ elements: Dictionary<Element, Value>.Keys) {
    self._base = Uniqued(elements)
  }
}

extension Uniqued.UnorderedView {
  public func contains(_ element: Element) -> Bool {
    _base.contains(element)
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  public mutating func insert(
    _ newMember: __owned Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    let (inserted, index) = _base.append(newMember)
    return (inserted, _base[index])
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection & MutableCollection {
  public mutating func update(with newMember: __owned Element) -> Element? {
    let (inserted, index) = _base.append(newMember)
    if inserted { return nil }
    let old = _base._elements[index]
    _base._elements[index] = newMember
    return old
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  @inline(__always)
  @discardableResult
  public mutating func remove(_ member: Self.Element) -> Self.Element? {
    _base.remove(member)
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  @inline(__always)
  public mutating func formUnion(_ other: __owned Self) {
    _base.formUnion(other._base)
  }

  @inline(__always)
  public __consuming func union(_ other: __owned Self) -> Self {
    _base.union(other._base).unordered
  }

  // Generalizations

  @inline(__always)
  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    _base.formUnion(other)
  }

  @inline(__always)
  public __consuming func union<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    _base.union(other).unordered
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  @inline(__always)
  public __consuming func intersection(_ other: Self) -> Self {
    _base.intersection(other._base).unordered
  }

  @inline(__always)
  public mutating func formIntersection(_ other: Self) {
    _base.formIntersection(other._base)
  }

  // Generalizations

  @inline(__always)
  public __consuming func intersection<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _base.intersection(other).unordered
  }

  @inline(__always)
  public mutating func formIntersection<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    _base.formIntersection(other)
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  @inline(__always)
  public __consuming func symmetricDifference(_ other: __owned Self) -> Self {
    _base.symmetricDifference(other._base).unordered
  }

  @inline(__always)
  public mutating func formSymmetricDifference(_ other: __owned Self) {
    _base.formSymmetricDifference(other._base)
  }

  // Generalizations

  @inline(__always)
  public __consuming func symmetricDifference<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    _base.symmetricDifference(other).unordered
  }

  @inline(__always)
  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    _base.formSymmetricDifference(other)
  }
}

extension Uniqued.UnorderedView where Base: RangeReplaceableCollection {
  @inline(__always)
  public __consuming func subtracting(_ other: Self) -> Self {
    _base.subtracting(other._base).unordered
  }

  @inline(__always)
  public mutating func subtract(_ other: Self) {
    _base.subtract(other._base)
  }

  // Generalizations
  @inline(__always)
  public __consuming func subtracting<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _base.subtracting(other).unordered
  }

  @inline(__always)
  public mutating func subtract<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    _base.subtract(other)
  }
}

extension Uniqued.UnorderedView {
  @inline(__always)
  public func isSubset(of other: Self) -> Bool {
    _base.isSubset(of: other._base)
  }

  // Generalizations

  @inline(__always)
  public func isSubset(of other: Set<Element>) -> Bool {
    _base.isSubset(of: other)
  }

  @inline(__always)
  public func isSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _base.isSubset(of: other)
  }
}

extension Uniqued.UnorderedView {
  @inline(__always)
  public func isSuperset(of other: Self) -> Bool {
    _base.isSuperset(of: other._base)
  }

  // Generalizations

  @inline(__always)
  public func isSuperset(of other: Set<Element>) -> Bool {
    _base.isSuperset(of: other)
  }

  @inline(__always)
  public func isSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _base.isSuperset(of: other)
  }
}

extension Uniqued.UnorderedView {
  @inline(__always)
  public func isStrictSubset(of other: Self) -> Bool {
    _base.isStrictSubset(of: other._base)
  }

  // Generalizations

  @inline(__always)
  public func isStrictSubset(of other: Set<Element>) -> Bool {
    _base.isStrictSubset(of: other)
  }

  @inline(__always)
  public func isStrictSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _base.isStrictSubset(of: other)
  }
}

extension Uniqued.UnorderedView {
  public func isStrictSuperset(of other: Self) -> Bool {
    _base.isStrictSuperset(of: other._base)
  }

  // Generalizations

  public func isStrictSuperset(of other: Set<Element>) -> Bool {
    _base.isStrictSuperset(of: other)
  }

  public func isStrictSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _base.isStrictSuperset(of: other)
  }
}

extension Uniqued.UnorderedView {
  public func isDisjoint(with other: Self) -> Bool {
    _base.isDisjoint(with: other._base)
  }

  // Generalizations

  public func isDisjoint(with other: Set<Element>) -> Bool {
    _base.isDisjoint(with: other)
  }

  public func isDisjoint<S: Sequence>(
    with other: S
  ) -> Bool where S.Element == Element {
    _base.isDisjoint(with: other)
  }
}
