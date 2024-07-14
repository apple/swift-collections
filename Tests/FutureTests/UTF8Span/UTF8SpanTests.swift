@testable
import Future

import XCTest


func bitEqual(
  _ span1: UTF8Span,
  _ span2: UTF8Span
) -> Bool {
  span1.unsafeBaseAddress == span2.unsafeBaseAddress && 
  span1._countAndFlags == span2._countAndFlags
}

class UTF8SpanTests: XCTestCase {
  // TODO: basic operations tests

  func testFoo() {
    let str = "abcdefg"
    let span = str.utf8Span
    print(span[0])
  }

  func testInitForwarding() throws {
    // TODO: test we get same bits from various init pathways
    // include null-terminated ones (stripping the isNULL bit of course)
  }

  func testNullTermination() throws {
    func runTest(_ input: String) throws {
      let utf8 = input.utf8
      let nullIdx = utf8.firstIndex(of: 0) ?? utf8.endIndex
      let prefixCount = utf8.distance(
        from: utf8.startIndex, to: nullIdx)

      try Array(utf8).withUnsafeBytes {
        let nullContent = try UTF8Span(
          validatingUnsafeRaw: $0, owner: $0)
        let nullTerminated = try UTF8Span(
          validatingUnsafeRawCString: $0.baseAddress!, owner: $0)

        XCTAssertFalse(nullContent.isNullTerminatedCString)
        XCTAssertTrue(nullTerminated.isNullTerminatedCString)
        XCTAssertEqual(nullContent.count, utf8.count)
        XCTAssertEqual(nullTerminated.count, prefixCount)
      }
    }
    try runTest("abcdefg\0")
    try runTest("abc\0defg\0")
    try runTest("a🧟‍♀️bc\0defg\0")
    try runTest("a🧟‍♀️bc\0\u{301}defg")
    try runTest("abc\0\u{301}defg\0")
  }

  func testContentViews() throws {
    func runTest(_ input: String) throws {
      // For convenience, we use the API defined in
      // UTF8SpanViews.swift

      // TODO: also try input.utf8Span after compiler bug fixes

      let array = Array(input.utf8)
      let span = try UTF8Span(validating: array.storage)

      do {
        var strIter = input.makeIterator()
        var spanIter = span.characters.makeIterator()

        while let c = strIter.next() {
          guard let spanC = spanIter.next() else {
            XCTFail("Span ran out of content")
            return
          }
          XCTAssertEqual(c, spanC)
        }
        XCTAssertNil(spanIter.next())
      }

      do {
        var strIter = input.unicodeScalars.makeIterator()
        var spanIter = span.unicodeScalars.makeIterator()

        while let c = strIter.next() {
          guard let spanC = spanIter.next() else {
            XCTFail("Span ran out of content")
            return
          }
          XCTAssertEqual(c, spanC)
        }
        XCTAssertNil(spanIter.next())
      }

      // TODO: uncomment the collection style bidi tests
      // when compiler bug is fixes

      // Scalars
      do {

        var strIdx = input.unicodeScalars.startIndex
        var spanIdx = span.unicodeScalars.startIndex
        while strIdx != input.unicodeScalars.endIndex {
          XCTAssertEqual(
            input.utf8.distance(from: input.startIndex, to: strIdx),
            spanIdx.position)
          XCTAssertEqual(input.unicodeScalars[strIdx], span.unicodeScalars[spanIdx])
          input.unicodeScalars.formIndex(after: &strIdx)
          span.unicodeScalars.formIndex(after: &spanIdx)
        }
        XCTAssertEqual(spanIdx, span.unicodeScalars.endIndex)

        strIdx = input.unicodeScalars.endIndex
        spanIdx = span.unicodeScalars.endIndex
        while strIdx != input.startIndex {
          XCTAssertEqual(
            input.utf8.distance(from: input.startIndex, to: strIdx),
            spanIdx.position)
          input.unicodeScalars.formIndex(before: &strIdx)
          span.unicodeScalars.formIndex(before: &spanIdx)
          XCTAssertEqual(input.unicodeScalars[strIdx], span.unicodeScalars[spanIdx])
        }
      }

      // Characters
      do {
        var strIdx = input.startIndex
        var spanIdx = span.characters.startIndex
        while strIdx != input.endIndex {
          XCTAssertEqual(
            input.utf8.distance(from: input.startIndex, to: strIdx),
            spanIdx.position)
          XCTAssertEqual(input[strIdx], span.characters[spanIdx])
          input.formIndex(after: &strIdx)
          span.characters.formIndex(after: &spanIdx)
        }
        XCTAssertEqual(spanIdx, span.characters.endIndex)

        strIdx = input.endIndex
        spanIdx = span.characters.endIndex
        while strIdx != input.startIndex {
          XCTAssertEqual(
            input.utf8.distance(from: input.startIndex, to: strIdx),
            spanIdx.position)
          input.formIndex(before: &strIdx)
          span.characters.formIndex(before: &spanIdx)
          XCTAssertEqual(input[strIdx], span.characters[spanIdx])
        }
      }

    }

    try runTest("abc")
    try runTest("abcdefghiljkmnop")
    try runTest("abcde\0fghiljkmnop")
    try runTest("a🧟‍♀️bc\0\u{301}defg")
    try runTest("a🧟‍♀️bce\u{301}defg")
    try runTest("a🧟‍♀️bce\u{301}defg\r\n 🇺🇸")

  }

