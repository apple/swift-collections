//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8) && DEBUG
import _CollectionsTestSupport
import XCTest
@testable import RopeModule

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
class TestBString2: CollectionTestCase {
  func testUTF8View() {
    let str = _BString(shortSample)
    checkBidirectionalCollection(str.utf8, expectedContents: shortSample.utf8)
  }
  
  func testUTF16View() {
    let str = _BString(shortSample)
    checkBidirectionalCollection(str.utf16, expectedContents: shortSample.utf16)
  }
  
  func testUnicodeScalarView() {
    let str = _BString(shortSample)
    checkBidirectionalCollection(str.unicodeScalars, expectedContents: shortSample.unicodeScalars)
  }
  
  func testCharacterView() {
    let str = _BString(shortSample)
    checkBidirectionalCollection(str, expectedContents: shortSample)
  }
  
  func testHashable_Characters() {
    let classes: [[_BString]] = [
      ["Cafe\u{301}", "Café"],
      ["Foo\u{301}\u{327}", "Foo\u{327}\u{301}"],
      ["Foo;bar", "Foo\u{37e}bar"],
    ]
    checkHashable(equivalenceClasses: classes)
  }
  
  func testHashable_Scalars() {
    let classes: [_BString] = [
      "Cafe\u{301}",
      "Café",
      "Foo\u{301}\u{327}",
      "Foo\u{327}\u{301}",
      "Foo;bar",
      "Foo\u{37e}bar",
    ]
    checkHashable(equivalenceClasses: classes.map { [$0.unicodeScalars] })
    checkHashable(equivalenceClasses: classes.map { [$0.utf8] })
    checkHashable(equivalenceClasses: classes.map { [$0.utf16] })
  }
}

#endif
