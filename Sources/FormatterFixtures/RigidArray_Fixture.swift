//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) YEARS Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// This file is a fixture for testing LLDB data formatters. To run the tests, see Utils/Debugger/test_formatters.py.

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
