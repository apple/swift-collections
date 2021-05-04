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
@_spi(Testing) import Capsule

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

        expectEqual(res1.count, 2)
        expectTrue(res1.contains(CollidableInt(11, 1)))
        expectTrue(res1.contains(CollidableInt(12, 1)))


        var res2 = res1
        res2[CollidableInt(12, 1)] = nil
        expectTrue(res2.contains(CollidableInt(11, 1)))
        expectFalse(res2.contains(CollidableInt(12, 1)))

        expectEqual(res2.count, 1)
        // expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1)]), res2)


        var res3 = res1
        res3[CollidableInt(11, 1)] = nil
        expectFalse(res3.contains(CollidableInt(11, 1)))
        expectTrue(res3.contains(CollidableInt(12, 1)))

        expectEqual(res3.count, 1)
        // expectEqual(HashMap.init([CollidableInt(12, 1) : CollidableInt(12, 1)]), res3)


        var resX = res1
        resX[CollidableInt(32769)] = CollidableInt(32769)
        resX[CollidableInt(12, 1)] = nil
        expectTrue(resX.contains(CollidableInt(11, 1)))
        expectFalse(resX.contains(CollidableInt(12, 1)))
        expectTrue(resX.contains(CollidableInt(32769)))

        expectEqual(resX.count, 2)
        // expectEqual(HashMap.init([CollidableInt(11, 1) : CollidableInt(11, 1), CollidableInt(32769) : CollidableInt(32769)]), resX)
    }

    func testCompactionWhenDeletingFromHashCollisionNode2() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectEqual(res1.count, 2)
        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))


        var res2 = res1
        res2[CollidableInt(1)] = CollidableInt(1)

        expectEqual(res2.count, 3)
        expectTrue(res2.contains(CollidableInt(1)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))


        var res3 = res2
        res3[CollidableInt(32769_2, 32769)] = nil

        expectEqual(res3.count, 2)
        expectTrue(res3.contains(CollidableInt(1)))
        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))


        // expectEqual(HashMap.init([CollidableInt(1) : CollidableInt(1), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res3)
    }

    func testCompactionWhenDeletingFromHashCollisionNode3() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectEqual(res1.count, 2)
        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))


        var res2 = res1
        res2[CollidableInt(1)] = CollidableInt(1)

        expectEqual(res2.count, 3)
        expectTrue(res2.contains(CollidableInt(1)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))


        var res3 = res2
        res3[CollidableInt(1)] = nil

        expectEqual(res3.count, 2)
        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res3.contains(CollidableInt(32769_2, 32769)))


        // expectEqual(HashMap.init([CollidableInt(32769_1, 32769) : CollidableInt(32769_1, 32769), CollidableInt(32769_2, 32769) : CollidableInt(32769_2, 32769)]), res3)

    }

    func testCompactionWhenDeletingFromHashCollisionNode4() {
        let map: HashMap<CollidableInt, CollidableInt> = [:]


        var res1 = map
        res1[CollidableInt(32769_1, 32769)] = CollidableInt(32769_1, 32769)
        res1[CollidableInt(32769_2, 32769)] = CollidableInt(32769_2, 32769)

        expectEqual(res1.count, 2)
        expectTrue(res1.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res1.contains(CollidableInt(32769_2, 32769)))


        var res2 = res1
        res2[CollidableInt(5)] = CollidableInt(5)

        expectEqual(res2.count, 3)
        expectTrue(res2.contains(CollidableInt(5)))
        expectTrue(res2.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res2.contains(CollidableInt(32769_2, 32769)))


        var res3 = res2
        res3[CollidableInt(5)] = nil

        expectEqual(res3.count, 2)
        expectTrue(res3.contains(CollidableInt(32769_1, 32769)))
        expectTrue(res3.contains(CollidableInt(32769_2, 32769)))


        // expectEqual(res1, res3)
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
