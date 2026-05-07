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

import XCTest

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview
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

    let evenInline = inline.makeBorrowingIterator_()
      .compactMap { $0.isMultiple(of: 2) ? $0 : nil }
      .collect()
    XCTAssertTrue(([2, 4, 6, 8] as InlineArray).elementsEqual(evenInline))

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
    
    // This works, can collect noncopyable values into appropriate container
    let inlineMappedToNoCopy = inline.makeBorrowingIterator_()
      .map { NoncopyableInt(value: $0) }
    
    let firstFour = inline.makeBorrowingIterator_()
      .prefix(4)
      .copy()
      .collect()
    XCTAssertEqual(firstFour, [1, 2, 3, 4])
    
    let lessThanFive = inline.makeBorrowingIterator_()
      .prefix(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(lessThanFive, [1, 2, 3, 4])
    
    let lastFour = inline.makeBorrowingIterator_()
      .dropFirst(4)
      .copy()
      .collect()
    XCTAssertEqual(lastFour, [5, 6, 7, 8])
    
    let greaterEqualToFive = inline.makeBorrowingIterator_()
      .dropFirst(while: { $0 < 5 })
      .copy()
      .collect()
    XCTAssertEqual(greaterEqualToFive, [5, 6, 7, 8])

    do {
      let array = Array(1...100)
      let span = array.span
      let subset = span.makeBorrowingIterator_()
        .prefix(25)
        .dropFirst(10)
        .prefix(while: { $0 < 20 })
        .dropFirst(while: { $0 < 15 })
        .copy()
        .collect()
      XCTAssertEqual(subset, [15, 16, 17, 18, 19])
    }
    
    // Spurious error?
    //   error: instance method 'map' requires that 'NoncopyableInt' conform to 'Copyable'
    //   points at 'BorrowingIteratorProtocol+Map.swift:24'
    //   but that extension has `Element_: ~Copyable`
    //
    // let noCopyMappedToInlineArray = nocopyInline.makeBorrowingIterator_()
    //  .map { $0.value }
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

#endif
