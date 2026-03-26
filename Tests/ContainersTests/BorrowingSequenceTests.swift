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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import XCTest
import ContainersPreview
import Synchronization

final class BorrowingSequenceTests: XCTestCase {
  @available(SwiftStdlib 6.2, *)
  func testBasic() {
    let array = [1, 2, 3, 4, 5, 6, 7, 8]

    let span = array.span
    let spanCollected = span.collectViaBorrowing()
    XCTAssertTrue(span.elementsEqual(span))
    XCTAssertTrue(span.elementsEqual(spanCollected))
    XCTAssertTrue(spanCollected.elementsEqual(span))
    // Array.elementsEqual is ambiguous:
    // XCTAssertTrue(spanCollected.elementsEqual(spanCollected))
    
    XCTAssertEqual(array.reduce(0, +), span.reduce(0, +))
    // Using 'borrowingReduce' to avoid ambiguity:
    XCTAssertEqual(array._borrowingReduce(into: 0, +=), span.reduce(into: 0, +=))
    
    let inline: [8 of Int] = [1, 2, 3, 4, 5, 6, 7, 8]
    let inlineCollected = inline.collectViaBorrowing()
    XCTAssertTrue(inline.elementsEqual(inline))
    XCTAssertTrue(inline.elementsEqual(inlineCollected))
    XCTAssertTrue(inlineCollected.elementsEqual(inline))
    // Array.elementsEqual is ambiguous:
    // XCTAssertTrue(inlineCollected.elementsEqual(inlineCollected))

    let nocopyInline: [8 of NoncopyableInt] = InlineArray(NoncopyableInt.init(value:))
    let nocopyBuffer = UnsafeMutableBufferPointer<NoncopyableInt>.allocate(capacity: 8)
    defer { nocopyBuffer.deallocate() }
    for i in 0..<8 {
      nocopyBuffer.initializeElement(at: i, to: NoncopyableInt(value: i))
    }
    XCTAssertTrue(nocopyInline.elementsEqual(nocopyInline))
    // No BorrowingSequence conformance for UMBP yet...
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable, Element: Copyable {
  func collectViaBorrowing() -> [Element] {
    var borrowIterator = makeBorrowingIterator()
    var result: [Element] = []
    while true {
      let span = borrowIterator.nextSpan(maximumCount: .max)
      if span.isEmpty { break }
      for i in span.indices {
        result.append(span[i])
      }
    }
    return result
  }
}

struct NoncopyableInt: ~Copyable, Equatable {
  var value: Int

  static func ==(lhs: borrowing Self, rhs: borrowing Self) -> Bool {
    lhs.value == rhs.value
  }
}

#endif
