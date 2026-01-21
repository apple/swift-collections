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
@available(SwiftStdlib 5.0, *)
public func expectIterablesWithEquivalentElements<
  I1: Iterable & ~Copyable & ~Escapable,
  I2: Iterable & ~Copyable & ~Escapable
>(
  _ left: borrowing I1,
  _ right: borrowing I2,
  by areEquivalent: (borrowing I1.Element, borrowing I2.Element) -> Bool,
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
  I1: Iterable<Element> & ~Copyable & ~Escapable,
  I2: Iterable<Element> & ~Copyable & ~Escapable,
>(
  _ left: borrowing I1,
  _ right: borrowing I2,
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
  I1: Iterable<Element> & ~Copyable & ~Escapable,
  C2: Collection<Element>,
>(
  _ left: borrowing I1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var it1 = left.startBorrowIteration()
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
  I1: Iterable & ~Copyable & ~Escapable,
  C2: Collection,
>(
  _ left: borrowing I1,
  equivalentTo right: C2,
  by areEquivalent: (borrowing I1.Element, C2.Element) -> Bool,
  printer: (borrowing I1.Element) -> String,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var it1 = left.startBorrowIteration()
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
