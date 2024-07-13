import Future
import XCTest


class UTF8SpanTests: XCTestCase {
  // TODO: basic operations tests

  func testFoo() {
    let str = "abcdefg"
    let span = str.utf8Span
    print(span[0])
  }

  func testBar() {

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
}
