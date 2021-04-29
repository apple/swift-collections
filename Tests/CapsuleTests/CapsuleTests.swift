//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
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
}
