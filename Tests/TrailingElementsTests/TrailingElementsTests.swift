import Testing
import TrailingElementsModule

struct Point {
    var x: Int
    var y: Int
}

struct Coordinates {
    var numCoordinates: Int
}

extension Coordinates: TrailingElements {
    typealias Element = Point
    var trailingCount: Int { numCoordinates }
}

@Suite("Trailing elements tests")
struct TrailingElementsTests {
    @Test func simpleCoordinates() async throws {
        var coords = IntrusiveManagedBuffer(header: Coordinates(numCoordinates: 3)) { outputSpan in
            outputSpan.append(Point(x: 1, y: 2))
            outputSpan.append(Point(x: 2, y: 3))
            outputSpan.append(Point(x: 3, y: 4))
        }

        #expect(coords[0].x == 1)
        #expect(coords[1].x == 2)
        #expect(coords[2].x == 3)

        coords[1].y = 17
        #expect(coords[1].y == 17)
    }

    @Test func repeatingInit() async throws {
        var coords = IntrusiveManagedBuffer(header: Coordinates(numCoordinates: 3), repeating: Point(x: 1, y: 1))

        #expect(coords[0].x == 1)
        #expect(coords[1].x == 1)
        #expect(coords[2].x == 1)

        coords[1].x = 17
        #expect(coords[0].x == 1)
        #expect(coords[1].x == 17)
        #expect(coords[2].x == 1)
    }

    @Test func temporaryCoordinates() async throws {
        IntrusiveManagedBuffer.withTemporaryValue(header: Coordinates(numCoordinates: 3)) { outputSpan in
            outputSpan.append(Point(x: 1, y: 2))
            outputSpan.append(Point(x: 2, y: 3))
            outputSpan.append(Point(x: 3, y: 4))
        } body: { coords in
            #expect(coords[0].x == 1)
            #expect(coords[1].x == 2)
            #expect(coords[2].x == 3)
        }
    }
}
