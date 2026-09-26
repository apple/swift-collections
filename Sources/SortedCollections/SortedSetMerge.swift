//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Utilities for merging two already-sorted sequences as if they were sets.

// MARK: Raw Results of Sorted Set Mergers

/// A comparison result emitted while merging two sorted sequences.
///
/// Each result indicates whether the merged sequence element is sourced from
/// strictly to the first sequence,
/// strictly to the second sequence,
/// or present in both sequences (*i.e.*, shared).
///
/// - SeeAlso: ``rawSortedMerge(of:and:sortingBy:)``
public enum SortedSetMergeComparison<Element> {
  /// Value occurs only in the first sequence.
  case exclusiveToFirst(first: Element)
  /// Value occurs only in the second sequence.
  case exclusiveToSecond(second: Element)
  /// Value occurs in both sequences; payloads are the equal values from each side.
  case shared(first: Element, second: Element)
}

/// A lazy sequence that walks two sorted input sequences and reports how their
/// elements relate to each other without coalescing duplicates.
///
/// Use this when you need to know whether a value is unique to a side or
/// appears in both, e.g. to implement set-like operations.
public struct SortedSetRawMergingSequence<First: Sequence, Second: Sequence>
where First.Element == Second.Element {
  let firstBase: First
  let secondBase: Second
  let areInIncreasingOrder: (First.Element, Second.Element) -> Bool
}

extension SortedSetRawMergingSequence: LazySequenceProtocol {
  public struct Iterator: IteratorProtocol {
    var firstBase: First.Iterator
    var secondBase: Second.Iterator
    let areInIncreasingOrder: (First.Element, Second.Element) -> Bool

    fileprivate var firstCache: First.Element?
    fileprivate var secondCache: Second.Element?

    public mutating func next() -> SortedSetMergeComparison<First.Element>? {
      firstCache = firstCache ?? firstBase.next()
      secondCache = secondCache ?? secondBase.next()
      switch (firstCache, secondCache) {
      case (let first?, let second?):
        if areInIncreasingOrder(first, second) {
          firstCache = nil
          return .exclusiveToFirst(first: first)
        } else if areInIncreasingOrder(second, first) {
          secondCache = nil
          return .exclusiveToSecond(second: second)
        } else {
          firstCache = nil
          secondCache = nil
          return .shared(first: first, second: second)
        }
      case (let first?, nil):
        firstCache = nil
        return .exclusiveToFirst(first: first)
      case (nil, let second?):
        secondCache = nil
        return .exclusiveToSecond(second: second)
      case (nil, nil):
        return nil
      }
    }
  }

  public func makeIterator() -> Iterator {
    return .init(
      firstBase: firstBase.makeIterator(),
      secondBase: secondBase.makeIterator(),
      areInIncreasingOrder: areInIncreasingOrder
    )
  }

  public var underestimatedCount: Int {
    switch (
      firstBase.underestimatedCount > 0, secondBase.underestimatedCount > 0
    ) {
    case (false, false):
      0
    case (false, true):
      secondBase.underestimatedCount
    case (true, false):
      firstBase.underestimatedCount
    case (true, true):
      Swift.min(firstBase.underestimatedCount, secondBase.underestimatedCount)
    }
  }
}

/// Creates a lazy sequence that merges the two sequences sorted along
/// the given predicate to report the raw comparisons between them.
///
/// - Parameters:
///   - first: The first input sequence, sorted by `areInIncreasingOrder`.
///   - second: The second input sequence, sorted by `areInIncreasingOrder`.
///   - areInIncreasingOrder: A strict weak ordering that defines ascending
///     order for elements.
/// - Returns: A lazy sequence of ``SortedSetMergeComparison`` values.
///
/// - Note: Results are yielded in ascending order as determined by
///   `areInIncreasingOrder`. Equal elements across inputs are reported via a
///   single `.shared` result.
///
/// - Note: Stability: For equal elements that originate from the same input
///   sequence, their original relative order is preserved when they are emitted
///   as exclusives. When a `.shared` is produced for equal elements across
///   inputs, it represents the pair in the order discovered by the merge.
///
/// ### Example
/// ```swift
/// let a = [5, 4, 2, 1]
/// let b = [5, 3, 2]
/// let comparisons = rawSortedMerge(of: a, and: b, sortingBy: >)
/// for c in comparisons {
///   switch c {
///   case .exclusiveToFirst(let x): print("A-only: \(x)")
///   case .exclusiveToSecond(let y): print("B-only: \(y)")
///   case .shared(let x, _): print("Shared: \(x)")
///   }
/// }
/// // Prints (order may vary with iteration):
/// // Shared: 5
/// // A-only: 4
/// // B-only: 3
/// // Shared: 2
/// // A-only: 1
/// ```
public func rawSortedMerge<First, Second>(
  of first: First,
  and second: Second,
  sortingBy areInIncreasingOrder:
    @escaping (First.Element, Second.Element) -> Bool
)
  -> SortedSetRawMergingSequence<First, Second>
