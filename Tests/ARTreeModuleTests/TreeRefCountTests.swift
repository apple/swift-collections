import XCTest

@testable import ARTreeModule

private class TestBox {
  var d: String

  init(_ d: String) {
    self.d = d
  }
}

final class ARTreeRefCountTest: XCTestCase {
  func testRefCountBasic() throws {
    // TODO: Why is it 2?
    var x = TestBox("foo")
    XCTAssertEqual(CFGetRetainCount(x), 2)
    var t = ARTree<TestBox>()
    XCTAssertEqual(CFGetRetainCount(x), 2)
    t.insert(key: [10, 20, 30], value: x)
    XCTAssertEqual(CFGetRetainCount(x), 3)
    x = TestBox("bar")
    XCTAssertEqual(CFGetRetainCount(x), 2)
    x = t.getValue(key: [10, 20, 30])!
    XCTAssertEqual(CFGetRetainCount(x), 3)
    t.delete(key: [10, 20, 30])
    XCTAssertEqual(CFGetRetainCount(x), 2)
  }
}
