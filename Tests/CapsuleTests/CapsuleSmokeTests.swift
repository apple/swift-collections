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
}
