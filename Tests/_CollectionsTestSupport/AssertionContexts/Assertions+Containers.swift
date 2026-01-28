//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import ContainersPreview
#endif

#if compiler(>=6.2)
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 5.0, *)
public func expectIterablePayloads<
  Payload: Equatable,
  E1: BorrowingSequence<LifetimeTrackedStruct<Payload>> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
>(
  _ left: borrowing E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var it1 = left.makeBorrowingIterator()
  var it2 = right.makeIterator()
  var i = 0
  while true {
    let next1 = it1.nextSpan(maximumCount: 1)
    let next2 = it2.next()
    switch (next1.isEmpty, next2) {
    case (true, nil):
      return
    case (true, _?):
      _expectFailure(
        "Borrowing sequence is shorter than expected",
        message, trapping: trapping, file: file, line: line)
      return
    case (false, nil):
      _expectFailure(
        "Borrowing sequence is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    case (false, let b?):
      let a = next1[0].payload
      guard a == b else {
        _expectFailure(
          "Element at offset \(i) '\(a)' is not equal to '\(b)'",
          message, trapping: trapping, file: file, line: line)
        return
      }
    }
    i += 1
  }
}

/// Check if `left` contains lifetime tracked instances whose payloads equal
/// the elements in `right`.
@available(SwiftStdlib 5.0, *)
public func expectIterablePayloads<
  Payload: Equatable,
  E1: BorrowingSequence<LifetimeTracked<Payload>> & ~Copyable & ~Escapable,
  C2: Collection<Payload>,
>(
  _ left: borrowing E1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var it1 = left.makeBorrowingIterator()
  var it2 = right.makeIterator()
  var i = 0
  while true {
    let next1 = it1.nextSpan(maximumCount: 1)
    let next2 = it2.next()
    switch (next1.isEmpty, next2) {
    case (true, nil):
      return
    case (true, _?):
      _expectFailure(
        "Borrowing sequence is shorter than expected",
        message, trapping: trapping, file: file, line: line)
      return
    case (false, nil):
      _expectFailure(
        "Borrowing sequence is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    case (false, let b?):
      let a = next1[0].payload
      guard a == b else {
        _expectFailure(
          "Element at offset \(i) '\(a)' is not equal to '\(b)'",
          message, trapping: trapping, file: file, line: line)
        return
      }
    }
    i += 1
  }
}
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
public func expectIterablesWithEquivalentElements<
  S1: BorrowingSequence & ~Copyable & ~Escapable,
  S2: BorrowingSequence & ~Copyable & ~Escapable
>(
  _ left: borrowing S1,
  _ right: borrowing S2,
  by areEquivalent: (borrowing S1.Element, borrowing S2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  if left.elementsEqual(right, by: areEquivalent) { return }
  _expectFailure(
    "Containers do not have equivalent elements",
    message, trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterablesWithEqualElements<
  Element: Equatable,
  S1: BorrowingSequence<Element> & ~Copyable & ~Escapable,
  S2: BorrowingSequence<Element> & ~Copyable & ~Escapable,
>(
  _ left: borrowing S1,
  _ right: borrowing S2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  if left.elementsEqual(right) { return }
  _expectFailure(
    "Containers do not have equal elements",
    message, trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterableContents<
  Element: Equatable,
  S1: BorrowingSequence<Element> & ~Copyable & ~Escapable,
  C2: Collection<Element>,
>(
  _ left: borrowing S1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var it1 = left.makeBorrowingIterator()
  var it2 = right.makeIterator()
  while true {
    let span = it1.nextSpan()
    if span.isEmpty { break }
    for i in 0 ..< span.count {
      guard let b = it2.next() else {
        _expectFailure(
          "Container is longer than expected",
          message, trapping: trapping, file: file, line: line)
        return
      }
      guard span[i] == b else {
        _expectFailure(
          "'\(span[i])' is not equal to '\(b)'",
          message, trapping: trapping, file: file, line: line)
        return
      }
    }
  }
  guard it2.next() == nil else {
    _expectFailure(
      "Container is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectIterableContents<
  S1: BorrowingSequence & ~Copyable & ~Escapable,
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
) {
  var it1 = left.makeBorrowingIterator()
  var it2 = right.makeIterator()
  var offset = 0
  while true {
    let span = it1.nextSpan()
    if span.isEmpty { break }
    for i in 0 ..< span.count {
      guard let b = it2.next() else {
        _expectFailure(
          "Container is longer than expected",
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
      "Container is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}
#endif
#endif
