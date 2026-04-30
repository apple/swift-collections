import BasicContainers

@available(SwiftStdlib 5.0, *)
func testEmpty() {
    let actual = RigidArray<Int>()
    let expected: [Int] = []
    breakHere(actual, expected)
}

@available(SwiftStdlib 5.0, *)
func testUnderCapacity() {
    var actual = RigidArray<Int>(capacity: 4)
    let expected = [23, 41]
    for i in expected {
        actual.append(i)
    }
    breakHere(actual, expected)
}

@available(SwiftStdlib 5.0, *)
func testFullCapacity() {
    var actual = RigidArray<Int>(capacity: 2)
    let expected = [23, 41]
    for i in expected {
        actual.append(i)
    }
    breakHere(actual, expected)
}

@main
struct FormatterTests {
    static func main() {
        if #available(SwiftStdlib 5.0, *) {
            testEmpty()
            testUnderCapacity()
            testFullCapacity()
        }
    }
}

func breakHere<A: ~Copyable, B: ~Copyable>(_ a: borrowing A, _ b: borrowing B) {}
