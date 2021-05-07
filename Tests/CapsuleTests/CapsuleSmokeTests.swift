//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsTestSupport
@testable import Capsule

final class CapsuleSmokeTests: CollectionTestCase {
    func testSubscriptAdd() {
        var map: HashMap<Int, String> = [ 1 : "a", 2 : "b" ]
        
        map[3] = "x"
        map[4] = "y"

        expectEqual(map.count, 4)
        expectEqual(map[1], "a")
        expectEqual(map[2], "b")
        expectEqual(map[3], "x")
        expectEqual(map[4], "y")
    }

    func testSubscriptOverwrite() {
        var map: HashMap<Int, String> = [ 1 : "a", 2 : "b" ]
        
        map[1] = "x"
        map[2] = "y"

        expectEqual(map.count, 2)
        expectEqual(map[1], "x")
        expectEqual(map[2], "y")
    }
    
    func testSubscriptRemove() {
        var map: HashMap<Int, String> = [ 1 : "a", 2 : "b" ]
        
        map[1] = nil
        map[2] = nil
        
        expectEqual(map.count, 0)
        expectEqual(map[1], nil)
        expectEqual(map[2], nil)
    }

    func testTriggerOverwrite1() {
        let map: HashMap<Int, String> = [ 1 : "a", 2 : "b" ]

        let _ = map
            .inserting(key: 1, value: "x") // triggers COW
            .inserting(key: 2, value: "y") // triggers COW

        var res1: HashMap<Int, String> = [:]
        res1.insert(key: 1, value: "a") // in-place
        res1.insert(key: 2, value: "b") // in-place

        var res2: HashMap<Int, String> = [:]
        res2[1] = "a" // in-place
        res2[2] = "b" // in-place

        var res3: HashMap<Int, String> = res2
        res3[1] = "x" // triggers COW
        res3[2] = "y" // in-place

        expectEqual(res2.count, 2)
        expectEqual(res2.get(1), "a")
        expectEqual(res2.get(2), "b")

        expectEqual(res3.count, 2)
        expectEqual(res3.get(1), "x")
        expectEqual(res3.get(2), "y")
    }

    func testTriggerOverwrite2() {
        var res1: HashMap<CollidableInt, String> = [:]
        res1.insert(key: CollidableInt(10, 01), value: "a") // in-place
        res1.insert(key: CollidableInt(11, 33), value: "a") // in-place
        res1.insert(key: CollidableInt(20, 02), value: "b") // in-place

        res1.insert(key: CollidableInt(10, 01), value: "x") // in-place
        res1.insert(key: CollidableInt(11, 33), value: "x") // in-place
        res1.insert(key: CollidableInt(20, 02), value: "y") // in-place

        print("Yeah!")

        var res2: HashMap<CollidableInt, String> = res1
        res2.insert(key: CollidableInt(10, 01), value: "a") // triggers COW
        res2.insert(key: CollidableInt(11, 33), value: "a") // in-place
        res2.insert(key: CollidableInt(20, 02), value: "b") // in-place

        print("Yeah!")

        expectEqual(res1.get(CollidableInt(10, 01)), "x")
        expectEqual(res1.get(CollidableInt(11, 33)), "x")
        expectEqual(res1.get(CollidableInt(20, 02)), "y")

        expectEqual(res2.get(CollidableInt(10, 01)), "a")
        expectEqual(res2.get(CollidableInt(11, 33)), "a")
        expectEqual(res2.get(CollidableInt(20, 02)), "b")

    }

    func testTriggerOverwrite3() {
        let upperBound = 1_000

        var map1: HashMap<CollidableInt, String> = [:]
        for index in 0..<upperBound {
            map1[CollidableInt(index)] = "+\(index)"
        }

        print("Populated `map1`")

        var map2: HashMap<CollidableInt, String> = map1
        for index in 0..<upperBound {
            map2[CollidableInt(index)] = "-\(index)"
        }

        print("Populated `map2`")

        expectEqual(map1.count, upperBound)
        expectEqual(map2.count, upperBound)

        for index in 0..<upperBound {
            expectEqual(map1[CollidableInt(index)], "+\(index)")
            expectEqual(map2[CollidableInt(index)], "-\(index)")
        }

        print("Tested `map1` and `map2`")

        var map3: HashMap<CollidableInt, String> = map2
        for index in 0..<upperBound {
            map3[CollidableInt(index)] = nil
        }

        print("Populated `map3`")

        // Assertion currently fails, likely due to a concurrency issue when updating
        // the `cachedSize` when deleting. The map content itself is correct, but the
        // size doesn't reflect it.
        expectEqual(map3.count, 0)
    }

    private func hashPair<Key : Hashable, Value : Hashable>(_ k: Key, _ v: Value) -> Int {
        var hasher = Hasher()
        hasher.combine(k)
        hasher.combine(v)
        return hasher.finalize()
    }

