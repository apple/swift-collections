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

extension StringCollection {
  /// The copy-on-write wrapper for the inner collection.
  class Storage {
    /// Creates a wrapper around a copy of the given collection.
    init(_ inner: State) {
      self.state = inner
    }

    /// The nested implementation.
    var state: State
  }
}

extension StringCollection.Storage {
  struct State: Sendable {
    /// The logical count of elements stored in the collection.
    ///
    /// This improves the speed of `count` and `underestimatedCount` to O(1).
    var cachedCount: Int
    /// The string elements, broken into individual codepoints within
    /// a single contiguous buffer.
    ///
    /// Each string is encoded as a sequence of UTF-32 codepoints in
    /// Normalization Form D (NFD),
    /// with start-of-string and end-of-string caps to enable forward and
    /// backward iteration.
    /// The caps' element values are offsets to the other cap.
    ///
    /// Determining between offset markers and scalar values is done by
    /// dead reckoning.
    /// The value at `startIndex` must be a start-of-string cap,
    /// while the value at one-before-`endIndex` must be an end-of-string cap.
    /// Any values in between the caps are Unicode scalars.
    /// For two adjancent elements, the end-of-string cap of the earlier
    /// element directly abuts the start-of-string cap of the latter element.
    var innerElements: CoreStorage

    /// The implementation type for cap/scalar storage.
    typealias CoreStorage = ContiguousArray<Point>

    init() {
      self.cachedCount = 0
      self.innerElements = []
    }
    /// Creates a collection that clones the given one,
    /// except for replacing the elements at the given range,
    /// with the given sequence.
    init<S: StringProtocol>(
      clone original: StringCollection.Storage.State,
      replacing subrange: some RangeExpression<Index>,
      with newStrings: some Sequence<S>
    ) {
      let properSubrange = subrange.relative(to: original)
      let newEncodedElements = newStrings.map { Self.encode($0)[...] }
      let newElementCount = newEncodedElements.count
      var parts = [CoreStorage.SubSequence]()
      parts.reserveCapacity(2 + newElementCount)
      parts.append(original.innerElements[..<properSubrange.lowerBound])
      parts.append(contentsOf: newEncodedElements)
      parts.append(original.innerElements[properSubrange.upperBound...])
      self.cachedCount =
        original.count - original[properSubrange].count + newElementCount
      self.innerElements = .init(parts.joined())
    }

    /// The implementation type for cap & scalar values.
    typealias Point = Int
  }
}

extension StringCollection.Storage.State: BidirectionalCollection,
  RangeReplaceableCollection
{
  var count: Int { self.cachedCount }

  func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return self._customIndexOfEquatableElement(element).map { $0 != nil }
  }
  func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    return .some(self.findIndex(for: element, among: self.indices))
  }
  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    return .some(self.findIndex(for: element, among: self.indices.reversed()))
  }

  var endIndex: Index { self.innerElements.endIndex }

  func index(after i: Index) -> Index {
    return self.innerElements.index(i, offsetBy: self.innerElements[i] + 1)
  }
  func index(before i: Index) -> Index {
    let previousEndIndex = self.innerElements.index(before: i)
    return self.innerElements.index(
      i,
      offsetBy: self.innerElements[previousEndIndex] - 1
    )
  }

  var isEmpty: Bool { self.innerElements.isEmpty }

  var startIndex: Index { self.innerElements.startIndex }

  subscript(position: Int) -> String {
    let encodedRange = self.scalarRange(forElementAt: position)
    let scalars = self.innerElements[encodedRange].lazy.compactMap(
      UnicodeScalar.init
    )
    return .init(String.UnicodeScalarView(scalars))
  }

  mutating func replaceSubrange<S: StringProtocol>(
    _ subrange: some RangeExpression<Index>,
    with newElements: some Sequence<S>
  ) {
    let properSubrange = subrange.relative(to: self)
    let oldElementCount = self[properSubrange].count
    let newEncodedElements = newElements.map { Self.encode($0) }
    let newElementCount = newEncodedElements.count
    self.innerElements.replaceSubrange(
      properSubrange,
      with: newEncodedElements.joined()
    )
    self.cachedCount += newElementCount - oldElementCount
  }
}

// MARK: Helpers

extension StringCollection.Storage.State {
  /// For the given top-level index,
  /// returns the bottom-level indices for the corresponding string,
  /// including the string-cap markers.
  func embeddedRange(forElementAt position: Index) -> ClosedRange<Index> {
    let rangeEnd = self.innerElements.index(
      position,
      offsetBy: self.innerElements[position]
    )
    return position...rangeEnd
  }

  /// Returns the encoded form of the given string.
  static func encode(_ string: some StringProtocol) -> CoreStorage {
    let normalizedScalars = Array(
      string.decomposedStringWithCanonicalMapping.unicodeScalars.lazy.map(
        \.value
      ).map(Int.init)
    )
    let scalarCount = normalizedScalars.count
    var result = CoreStorage()
    result.reserveCapacity(2 + scalarCount)
    result.append(+scalarCount + 1)  // start-of-string cap
    result.append(contentsOf: normalizedScalars)
    result.append(-scalarCount - 1)  // end-of-string cap
    return result
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
    let pattern = Self.encode(element)
    for bulkIndex in bulkIndices {
      if self.innerElements[bulkIndex...].starts(with: pattern) {
        return bulkIndex
      }
    }
    return nil
  }

  /// For the given top-level index,
  /// returns the bottom-level range for the corresponding string's scalars.
  func scalarRange(forElementAt position: Index) -> Range<Index> {
    let fullRange = self.embeddedRange(forElementAt: position)
    let firstScalarIndex = self.innerElements.index(after: position)
    return firstScalarIndex..<fullRange.upperBound
  }
}
