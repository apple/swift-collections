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

extension CountedSet: SetAlgebra {
  @inlinable
  public init() {
    _storage = RawValue()
  }

  /// Returns a new set with the greater number of elements of both this and the
  /// given set.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, preserving
  /// the higher multiplicity.
  /// - Note: This function does **not** add the multiplicities of each set
  /// together. Rather, it discards the lower multiplicity for each element.
  @inlinable
  public __consuming func union(_ other: __owned CountedSet<Element>)
  -> CountedSet<Element> {
    var result = self
    result.formUnion(other)
    return result
  }

  /// Returns a new set with the lesser number of elements of both this and the
  /// given set.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, preserving
  /// the lower multiplicity.
  /// - Complexity: O(*k*), where *k* is the number of unique elements in the
  /// current set.
  @inlinable
  public __consuming func intersection(_ other: CountedSet<Element>)
  -> CountedSet<Element> {
    var result = self
    result.formIntersection(other)
    return result
  }


  /// Returns a new set with the difference between the number of elements of
  /// both this and the given set.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, taking the
  /// difference between multiplicities.
  @inlinable
  public __consuming func symmetricDifference(
    _ other: __owned CountedSet<Element>
  ) -> CountedSet<Element> {
    var result = self
    result.formSymmetricDifference(other)
    return result
  }

  /// Inserts the given element in the set.
  ///
  /// If an element equal to `newMember` is already contained in the set, its
  /// multiplicity is incremented by one. In this example, a new element is
  /// inserted into `classDays`, a set of days of the week.
  ///
  ///     enum DayOfTheWeek: Int {
  ///         case sunday, monday, tuesday, wednesday, thursday,
  ///             friday, saturday
  ///     }
  ///
  ///     var classDays: CountedSet<DayOfTheWeek> = [.wednesday, .friday]
  ///     print(classDays.insert(.monday))
  ///     // Prints "(true, .monday)"
  ///     print(classDays)
  ///     // Prints "[.friday, .wednesday, .monday]"
  ///
  ///     print(classDays.insert(.friday))
  ///     // Prints "(true, .friday)"
  ///     print(classDays)
  ///     // Prints "[.friday, .friday, .wednesday, .monday]"
  ///
  /// - Parameter newMember: An element to insert into the set.
  /// - Complexity: Amortized O(1)
  /// - Note: Insertion is always performed, in contrast to an uncounted set.
  /// This means that the result's `inserted` value is always `true`.
  @inlinable
  @discardableResult
  public mutating func insert(_ newMember: __owned Element)
  -> (inserted: Bool, memberAfterInsert: Element) {
    _storage[newMember, default: 0] += 1
    return (inserted: true, memberAfterInsert: newMember)
  }

  /// Removes the given element.
  ///
  /// If an element equal to `member` is contained in the set, its
  /// multiplicity is decremented by one.
  /// - Parameter member: An element to remove from the set.
  /// - Complexity: O(*k*), where *k* is the number of unique elements in the
  /// set, if the multiplicity of the given element was one. Otherwise, O(1).
  /// - Note: This method is *not* idempotent, in contrast to an uncounted set,
  /// as multiple instances of the given element may be present.
  @inlinable
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    guard let oldMultiplicity = rawValue[member] else {
      return nil
    }

    if oldMultiplicity > 1 {
      _storage[member] = oldMultiplicity &- 1
    } else {
      _storage.removeValue(forKey: member)
    }
    return member
  }

  /// Inserts the given element in the set and replaces equal elements that are
  /// already present.
  ///
  /// If an element equal to `newMember` is contained in the set, its
  /// multiplicity is transferred to `newMember` and incremented by one.
  /// - Parameter newMember: An element to insert into the set.
  /// - Returns: The element equal to `newMember` that was contained in the set,
  /// if any.
  /// - Complexity: O(*k*), where *k* is the number of unique elements in the
  /// set.
  @inlinable
  @discardableResult
  public mutating func update(with newMember: __owned Element) -> Element? {
    guard let oldMemberIndex = rawValue.index(forKey: newMember) else {
      insert(newMember)
      return nil
    }

    let (oldMember, oldValue) = _storage.remove(at: oldMemberIndex)
    _storage[newMember] = oldValue + 1
    return oldMember
  }

  /// Combines the given set into the current set, keeping the higher number of
  /// elements.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, preserving
  /// the higher multiplicity.
  /// - Note: This function does **not** add the multiplicities of each set
  /// together. Rather, it discards the lower multiplicity for each element.
  @inlinable
  public mutating func formUnion(_ other: __owned CountedSet<Element>) {
    _storage.merge(other.rawValue, uniquingKeysWith: Swift.max)
  }

  /// Combines the given set into the current set, keeping the lower number of
  /// elements.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, preserving
  /// the lower multiplicity.
  /// - Complexity: O(*k*), where *k* is the number of unique elements in the
  /// current set.
  @inlinable
  public mutating func formIntersection(_ other: CountedSet<Element>) {
    _storage = RawValue(
      uniqueKeysWithValues: rawValue.lazy.compactMap { key, value in
        other.rawValue[key].map { (key, Swift.min($0, value)) }
      }
    )
  }

  /// Combines the given set into the current set, keeping the difference
  /// between the number of elements.
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set with the elements of this set and `other`, taking the
  /// difference between multiplicities.
  @inlinable
  public mutating func formSymmetricDifference(
    _ other: __owned CountedSet<Element>
  ) {
    _storage = rawValue.merging(other.rawValue) {
      $0 >= $1 ? $0 &- $1 : $1 &- $0
    }.filter {
      $0.value != .zero
    }
  }
}
