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
final class BorrowingIteratorDropFirstTests: XCTestCase {
  let inline: InlineArray = [1, 2, 3, 4, 5]
  
  // MARK: dropFirst(_ count:)
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstZero() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(0)
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstDefault() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst()
      .copy()
      .collect()
    XCTAssertEqual(result, [2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstOne() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(1)
      .copy()
      .collect()
    XCTAssertEqual(result, [2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstSome() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(4)
      .copy()
      .collect()
    XCTAssertEqual(result, [5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstExactCount() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(5)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstExceedsCount() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(100)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }
    
  @available(SwiftStdlib 6.2, *)
  func testDropFirstEmpty() {
    let inline: InlineArray<_, Int> = []
    let result = inline.makeBorrowingIterator_()
      .dropFirst(0)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstExceedsEmpty() {
    let inline: InlineArray<_, Int> = []
    let result = inline.makeBorrowingIterator_()
      .dropFirst(100)
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }
  
  // MARK: dropFirst(while:)
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileNoneMatch() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 0 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileAllMatch() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 100 })
      .copy()
      .collect()
    XCTAssertEqual(result, [])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileSomeMatch() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(result, [5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileFirstFails() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 > 1 })
      .copy()
      .collect()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileOnlyFirstMatches() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 2 })
      .copy()
      .collect()
    XCTAssertEqual(result, [2, 3, 4, 5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testPrefixWhileLastDoesNotMatch() {
    let result = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(result, [5])
  }
  
  @available(SwiftStdlib 6.2, *)
  func testDropFirstWhileFromSpan() {
    let array = [1, 3, 5, 6, 8, 10]
    let span = array.span
    let result = span.makeBorrowingIterator_()
      .dropFirst(while: { !$0.isMultiple(of: 2) })
      .copy()
      .collect()
    XCTAssertEqual(result, [6, 8, 10])
  }
  
  // MARK: Chaining

  // FIXME: Add chaining tests
}

#else

final class BorrowingIteratorDropFirstTests: XCTestCase {
  func testRequire64Compiler() {
    XCTFail("'BorrowingIteratorDropFirstTests' requires a Swift 6.4 compiler.")
  }
}

#endif
#endif
