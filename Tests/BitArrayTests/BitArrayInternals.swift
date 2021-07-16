//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/15/21.
//
import CollectionsTestSupport
@_spi(Testing) import BitArrayModule

func withSomeUsefulBitArrays<C: Collection>(
    _ label: String,
    ofCapacities capacities: C,
    file: StaticString = #file, line: UInt = #line,
    _ body: ([Bool]) throws -> Void
) rethrows -> Void where C.Element == Int {
    // Exhaustive tests for all deque layouts of various capacities
    for capacity in capacities {
        let allFalses = Array(repeating: false, count: capacity)
        let falseEntry = TestContext.current.push("\(label): \(allFalses)", file: file, line: line)
        do {
            defer { TestContext.current.pop(falseEntry) }
            try body(allFalses)
        }
        let allTrues = Array(repeating: true, count: capacity)
        let trueEntry = TestContext.current.push("\(label): \(allTrues)", file: file, line: line)
        do {
            defer { TestContext.current.pop(trueEntry) }
            try body(allTrues)
        }
        for _ in 0 ... 10 {
            let array = (0 ..< capacity).map { _ in Bool.random() }
            let entry = TestContext.current.push("\(label): \(array)", file: file, line: line)
            defer { TestContext.current.pop(entry) }
            try body(array)
        }
    }
}
