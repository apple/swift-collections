import XCTest
@testable import OrderedCollections

final class OrderedDictionaryOptimizedUpdateTests: XCTestCase {
    func testOptimizedUpdate_NoWriteWhenEqualEquatable() {
        var dict: OrderedDictionary<String, Int> = ["a": 1, "b": 2]
        let old = dict.optimizedUpdateValue(2, forKey: "b")
        XCTAssertEqual(old, 2)
        XCTAssertEqual(dict["b"], 2)
        // No behavior change expected when same value assigned
    }

    func testOptimizedUpdate_InsertWhenMissing() {
        var dict: OrderedDictionary<String, Int> = ["a": 1]
        let old = dict.optimizedUpdateValue(3, forKey: "b")
        XCTAssertNil(old)
        XCTAssertEqual(dict["b"], 3)
        XCTAssertEqual(Array(dict.keys), ["a", "b"])
    }
}

