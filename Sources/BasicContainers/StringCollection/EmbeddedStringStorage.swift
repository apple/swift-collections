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

import Foundation

// MARK: Primary Definition

/// A collection of `String`s packed into a single contiguous buffer.
///
/// Each string is a sequence of words.
/// The first and last elements are navigation metadata,
/// while the middle is a UTF-32 sequence of the string's codepoints in
/// Normalization Form D (NFD).
///
/// Conformances:
/// - `BidirectionalCollection`: supports forward and backward traversal,
///   with optimized element search.
/// - `Hashable`: exploiting the faster binary-level comparisons.
/// - `RangeReplaceableCollection`: supports replacing subranges with
///   new elements.
/// - `Sendable`: concurrency safety for the value-typed storage.
///
/// The subscripting operator forms an actual `String` from its
/// encoded storage on demand.
struct EmbeddedStringStorage: Hashable, Sendable {
  /// The codepoints of all the string elements, spliced together.
  var bulk: ContiguousArray<Int>
  /// The count of packed-in string elements.
  var logicalCount: Int

  init() {
    bulk = .init()
    logicalCount = 0
  }
}

// MARK: - Helpers

extension EmbeddedStringStorage {
  /// Return a length-checked normalized form of the given string.
  ///
  /// Strings are stored in UTF-32 with Normalized Form D.
  static func canonize(_ string: some StringProtocol) -> [UnicodeScalar] {
    return Array(string.decomposedStringWithCanonicalMapping.unicodeScalars)
  }

  /// Return the given string in its embedded form.
  ///
  /// A string's embedded form is a sequence of `Int`,
  /// where the very first element is the start-of-string cap,
  /// while the very last is the end-of-string cap.
  /// The values of those elements is the collection offset to the other cap.
  /// Between them is the string as Normalization Form D expressed as UTF-32.
  /// The start-of-string cap enables forward iteration in reasonable time,
  /// while the end-of-string cap enables reverse iteration.
  static func embeddedForm(of string: some StringProtocol) -> [Int] {
    let rawScalars = Self.canonize(string)
    let rawCount = rawScalars.count
    var result = [Int]()
    result.reserveCapacity(2 + rawCount)
    result.append(+rawCount + 1)
    result.append(contentsOf: rawScalars.lazy.map(\.value).map(Int.init))
    result.append(-rawCount - 1)
    return result
  }

  /// For the given top-level index,
  /// returns the bottom-level indices for the corresponding string,
  /// including the string-cap markers.
  func embeddedRange(forElementAt position: Index) -> ClosedRange<Index> {
    return position...self.bulk.index(position, offsetBy: self.bulk[position])
  }

  /// For the given top-level index,
  /// returns the bottom-level range for the corresponding string's scalars.
  func scalarRange(forElementAt position: Index) -> Range<Index> {
    let fullRange = self.embeddedRange(forElementAt: position)
    let firstScalarIndex = self.bulk.index(after: fullRange.lowerBound)
    return firstScalarIndex..<fullRange.upperBound
  }

  /// Return the first of the given indices into the embedded storage that
  /// points to the embedded form of the given string.
  ///
  /// Indices are checked in their order in `bulkIndices`,
  /// regardless of their relative values.
  /// Each index must point to a valid bottom-level element.
  func findIndex(for element: Element, among bulkIndices: some Sequence<Index>)
    -> Index?
  {
    let pattern = Self.embeddedForm(of: element)
    for bulkIndex in bulkIndices {
      if self.bulk[bulkIndex...].starts(with: pattern) {
        return bulkIndex
      }
    }
    return nil
  }
}

// MARK: - Conformances

extension EmbeddedStringStorage: BidirectionalCollection,
  RangeReplaceableCollection
{
  // MARK: Sequence

  func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return self._customIndexOfEquatableElement(element).map { $0 != nil }
  }

  // MARK: Collection

  var count: Int { self.logicalCount }
  var endIndex: Index { self.bulk.endIndex }
  var isEmpty: Bool { self.bulk.isEmpty }
  var startIndex: Index { self.bulk.startIndex }

  func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    return .some(self.findIndex(for: element, among: self.indices))
  }
  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    return .some(self.findIndex(for: element, among: self.indices.reversed()))
  }

  func index(after i: Index) -> Index {
    // For a non-empty collection,
    // `startIndex` is assumed to be a start-of-string cap,
    // the element directly before `endIndex` is assumed to be an
    // end-of-string cap.
    // For two consecutive valid elements,
    // the end cap of the first string is followed directly by the start cap of
    // the second string.
    // Determining between caps and Unicode scalars is strictly through
    // dead-reckoning.
    let embeddedRange = self.embeddedRange(forElementAt: i)
    return self.bulk.index(after: embeddedRange.upperBound)
  }

  // This is where "Element" and "Index" are defined.
  subscript(position: Int) -> String {
    let scalarRange = self.scalarRange(forElementAt: position)
    let scalars = self.bulk[scalarRange].lazy.compactMap(UnicodeScalar.init)
    return String(String.UnicodeScalarView(scalars))
  }

  // MARK: BidirectionalCollection

  func index(before i: Index) -> Index {
    let endCapOfPrevious = self.bulk.index(before: i)
    let startCapOfPrevious = self.bulk.index(
      endCapOfPrevious,
      offsetBy: self.bulk[endCapOfPrevious]
    )
    return startCapOfPrevious
  }

  // MARK: RangeReplaceableCollection

  mutating func _customRemoveLast() -> Element? {
    defer { _ = self._customRemoveLast(1) }

    return self.last
  }
  mutating func _customRemoveLast(_ n: Int) -> Bool {
    precondition(n >= 0)
    guard
      let suffixStart = self.index(
        self.endIndex,
        offsetBy: -n,
        limitedBy: self.startIndex
      )
    else {
      self.removeAll()
      return true
    }

    self.bulk.removeSubrange(suffixStart...)
    self.logicalCount -= n
    return true
  }

  mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self.bulk.removeAll(keepingCapacity: keepCapacity)
    self.logicalCount = 0
  }

  mutating func replaceSubrange<S: StringProtocol & Sendable>(
    _ subrange: some RangeExpression<Index>,
    with newElements: some Sequence<S>
  ) {
    let newEmbeddedElements = newElements.map(Self.embeddedForm(of:))
    let properRange = subrange.relative(to: self)
    let oldElementCount = self[properRange].count
    self.bulk.replaceSubrange(
      properRange,
      with: newEmbeddedElements.lazy.joined()
    )
    self.logicalCount -= oldElementCount
    self.logicalCount += newEmbeddedElements.count
  }
}
