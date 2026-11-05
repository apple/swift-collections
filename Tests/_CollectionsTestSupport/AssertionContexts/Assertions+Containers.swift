//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
#endif
import ContainersPreview

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterableContents<
  Element: Equatable,
  C2: Collection<Element>,
>(
  _ left: borrowing Span<Element>,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var i = 0
  var it = right.makeIterator()
  while i < left.count {
    let a = left[i]
    guard let b = it.next() else {
      _expectFailure(
        "\(left.testDescription) is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    }
    guard a == b else {
      _expectFailure(
        "'\(a)' at index \(i) is not equal to '\(b)'",
        message, trapping: trapping, file: file, line: line)
      return
    }
    i += 1
  }
  guard it.next() == nil else {
    _expectFailure(
      "\(left.testDescription) is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterableContents<
  E1,
  C2: Collection,
>(
  _ left: borrowing Span<E1>,
  equivalentTo right: C2,
  by areEquivalent: (borrowing E1, C2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  expectIterableContents(
    left,
    equivalentTo: right,
    by: areEquivalent,
    printer: { "\($0)" },
    message(),
    trapping: trapping,
    file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterableContents<
  E1: ~Copyable,
  C2: Collection,
>(
  _ left: borrowing Span<E1>,
  equivalentTo right: C2,
  by areEquivalent: (borrowing E1, C2.Element) -> Bool,
  printer: (borrowing E1) -> String,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var i = 0
  var it = right.makeIterator()
  while i < left.count {
    guard let b = it.next() else {
      _expectFailure(
        "\(left.testDescription) is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    }
    guard areEquivalent(left[i], b) else {
      _expectFailure(
        "Element at index \(i) is not equal to '\(b)'",
        message, trapping: trapping, file: file, line: line)
      return
    }
    i += 1
  }
  guard it.next() == nil else {
    _expectFailure(
      "\(left.testDescription) is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}

#if compiler(>=6.4)
/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 6.4, *)
public func expectIterablePayloads<
  Payload: Equatable,
  E1: Iterable<LifetimeTrackedStruct<Payload>, E> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
  E,
>(
  _ left: borrowing E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(E) where E1.Element: ~Copyable {
  try expectBorrowingIteratorPayloads(
    left.makeBorrowingIterator(),
    equalTo: right,
    message(),
    trapping: trapping,
    file: file, line: line)
}

/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 6.4, *)
public func expectBorrowingIteratorPayloads<
  Payload: Equatable,
  E1: BorrowingIteratorProtocol<LifetimeTrackedStruct<Payload>, E> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
  E,
>(
  _ left: consuming E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(E) where E1.Element: ~Copyable {
  try expectBorrowingIteratorContents(
    left,
    equivalentTo: right,
    by: { $0.payload == $1 },
    printer: { "\($0.payload)" },
    message(),
    trapping: trapping,
    file: file, line: line)
}
#endif

#if compiler(>=6.4)
/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 6.4, *)
public func expectIterablePayloads<
  Payload: Equatable,
  E1: Iterable<LifetimeTracked<Payload>, E> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
  E,
>(
  _ left: borrowing E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(E) {
  try expectIterableContents(
    left,
    equivalentTo: right,
    by: { $0.payload == $1 },
    printer: { "\($0.payload)" },
    message(),
    trapping: trapping,
    file: file, line: line)
}
#endif

#if compiler(>=6.4)
/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 6.4, *)
public func expectBorrowingIteratorPayloads<
  Payload: Equatable,
  E1: BorrowingIteratorProtocol<LifetimeTracked<Payload>, E> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
  E,
>(
  _ left: consuming E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(E) {
  try expectBorrowingIteratorContents(
    left,
    equivalentTo: right,
    by: { $0.payload == $1 },
    printer: { "\($0.payload)" },
    message(),
    trapping: trapping,
    file: file, line: line)
}
#endif

#if compiler(>=6.4)
/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.4, *)
public func expectIterableContents<
  Element: Equatable,
  Failure,
  S1: Iterable<Element, Failure> & ~Copyable & ~Escapable,
  C2: Collection<Element>,
>(
  _ left: borrowing S1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(Failure) {
  try expectBorrowingIteratorContents(
    left.makeBorrowingIterator(),
    equalTo: right,
    message(),
    trapping: trapping,
    file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.4, *)
public func expectIterableContents<
  S1: Iterable & ~Copyable & ~Escapable,
  C2: Collection,
>(
  _ left: borrowing S1,
  equivalentTo right: C2,
  by areEquivalent: (borrowing S1.Element, C2.Element) -> Bool,
  printer: (borrowing S1.Element) -> String,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(S1.Failure) where S1.Element: ~Copyable {
  try expectBorrowingIteratorContents(
    left.makeBorrowingIterator(),
    equivalentTo: right,
    by: areEquivalent,
    printer: printer,
    message(),
    trapping: trapping,
    file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.4, *)
public func expectBorrowingIteratorContents<
  S1: BorrowingIteratorProtocol & ~Copyable & ~Escapable,
  C2: Collection,
>(
  _ left: consuming S1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(S1.Failure) where S1.Element == C2.Element, S1.Element: Equatable {
  try expectBorrowingIteratorContents(
    left,
    equivalentTo: right,
    by: ==,
    printer: { "\($0)" },
    message(),
    trapping: trapping,
    file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.4, *)
public func expectBorrowingIteratorContents<
  S1: BorrowingIteratorProtocol & ~Copyable & ~Escapable,
  C2: Collection,
>(
  _ left: consuming S1,
  equivalentTo right: C2,
  by areEquivalent: (borrowing S1.Element, C2.Element) -> Bool,
  printer: (borrowing S1.Element) -> String,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(S1.Failure) where S1.Element: ~Copyable {
  var it1 = left
  var it2 = right.makeIterator()
  var offset = 0
  while true {
    let span = try it1.nextSpan()
    if span.isEmpty { break }
    for i in 0 ..< span.count {
      guard let b = it2.next() else {
        _expectFailure(
          "Iterable is longer than expected",
          message, trapping: trapping, file: file, line: line)
        return
      }
      guard areEquivalent(span[i], b) else {
        _expectFailure(
          "Element at offset \(offset + i) is not equivalent to '\(b)'",
          message, trapping: trapping, file: file, line: line)
        return
      }
    }
    offset += span.count
  }
  guard it2.next() == nil else {
    _expectFailure(
      "Iterable is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}
#endif
