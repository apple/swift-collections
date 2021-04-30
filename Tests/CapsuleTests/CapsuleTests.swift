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

final class CapsuleTests: CollectionTestCase {
    func testSubscriptAdd() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[3] = "x"
        copyAndSetTest[4] = "y"

        expectEqual(copyAndSetTest.count, 4)
        expectEqual(copyAndSetTest[1], "a")
        expectEqual(copyAndSetTest[2], "b")
        expectEqual(copyAndSetTest[3], "x")
        expectEqual(copyAndSetTest[4], "y")
    }

    func testSubscriptOverwrite() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[1] = "x"
        copyAndSetTest[2] = "y"

        expectEqual(copyAndSetTest.count, 2)
        expectEqual(copyAndSetTest[1], "x")
        expectEqual(copyAndSetTest[2], "y")
    }
    
    func testSubscriptRemove() {
        var copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]
        
        copyAndSetTest[1] = nil
        copyAndSetTest[2] = nil
        
        expectEqual(copyAndSetTest.count, 0)
        expectEqual(copyAndSetTest[1], nil)
        expectEqual(copyAndSetTest[2], nil)
    }

    private func hashPair<Key : Hashable, Value : Hashable>(_ k: Key, _ v: Value) -> Int {
        var hasher = Hasher()
        hasher.combine(k)
        hasher.combine(v)
        return hasher.finalize()
    }

    func testHashable() {
        let copyAndSetTest: HashMap<Int, String> =
            [ 1 : "a", 2 : "b" ]

        let hashPair1 = hashPair(1, "a")
        let hashPair2 = hashPair(2, "b")

        var commutativeHasher = Hasher()
        commutativeHasher.combine(hashPair1 ^ hashPair2)

        let expectedHashValue = commutativeHasher.finalize()

        expectEqual(copyAndSetTest.hashValue, expectedHashValue)

        var inoutHasher = Hasher()
        copyAndSetTest.hash(into: &inoutHasher)

        expectEqual(inoutHasher.finalize(), expectedHashValue)
    }
}