    func testHashable() {
        let map: HashMap<Int, String> = [ 1 : "a", 2 : "b" ]

        let hashPair1 = hashPair(1, "a")
        let hashPair2 = hashPair(2, "b")

        var commutativeHasher = Hasher()
        commutativeHasher.combine(hashPair1 ^ hashPair2)

        let expectedHashValue = commutativeHasher.finalize()

        expectEqual(map.hashValue, expectedHashValue)

        var inoutHasher = Hasher()
        map.hash(into: &inoutHasher)

        expectEqual(inoutHasher.finalize(), expectedHashValue)
    }

    func testCompactionWhenDeletingFromHashCollisionNode1() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(11, 1)] = CollidableInt(11, 1)
        res1[CollidableInt(12, 1)] = CollidableInt(12, 1)

        expectTrue(res1.contains(CollidableInt(11, 1)))
        expectTrue(res1.contains(CollidableInt(12, 1)))

        expectEqual(res1.count, 2)
        expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1), CollidableInt(12, 1) : CollidableInt(12, 1)]), res1)


        var res2 = res1
        res2[CollidableInt(12, 1)] = nil

        expectTrue(res2.contains(CollidableInt(11, 1)))
        expectFalse(res2.contains(CollidableInt(12, 1)))

        expectEqual(res2.count, 1)
        expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1)]), res2)


        var res3 = res1
        res3[CollidableInt(11, 1)] = nil

        expectFalse(res3.contains(CollidableInt(11, 1)))
        expectTrue(res3.contains(CollidableInt(12, 1)))

        expectEqual(res3.count, 1)
        expectEqual(HashMap.init([CollidableInt(12, 1) : CollidableInt(12, 1)]), res3)


        var resX = res1
        resX[CollidableInt(32769)] = CollidableInt(32769)
        resX[CollidableInt(12, 1)] = nil

        expectTrue(resX.contains(CollidableInt(11, 1)))
        expectFalse(resX.contains(CollidableInt(12, 1)))
        expectTrue(resX.contains(CollidableInt(32769)))

        expectEqual(resX.count, 2)
        expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1), CollidableInt(32769) : CollidableInt(32769)]), resX)


        var resY = res1
        resY[CollidableInt(32769)] = CollidableInt(32769)
        resY[CollidableInt(32769)] = nil

        expectTrue(resY.contains(CollidableInt(11, 1)))
        expectTrue(resY.contains(CollidableInt(12, 1)))
        expectFalse(resY.contains(CollidableInt(32769)))

        expectEqual(resY.count, 2)
        expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1), CollidableInt(12, 1) : CollidableInt(12, 1)]), resY)
    }

    func testCompactionWhenDeletingFromHashCollisionNode2() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res1.count, 2)
        expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res1)


        var res2 = res1
        res2[CollidableInt(1)] = CollidableInt(1)

        expectTrue(res2.contains(CollidableInt(1)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res2.count, 3)
        expectEqual(HashMap.init([CollidableInt(1) : CollidableInt(1), CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res2)


        var res3 = res2
        res3[CollidableInt(32769_2, 32769)] = nil

        expectTrue(res3.contains(CollidableInt(1)))
        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))

        expectEqual(res3.count, 2)
        expectEqual(HashMap.init([CollidableInt(1) : CollidableInt(1), CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769)]), res3)
    }

    func testCompactionWhenDeletingFromHashCollisionNode3() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res1.count, 2)
        expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res1)


        var res2 = res1
        res2[CollidableInt(1)] = CollidableInt(1)

        expectTrue(res2.contains(CollidableInt(1)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res2.count, 3)
        expectEqual(HashMap.init([CollidableInt(1) : CollidableInt(1), CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res2)


        var res3 = res2
        res3[CollidableInt(1)] = nil

        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res3.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res3.count, 2)
        expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res3)


        expectEqual(res1, res3)
    }

    func testCompactionWhenDeletingFromHashCollisionNode4() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res1.count, 2)
        expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res1)


        var res2 = res1
        res2[CollidableInt(5)] = CollidableInt(5)

        expectTrue(res2.contains(CollidableInt(5)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res2.count, 3)
        expectEqual(HashMap.init([CollidableInt(5) : CollidableInt(5), CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res2)


        var res3 = res2
        res3[CollidableInt(5)] = nil

        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res3.contains(CollidableInt(32769_2, 32769)))

        expectEqual(res3.count, 2)
        expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res3)


        expectEqual(res1, res3)
    }
}

fileprivate final class CollidableInt : CustomStringConvertible, Equatable, Hashable {
    let value: Int
    let hashValue: Int

    fileprivate init(_ value: Int) {
        self.value = value
        self.hashValue = value
    }

    fileprivate init(_ value: Int, _ hashValue: Int) {
        self.value = value
        self.hashValue = hashValue
    }

    var description: String {
        return "\(value) [hash = \(hashValue)]"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }

    static func == (lhs: CollidableInt, rhs: CollidableInt) -> Bool {
        return lhs.value == rhs.value
    }
}

final class BitmapSmokeTests: CollectionTestCase {
    func test_BitPartitionSize_isValid() {
        expectTrue(BitPartitionSize > 0)
        expectTrue((2 << (BitPartitionSize - 1)) != 0)
        expectTrue((2 << (BitPartitionSize - 1)) <= Bitmap.bitWidth)
    }
}
