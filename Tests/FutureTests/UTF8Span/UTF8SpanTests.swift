import Future
import XCTest


class UTF8SpanTests: XCTestCase {
  // TODO: basic operations tests

  func testFoo() {
    let str = "abcdefg"
    let span = str.utf8Span
    print(span[0])
  }
}
