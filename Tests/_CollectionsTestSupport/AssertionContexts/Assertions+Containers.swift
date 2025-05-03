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

import Future

@available(SwiftStdlib 6.2, *)
public func expectContainersWithEquivalentElements<
  C1: Container & ~Copyable & ~Escapable,
  C2: Container & ~Copyable & ~Escapable
>(
  _ left: borrowing C1,
  _ right: borrowing C2,
  by areEquivalent: (borrowing C1.Element, borrowing C2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  if left.elementsEqual(right, by: areEquivalent) { return }
  _expectFailure(
    "Containers do not have equivalent elements",
    message, trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.2, *)
public func expectContainersWithEqualElements<
  Element: Equatable,
  C1: Container<Element> & ~Copyable & ~Escapable,
  C2: Container<Element> & ~Copyable & ~Escapable,
>(
  _ left: borrowing C1,
  _ right: borrowing C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  if left.elementsEqual(right) { return }
  _expectFailure(
    "Containers do not have equal elements",
    message, trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.2, *)
public func expectContainerContents<
  Element: Equatable,
  C1: Container<Element> & ~Copyable & ~Escapable,
  C2: Collection<Element>,
>(
  _ left: borrowing C1,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  var i = left.startIndex
  var it = right.makeIterator()
  while i < left.endIndex {
    let a = left[i]
    guard let b = it.next() else {
      _expectFailure(
        "Container is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    }
    guard a == b else {
      _expectFailure(
        "'\(a)' at index \(i) is not equal to '\(b)'",
        message, trapping: trapping, file: file, line: line)
      return
    }
    left.formIndex(after: &i)
  }
  guard it.next() == nil else {
    _expectFailure(
      "Container is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 6.2, *)
public func expectContainerContents<
  C1: Container & ~Copyable & ~Escapable,
  C2: Collection,
>(
  _ left: borrowing C1,
  equivalentTo right: C2,
  by areEquivalent: (borrowing C1.Element, C2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  var i = left.startIndex
  var it = right.makeIterator()
  while i < left.endIndex {
    guard let b = it.next() else {
      _expectFailure(
        "Container is longer than expected",
        message, trapping: trapping, file: file, line: line)
      return
    }
    guard areEquivalent(left[i], b) else {
      _expectFailure(
        "Element at index \(i) is not equal to '\(b)'",
        message, trapping: trapping, file: file, line: line)
      return
    }
    left.formIndex(after: &i)
  }
  guard it.next() == nil else {
    _expectFailure(
      "Container is shorter than expected",
      message, trapping: trapping, file: file, line: line)
    return
  }
}
