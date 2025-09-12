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

struct OneByteWithPointers: TrailingElements {
    var byte: UInt8

    init(count: Int) {
        self.byte = UInt8(count)
    }

    typealias Element = OpaquePointer
    var trailingCount: Int { Int(byte) }
}

struct ManyBytesWithPointers: TrailingElements {
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

    init(count: Int) {
        self.bytes = (UInt8(count), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    typealias Element = OpaquePointer
    var trailingCount: Int { Int(bytes.0) }
}

@Suite("Trailing elements tests")
struct TrailingElementsTests {
    @Test func simpleCoordinates() {
        var coords = TrailingArray(header: Coordinates(numCoordinates: 3)) { outputSpan in
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

    @Test func repeatingInit() {
        var coords = TrailingArray(header: Coordinates(numCoordinates: 3), repeating: Point(x: 1, y: 1))

        #expect(coords[0].x == 1)
        #expect(coords[1].x == 1)
        #expect(coords[2].x == 1)

        coords[1].x = 17
        #expect(coords[0].x == 1)
        #expect(coords[1].x == 17)
        #expect(coords[2].x == 1)
    }

    @Test func temporaryCoordinates() {
        TrailingArray.withTemporaryValue(header: Coordinates(numCoordinates: 3)) { outputSpan in
            outputSpan.append(Point(x: 1, y: 2))
            outputSpan.append(Point(x: 2, y: 3))
            outputSpan.append(Point(x: 3, y: 4))
        } body: { coords in
            #expect(coords[0].x == 1)
            #expect(coords[1].x == 2)
            #expect(coords[2].x == 3)
        }
    }

    @Test(arguments: 0 ... 10)
    func underalignedByteOnHeap(count: Int) {
        var pointers = TrailingArray(header: OneByteWithPointers(count: count)) { outputSpan in
            for i in 0..<count {
                outputSpan.append(OpaquePointer(bitPattern: i+1)!)
            }
        }

        for i in 0..<count {
            #expect(pointers[i] == OpaquePointer(bitPattern: i+1))
        }

        pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
            #expect(
                UnsafeMutableRawPointer(headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)) ==
                UnsafeMutableRawPointer(elementsPtr.baseAddress))
        }
    }

    @Test(arguments: 0 ... 10)
    func underalignedByteOnStack(count: Int) {
        TrailingArray.withTemporaryValue(header: OneByteWithPointers(count: count)) { outputSpan in
            for i in 0..<count {
                outputSpan.append(OpaquePointer(bitPattern: i+1)!)
            }
        } body: { pointers in
            for i in 0..<count {
                #expect(pointers[i] == OpaquePointer(bitPattern: i+1))
            }

            pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
                #expect(
                    UnsafeMutableRawPointer(headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)) ==
                    UnsafeMutableRawPointer(elementsPtr.baseAddress))
            }
        }
    }

    @Test(arguments: 0 ... 10)
    func underalignedBytesOnHeap(count: Int) {
        var pointers = TrailingArray(header: ManyBytesWithPointers(count: count)) { outputSpan in
            for i in 0..<count {
                outputSpan.append(OpaquePointer(bitPattern: i+1)!)
            }
        }

        for i in 0..<count {
            #expect(pointers[i] == OpaquePointer(bitPattern: i+1))
        }

        pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
            #expect(
                UnsafeMutableRawPointer(headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)) ==
                UnsafeMutableRawPointer(elementsPtr.baseAddress))
        }
    }

    @Test(arguments: 0 ... 10)
    func underalignedBytesOnStack(count: Int) {
        TrailingArray.withTemporaryValue(header: ManyBytesWithPointers(count: count)) { outputSpan in
            for i in 0..<count {
                outputSpan.append(OpaquePointer(bitPattern: i+1)!)
            }
        } body: { pointers in
            for i in 0..<count {
                #expect(pointers[i] == OpaquePointer(bitPattern: i+1))
            }

            pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
                #expect(
                    UnsafeMutableRawPointer(headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)) ==
                    UnsafeMutableRawPointer(elementsPtr.baseAddress))
            }
        }
    }
}
