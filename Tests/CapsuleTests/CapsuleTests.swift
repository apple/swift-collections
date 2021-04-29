import XCTest
@testable import Capsule

final class CapsuleTests: XCTestCase {
    func testSubscriptAdd() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[3] = "x"
        copyAndSetTest[4] = "y"

        XCTAssertEqual(copyAndSetTest.count, 4)
        XCTAssertEqual(copyAndSetTest[1], "a")
        XCTAssertEqual(copyAndSetTest[2], "b")
        XCTAssertEqual(copyAndSetTest[3], "x")
        XCTAssertEqual(copyAndSetTest[4], "y")
    }

    func testSubscriptOverwrite() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[1] = "x"
        copyAndSetTest[2] = "y"

        XCTAssertEqual(copyAndSetTest.count, 2)
        XCTAssertEqual(copyAndSetTest[1], "x")
        XCTAssertEqual(copyAndSetTest[2], "y")
    }
    
    func testSubscriptRemove() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[1] = nil
        copyAndSetTest[2] = nil
        
        XCTAssertEqual(copyAndSetTest.count, 0)
        XCTAssertEqual(copyAndSetTest[1], nil)
        XCTAssertEqual(copyAndSetTest[2], nil)
    }
}
