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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import XCTest

#if compiler(>=6.4)
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
#endif

@available(SwiftStdlib 6.2, *)
final class BorrowingIteratorPrefixTests: XCTestCase {
  let inline: InlineArray = [1, 2, 3, 4, 5]
  
  // MARK: prefix(_ count:)

  @available(SwiftStdlib 6.2, *)
  func testPrefixZero() {
    let result = inline.makeBorrowingIterator_()
      .prefix(0)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixOne() {
    let result = inline.makeBorrowingIterator_()
      .prefix(1)
      .copy()
      .collect()
    XCTAssertEqual(result, [1])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixSome() {
    let result = inline.makeBorrowingIterator_()
      .prefix(4)
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixExactCount() {
    let result = inline.makeBorrowingIterator_()
      .prefix(5)
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixExceedsCount() {
    let result = inline.makeBorrowingIterator_()
      .prefix(100)
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixEmpty() {
    let inline: InlineArray<_, Int> = []
    let result = inline.makeBorrowingIterator_()
      .prefix(0)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixExceedsEmpty() {
    let inline: InlineArray<_, Int> = []
    let result = inline.makeBorrowingIterator_()
      .prefix(100)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }

  // MARK: prefix(while:)

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileNoneMatch() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 0 })
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileAllMatch() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 100 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileSomeMatch() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileFirstFails() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 > 1 })
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileOnlyFirstMatches() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 2 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileLastDoesNotMatch() {
    let result = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4])
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileFromSpan() {
    let array = [2, 4, 6, 7, 8, 10]
    let span = array.span
    let result = span.makeBorrowingIterator_()
      .prefix(while: { $0.isMultiple(of: 2) })
      .copy()
      .collect()
    XCTAssertEqual(result, [2, 4, 6])

    // Note: The local 'span' binding is required:
    //     let array = [2, 4, 6, 7, 8, 10]
    //     let result = array.span.makeBorrowingIterator_()
    //                        |    `- error: lifetime-dependent value escapes its scope
    //                        `- note: it depends on the lifetime of this parent value
    //       .prefix(while: { $0.isMultiple(of: 2) })
    //        `- note: this use of the lifetime-dependent value is out of scope
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileSingleElement() {
    let inline: InlineArray = [5]
    let matching = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 10 })
      .copy()
      .collect()
    XCTAssertEqual(matching, [5])

    let nonMatching = inline.makeBorrowingIterator_()
      .prefix(while: { $0 > 10 })
      .copy()
      .collect()
    XCTAssertEqual(nonMatching, [])
  }

  // MARK: Chaining

  @available(SwiftStdlib 6.2, *)
  func testPrefixPrefix() {
    let result1 = inline.makeBorrowingIterator_()
      .prefix(4)
      .prefix(2)
      .copy()
      .collect()
    let result2 = inline.makeBorrowingIterator_()
      .prefix(2)
      .prefix(4)
      .copy()
      .collect()
    XCTAssertEqual(result1, [1, 2])
    XCTAssertEqual(result2, result1)
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileLongerPrefix() {
    let result1 = inline.makeBorrowingIterator_()
      .prefix(4)
      .prefix(while: { $0 < 3 })
      .copy()
      .collect()
    let result2 = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 3 })
      .prefix(4)
      .copy()
      .collect()
    XCTAssertEqual(result1, [1, 2])
    XCTAssertEqual(result2, result1)
  }

  @available(SwiftStdlib 6.2, *)
  func testPrefixLongerPrefixWhile() {
    let result1 = inline.makeBorrowingIterator_()
      .prefix(2)
      .prefix(while: { $0 < 5 })
      .copy()
      .collect()
    let result2 = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 5 })
      .prefix(2)
      .copy()
      .collect()
    XCTAssertEqual(result1, [1, 2])
    XCTAssertEqual(result2, result1)
  }
}

#else

final class BorrowingIteratorPrefixTests: XCTestCase {
  func testRequire64Compiler() {
    XCTFail("'BorrowingIteratorPrefixTests' requires a Swift 6.4 compiler.")
  }
}

#endif
#endif
