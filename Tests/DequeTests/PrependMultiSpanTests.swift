//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import DequeModule
import ContainersPreview
#endif

/// Regression tests for #787: `prepend(copying:)` used to pull only a single
/// span from the source, silently dropping the remaining items whenever the
/// source handed out its elements in more than one span (e.g. a ring-buffer
/// deque whose storage wraps).
final class PrependMultiSpanTests: XCTestCase {
  #if compiler(>=6.4)
  private static func makeWrappedRigidDeque() -> RigidDeque<Int> {
    // [0, 1, 2, 3], stored in two spans: slots 2-3, then slots 0-1.
    var source = RigidDeque<Int>(capacity: 4)
    source.append(-1)
    source.append(-1)
    source.removeFirst()
    source.removeFirst()
    for i in 0 ..< 4 {
      source.append(i)
    }
    return source
  }

  #if UnstableContainersPreview
  func testPrependCopyingMultiSpanRigidSource() throws {
    let source = Self.makeWrappedRigidDeque()

    var unique = UniqueDeque<Int>()
    let r1: Range<Int> = unique.prepend(copying: source)
    XCTAssertEqual(r1.lowerBound, 0)
    XCTAssertEqual(r1.count, 4)
    XCTAssertEqual(Array(unique), [0, 1, 2, 3])

    var rigid = RigidDeque<Int>(capacity: 8)
    rigid.append(9)
    let r2: Range<Int> = rigid.prepend(copying: source)
    XCTAssertEqual(r2.count, 4)
    XCTAssertEqual(Array(rigid), [0, 1, 2, 3, 9])
  }

  func testPrependCopyingRigidSetSource() throws {
    let source: RigidSet<Int> = [0, 1, 2, 3]

    var deque = UniqueDeque<Int>()
    deque.prepend(copying: source)
    XCTAssertEqual(Array(deque).sorted(), [0, 1, 2, 3])
  }
  #endif

  func testPrependCopyingIterableCollectionSource() throws {
    struct Digits: RandomAccessCollection, Iterable {
      var startIndex: Int { 0 }
      var endIndex: Int { 4 }
      subscript(i: Int) -> Int { i }
    }

    var deque = UniqueDeque<Int>()
    deque.append(9)
    let range: Range<Int> = try deque.prepend(copying: Digits())
    XCTAssertEqual(range.count, 4)
    XCTAssertEqual(Array(deque), [0, 1, 2, 3, 9])
  }
  #endif
}
