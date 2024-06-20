import XCTest
import Future

final class ContiguousStorageTests: XCTestCase {

  func testBorrowArrayStorage() throws {

    let capacity = 10
    var a: [Int] = []
    a = Array(0..<capacity)

    let span = a.storage
    XCTAssertEqual(span.count, capacity)

    for i in span._indices {
      XCTAssertEqual(span[i], a[i])
    }

    // This should end the borrow, and the mutation should work rdar://126298676
//    _ = consume span
//    a = []
  }

  private struct Skipper: ~Escapable {
    private var span: Span<Int>

    var startIndex: Int { 0 }
    var endIndex: Int { span.count }
    func index(after i: Int) -> Int { i+2 }

    init(_ contiguous: borrowing Span<Int>) {
      span = copy contiguous
    }

    subscript(_ p: Int) -> Int { span[p] }
  }

  @inline(never)
  private func skip(
    along array: borrowing Array<Int>
  ) -> dependsOn(array) Skipper {
    Skipper(array.storage)
  }

  func testSpanWrapper() {
    let capacity = 8
    let a = Array(0..<capacity)

    let skipper = skip(along: a)
    var i = skipper.startIndex
    var s: [Int] = []
    while i < skipper.endIndex {
      s.append(skipper[i])
      i = skipper.index(after: i)
    }
    XCTAssertEqual(s, [0, 2, 4, 6])
  }
}
