//===--- MutableSpanSlicing.swift -----------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Span

//MARK: slicing tests and examples
@available(macOS 9999, *)
extension MutableSpanTests {

  private func modify(_ s: inout MutableSpan<Int>) {
    s[0] += 100
  }

  public func testSliceAsExtractingFunction() {
    let count = 8
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: count)
    _ = b.initialize(fromContentsOf: 0..<count)
    defer { b.deallocate() }

    var m = MutableSpan(_unsafeElements: b)

    let first = 5
    let range = first..<count
    var suffix = m.extracting(range)
    XCTAssertEqual(suffix.count, range.count)
    XCTAssertEqual(suffix[0], first)

    //    m[0] += 100          // exclusivity violation
    //    print(m.count, m[0]) // exclusivity violation

    modify(&suffix)

    //    print(m[5])          // exclusivity violation
    //    _ = consume suffix   // exclusivity violation

    // ideally, we would like to write:
    //    m.extracting(range).update(repeating: -1)

    suffix = m.extracting(range)
    suffix.update(repeating: -1)

    XCTAssertEqual(suffix.count, range.count)
    XCTAssertTrue(suffix._elementsEqual(repeatElement(-1, count: 3)))
  }

  public func testSliceAsExtractingSubscript() {
    let count = 8
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: count)
    _ = b.initialize(fromContentsOf: 0..<count)
    defer { b.deallocate() }

    var m = MutableSpan(_unsafeElements: b)

    let first = 5
    let range = first..<count
    var suffix = m[extracting: range]
    XCTAssertEqual(suffix.count, range.count)
    XCTAssertEqual(suffix[0], first)

    //    m[0] += 100          // exclusivity violation
    //    print(m.count, m[0]) // exclusivity violation

    modify(&suffix)

    //    print(m[5])          // exclusivity violation
    //    _ = consume suffix   // exclusivity violation

    // ideally, we would like to write:
    //    m[extracting: range].update(repeating: -1)

    suffix = m[extracting: range]
    suffix.update(repeating: -1)

    XCTAssertEqual(suffix.count, range.count)
    XCTAssertTrue(suffix._elementsEqual(repeatElement(-1, count: 3)))
  }

  private func modify(_ s: inout SubMutableSpan<Int>) {
    s[s.offset] += 100
  }

  public func testSliceAsWrapperType() {
    let count = 8
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: count)
    _ = b.initialize(fromContentsOf: 0..<count)
    defer { b.deallocate() }

    var m = MutableSpan(_unsafeElements: b)

    let first = 5
    let range = first..<count
    var suffix = m[slicing: range]
    XCTAssertEqual(suffix.count, range.count)
    XCTAssertEqual(suffix[5], 5)

    //    m[0] += 100          // exclusivity violation
    //    print(m.count, m[0]) // exclusivity violation

    modify(&suffix)

    //    print(m[5])          // exclusivity violation
    //    _ = consume suffix   // exclusivity violation

    // ideally, we would like to write:
    //    m[slicing: range].update(repeating: -1)

    suffix = m[slicing: range]
    suffix.update(repeating: -1)

    XCTAssertEqual(suffix.count, range.count)
    let repeated = repeatElement(-1, count: range.count)
    XCTAssertTrue(suffix.span._elementsEqual(repeated))
  }

  public func testPassRangeArgumentInsteadOfSlicing() {
    let count = 8
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: count)
    _ = b.initialize(fromContentsOf: 0..<count)
    defer { b.deallocate() }

    var m = MutableSpan(_unsafeElements: b)

    let first = 5
    let range = first..<count
    m.update(in: range, repeating: -1)

    let mutableSuffix = m[extracting: range]
    let suffix = mutableSuffix.span

    XCTAssertEqual(suffix.count, range.count)
    let repeated = repeatElement(-1, count: range.count)
    XCTAssertTrue(suffix._elementsEqual(repeated))
  }
}
