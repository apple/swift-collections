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
    XCTAssertEqual(array.reduce(into: 0, +=), span.reduce(into: 0, +=))
    
    let inline: InlineArray = [1, 2, 3, 4, 5, 6, 7, 8]
    let inlineCollected = inline.collectViaBorrowing()
    XCTAssertTrue(inline.elementsEqual(inline))
    XCTAssertTrue(inline.elementsEqual(inlineCollected))
    XCTAssertTrue(inlineCollected.elementsEqual(inline))
    // Array.elementsEqual is ambiguous:
    // XCTAssertTrue(inlineCollected.elementsEqual(inlineCollected))

    let nocopyInline: InlineArray = [
      NoncopyableInt(value: 0),
      NoncopyableInt(value: 1),
      NoncopyableInt(value: 2),
      NoncopyableInt(value: 3)
    ]
    XCTAssertTrue(nocopyInline.elementsEqual(nocopyInline))

    #if false // No BorrowingSequence conformance for UMBP yet...
    let nocopyBuffer = UnsafeMutableBufferPointer<NoncopyableInt>.allocate(capacity: nocopyInline.count)
    defer { nocopyBuffer.deallocate() }
    for i in 0..<nocopyBuffer.count {
      nocopyBuffer.initializeElement(at: i, to: NoncopyableInt(value: i))
    }
    #endif
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_ where Self: ~Copyable & ~Escapable, Element_: Copyable {
  func collectViaBorrowing() -> [Element_] {
    var borrowIterator = makeBorrowingIterator_()
    var result: [Element_] = []
    while true {
      let span = borrowIterator.nextSpan_(maximumCount: .max)
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

#else

final class BorrowingSequenceTests: XCTestCase {
  func testRequire64Compiler() {
    XCTFail("'BorrowingSequenceTests' requires a Swift 6.4 compiler.")
  }
}

#endif
#endif