  func testCanonicalEquivalence() throws {
    // TODO: equivalence checks
    // TODO: canonically less than checks
  }

  func testMisc() throws {
    // TODO: test withUnsafeBufferPointer

  }

  func testQueries() throws {
    // TODO: test isASCII
    // TODO: test knownNFC and checks for NFC
    // TODO: test single scalar character and checks

    ///
    enum CheckLevelToPass {
      case always // Passes upon bit inspection
      case quick  // Passes under quick checking
      case full   // Passes under full checking
      case never  // Doesn't succeed under full checking

      func check(
        query: () -> Bool,
        transform: (Bool) -> Bool
      ) {
        switch self {
        case .always:
          XCTAssert(query())

        case .quick:
          XCTAssertFalse(query())
          let b = transform(true)
          XCTAssert(b && query())

        case .full:
          XCTAssertFalse(query())
          var b = transform(true)
          XCTAssertFalse(b || query())

          b = transform(false)
          XCTAssert(b && query())

        case .never:
          XCTAssertFalse(query())
          var b = transform(true)
          XCTAssertFalse(b || query())

          b = transform(false)
          XCTAssertFalse(b || query())
        }
      }
    }

    func runTest(
      _ input: String,
      isASCII: Bool,
      isNFC: CheckLevelToPass,
      isSSC: CheckLevelToPass
    ) throws {
      let array = Array(input.utf8)
      var span = try UTF8Span(validating: array.storage)

      XCTAssertEqual(isASCII, span.isASCII)

      isNFC.check(
        query: { span.isKnownNFC },
        transform: { span.checkForNFC(quickCheck: $0) }
      )

      isSSC.check(
        query: { span.isKnownSingleScalarCharacters },
        transform: { span.checkForSingleScalarCharacters(quickCheck: $0) }
      )

    }

    // FIXME: shouldn't be .full for SSC
    try runTest("abc", isASCII: true, isNFC: .always, isSSC: .quick)
    try runTest("abcde\u{301}", isASCII: false, isNFC: .never, isSSC: .never)
    try runTest("abcdè", isASCII: false, isNFC: .quick, isSSC: .quick)

    try runTest(
      "abcd日",
      isASCII: false,
      isNFC: .full, // FIXME: change to quick when we query QC properties
      isSSC: .quick)

    try runTest(
      "a강c", // NOTE: Precomposed Gang U+AC15
      isASCII: false,
      isNFC: .full, // FIXME: change to quick when we query QC properties
      isSSC: .quick)

    try runTest(
      "a강c", // NOTE: Decomposed Gang U+1100 U+1161 U+11BC
      isASCII: false,
      isNFC: .never,
      isSSC: .never)


    // TODO(perf): speed up grapheme breaking based on single scalar
    // character, speed up nextScalarStart via isASCII, ...
  }
}