where First: Sequence, Second: Sequence, First.Element == Second.Element {
  return .init(
    firstBase: first,
    secondBase: second,
    areInIncreasingOrder: areInIncreasingOrder
  )
}

/// Creates a lazy sequence that merges the two sorted sequences to
/// report the raw comparisons between them.
///
/// Convenience overload that uses `<` for `Comparable` elements.
///
/// - Note: The emitted comparisons respect the ascending order of the inputs.
///   When elements compare equal, a single `.shared` is produced.
///
/// ### Example
/// ```swift
/// let a = [1, 2, 4, 5]
/// let b = [2, 3, 5]
/// for c in rawSortedMerge(of: a, and: b) {
///   print(c)
/// }
/// // .exclusiveToFirst(1), .shared(2, 2), .exclusiveToSecond(3), .exclusiveToFirst(4), .shared(5, 5)
/// ```
@inlinable
public func rawSortedMerge<First, Second>(of first: First, and second: Second)
  -> SortedSetRawMergingSequence<First, Second>
where
  First: Sequence, Second: Sequence, First.Element == Second.Element,
  Second.Element: Comparable
{
  return rawSortedMerge(of: first, and: second, sortingBy: <)
}

// MARK: - Sorted Set Merge

/// A set of high-level operations that determine which elements to emit while
/// merging two sorted sequences.
///
/// - SeeAlso: ``sortedMerge(between:and:retaining:sortingBy:)``
public enum SetOperation: Int, CaseIterable {
  /// Don't vend any element.
  case nothing
  /// Vend the elements that are from only the first sequence.
  case exclusivesToFirst
  /// Vend the elements that are from only the second sequence.
  case exclusivesToSecond
  /// Vend only the elements that appear in exactly one sequence.
  case symmetricDifference
  /// Vend only the elements that appear in both sequence,
  /// using the first sequence's representative.
  case intersection
  /// Vend the elements from the first sequence.
  case first
  /// Vend the elements from the second sequence.
  case second
  /// Vend all elements,
  /// collasping shared elements to the first sequence's representative.
  case union
  /// Vend all elements,
  /// with both versions of a shared element being released.
  case sum
}

extension SetOperation {
  /// Whether results should include elements that are only present in the first sequence.
  @inlinable
  public var includesExclusivesToFirst: Bool { rawValue & 0b1001 != 0 }
  /// Whether results should include elements that are only present in the second sequence.
  @inlinable
  public var includesExclusivesToSecond: Bool { rawValue & 0b1010 != 0 }
  /// Whether results should include elements that are present in both sequences.
  @inlinable
  public var includesSharedElements: Bool { rawValue & 0b1100 != 0 }
}

/// A lazy sequence that emits elements from the two given inputs
/// sorted along the given predicate
/// according to the given set operation (*e.g.*, union, intersection).
///
/// The merged output is also sorted along the given predicate.
/// Vended elements from the same source sequence retain their relative order in
/// the merged output.
///
/// When `.sum` is the operation,
/// a shared element has both of its representative elements
/// vended consecutively,
/// with the one from the first source sequence vended first.
/// The other operations that vend shared elements only use one representative.
public struct SortedSetMergingSequence<First: Sequence, Second: Sequence>
where First.Element == Second.Element {
  let firstBase: First
  let secondBase: Second
  let operation: SetOperation
  let areInIncreasingOrder: (First.Element, Second.Element) -> Bool
}

extension SortedSetMergingSequence: LazySequenceProtocol {
  public struct Iterator: IteratorProtocol {
    var rawIterator: SortedSetRawMergingSequence<First, Second>.Iterator
    let permitExclusivesToFirst: Bool
    let permitExclusivesToSecond: Bool
    let maxSharedElementsAllowed: Int

    fileprivate var cache: Second.Element?

    public mutating func next() -> First.Element? {
      if let secondOfShared = cache {
        cache = nil
        return secondOfShared
      }
      while let rawResult = rawIterator.next() {
        switch rawResult {
        case .exclusiveToFirst(let first) where permitExclusivesToFirst:
          return first
        case .exclusiveToSecond(let second) where permitExclusivesToSecond:
          return second
        case .shared(let first, let second) where maxSharedElementsAllowed > 0:
          if maxSharedElementsAllowed > 1 {
            cache = second
            return first
          } else {
            return !permitExclusivesToFirst && permitExclusivesToSecond
              ? second : first
          }
        case .exclusiveToFirst, .exclusiveToSecond, .shared:
          continue
        }
      }
      return nil
    }
  }

  public func makeIterator() -> Iterator {
    return .init(
      rawIterator: SortedSetRawMergingSequence(
        firstBase: firstBase,
        secondBase: secondBase,
        areInIncreasingOrder: areInIncreasingOrder
      ).makeIterator(),
      permitExclusivesToFirst: operation.includesExclusivesToFirst,
      permitExclusivesToSecond: operation.includesExclusivesToSecond,
      maxSharedElementsAllowed: operation == .sum
        ? 2 : operation == .union ? 1 : 0
    )
  }

  public var underestimatedCount: Int {
    switch operation {
    case .nothing:
      0
    case .exclusivesToFirst:
      Swift.min(
        firstBase.underestimatedCount - secondBase.underestimatedCount,
        0
      )
    case .exclusivesToSecond:
      Swift.min(
        secondBase.underestimatedCount - firstBase.underestimatedCount,
        0
      )
    case .symmetricDifference:
      abs(firstBase.underestimatedCount - secondBase.underestimatedCount)
    case .intersection:
      0
    case .first:
      firstBase.underestimatedCount
    case .second:
      secondBase.underestimatedCount
    case .union:
      Swift.max(firstBase.underestimatedCount, secondBase.underestimatedCount)
    case .sum:
      firstBase.underestimatedCount + secondBase.underestimatedCount
    }
  }
}

/// Creates a lazy sequence that performs a set-like merge of
/// the two given sequences sorted along the given predicate,
/// yielding the elements selected by the given desired result.
///
/// - Parameters:
///   - first: The first sorted input sequence.
///   - second: The second sorted input sequence.
///   - subset: The set operation that controls which elements are emitted.
///   - areInIncreasingOrder: A strict ordering predicate shared by both inputs.
/// - Returns: A lazy sequence of elements from `first` and/or `second`.
///
/// - SeeAlso: ``SetOperation``
///
/// ### Examples
/// ```swift
/// let a = [5, 4, 2, 1]
/// let b = [5, 3, 2]
///
/// // Union: [5, 4, 3, 2, 1]
/// let unionSeq = sortedMerge(between: a, and: b, retaining: .union, sortingBy: >)
/// print(Array(unionSeq))
///
/// // Intersection: [5, 2]
/// let intersectionSeq = sortedMerge(between: a, and: b, retaining: .intersection, sortingBy: >)
/// print(Array(intersectionSeq))
///
/// // Symmetric difference: [4, 3, 1]
/// let symDiffSeq = sortedMerge(between: a, and: b, retaining: .symmetricDifference, sortingBy: >)
/// print(Array(symDiffSeq))
///
/// // Sum (multiset-style): shared elements appear twice -> [5, 5, 4, 3, 2, 2, 1]
/// let sumSeq = sortedMerge(between: a, and: b, retaining: .sum, sortingBy: >)
/// print(Array(sumSeq))
/// ```
public func sortedMerge<First, Second>(
  between first: First,
  and second: Second,
  retaining subset: SetOperation,
  sortingBy areInIncreasingOrder:
    @escaping (First.Element, Second.Element) -> Bool
)
  -> SortedSetMergingSequence<First, Second>
where First: Sequence, Second: Sequence, First.Element == Second.Element {
  return .init(
    firstBase: first,
    secondBase: second,
    operation: subset,
    areInIncreasingOrder: areInIncreasingOrder
  )
}

/// Creates a lazy sequence that performs a set-like merge of
/// the two given sorted sequences,
/// yielding the elements selected by the given desired result.
///
/// Convenience overload that uses `<` for `Comparable` elements.
///
/// - Note: The output is in ascending order. For shared elements, behavior is
///   controlled by `subset`
///   (e.g., `.union` once, `.sum` twice, `.intersection` once).
///
/// ### Examples
/// ```swift
/// let a = [1, 2, 4, 5]
/// let b = [2, 3, 5]
/// print(Array(sortedMerge(between: a, and: b, retaining: .union)))            // [1, 2, 3, 4, 5]
/// print(Array(sortedMerge(between: a, and: b, retaining: .intersection)))     // [2, 5]
/// print(Array(sortedMerge(between: a, and: b, retaining: .symmetricDifference))) // [1, 3, 4]
/// print(Array(sortedMerge(between: a, and: b, retaining: .sum)))              // [1, 2, 2, 3, 4, 5, 5]
/// ```
@inlinable
public func sortedMerge<First, Second>(
  between first: First,
  and second: Second,
  retaining subset: SetOperation
)
  -> SortedSetMergingSequence<First, Second>
where
  First: Sequence, Second: Sequence, First.Element == Second.Element,
  Second.Element: Comparable
{
  return sortedMerge(
    between: first,
    and: second,
    retaining: subset,
    sortingBy: <
  )
}

// MARK: - Sorted Set Merging Degree of Overlap

/// Flags describing whether a given kind of overlap must or must not occur
/// between two sequences during a sorted merge.
///
/// - SeeAlso: ``doesSortedMerger(of:and:haveExclusivesToFirst:haveExclusivesToSecond:haveSharedElements:sortingBy:)``
public enum SetMergerOverlapFlags: Int, CaseIterable {
  /// Merged sequences cannot have any element matching the category.
  case mustBeAbsent = -1
  /// Ignore the category when checking results.
  case doNotCare
  /// Merged sequences must have at least one element matching the category.
  case mustBePresent
}

/// Checks whether a merge between the two given sequences
/// sorted along the given predicate will contain certain
/// kinds of overlap (exclusives or shared elements).
///
/// This walks both inputs lazily until it can determine the answer.
///
/// - Parameters:
///   - first: The first sorted input sequence.
///   - second: The second sorted input sequence.
///   - haveExclusivesToFirst: Requirement for elements that appear only in
///       `first`.
///   - haveExclusivesToSecond: Requirement for elements that appear only in
///       `second`.
///   - haveSharedElements: Requirement for elements present in both sequences.
///   - areInIncreasingOrder: The strict ordering predicate used by both inputs.
/// - Returns: `true` if the merge satisfies all requirements;
///     otherwise `false`.
///
/// - SeeAlso: ``SetMergerOverlapFlags``
///
/// ### Example
/// ```swift
/// let a = [5, 4, 2, 1]
/// let b = [5, 3, 2]
/// let hasShared = doesSortedMerger(
///   of: a,
///   and: b,
///   haveExclusivesToFirst: .doNotCare,
///   haveExclusivesToSecond: .doNotCare,
///   haveSharedElements: .mustBePresent,
///   sortingBy: >)
/// // hasShared == true
/// ```
public func doesSortedMerger<First, Second>(
  of first: First,
  and second: Second,
  haveExclusivesToFirst: SetMergerOverlapFlags,
  haveExclusivesToSecond: SetMergerOverlapFlags,
  haveSharedElements: SetMergerOverlapFlags,
  sortingBy areInIncreasingOrder: (First.Element, Second.Element) -> Bool
) -> Bool
where First: Sequence, Second: Sequence, First.Element == Second.Element {
  return withoutActuallyEscaping(areInIncreasingOrder) {
    var exclusiveToFirstCount = 0
    var exclusiveToSecondCount = 0
    var sharedCount = 0
    for find in SortedSetRawMergingSequence(
      firstBase: first,
      secondBase: second,
      areInIncreasingOrder: $0
    ) {
      switch find {
      case .exclusiveToFirst(let first):
        guard haveExclusivesToFirst != .mustBeAbsent else { return false }

        exclusiveToFirstCount += 1
      case .exclusiveToSecond(let second):
        guard haveExclusivesToSecond != .mustBeAbsent else { return false }

        exclusiveToSecondCount += 1
      case .shared(let first, let second):
        guard haveSharedElements != .mustBeAbsent else { return false }

        sharedCount += 1
      }
    }
    guard haveExclusivesToFirst != .mustBePresent || exclusiveToFirstCount > 0,
      haveExclusivesToSecond != .mustBePresent || exclusiveToSecondCount > 0,
      haveSharedElements != .mustBePresent || sharedCount > 0
    else {
      return false
    }

    return true
  }
}

/// Checks whether a merge between the two given sorted sequences will contain
/// certain kinds of overlap (exclusives or shared elements).
///
/// Convenience overload that uses `<` for `Comparable` elements.
///
/// - Note: Evaluation is lazy; the function stops as soon as it can decide the
///   answer based on the requirements.
///
/// ### Example
/// ```swift
/// let a = [1, 2, 4, 5]
/// let b = [2, 3, 5]
/// let ok = doesSortedMerger(
///   of: a,
///   and: b,
///   haveExclusivesToFirst: .mustBePresent,
///   haveExclusivesToSecond: .mustBePresent,
///   haveSharedElements: .mustBePresent)
/// // ok == true
/// ```
@inlinable
public func doesSortedMerger<First, Second>(
  of first: First,
  and second: Second,
  haveExclusivesToFirst: SetMergerOverlapFlags,
  haveExclusivesToSecond: SetMergerOverlapFlags,
  haveSharedElements: SetMergerOverlapFlags
) -> Bool
where
  First: Sequence, Second: Sequence, First.Element == Second.Element,
  Second.Element: Comparable
{
  return doesSortedMerger(
    of: first,
    and: second,
    haveExclusivesToFirst: haveExclusivesToFirst,
    haveExclusivesToSecond: haveExclusivesToSecond,
    haveSharedElements: haveSharedElements,
    sortingBy: <
  )
}
