//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import CollectionsTestSupport
import PriorityQueue

final class HeapTests: CollectionTestCase {
    
    func test_insert() {
        var minQueue = Heap<Int>(heapType: HeapType.min)
        minQueue.insert(value: 5)
        minQueue.insert(value: 26)
        minQueue.insert(value: 12)
        minQueue.insert(value: 23)
        minQueue.insert(value: 12)
        expectEqual(minQueue.count(), 5)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max)
        maxQueue.insert(value: 5)
        maxQueue.insert(value: 26)
        maxQueue.insert(value: 12)
        maxQueue.insert(value: 23)
        maxQueue.insert(value: 12)
        expectEqual(maxQueue.count(), 5)
    }
    
    func test_remove() {
        var minQueue = Heap<Int>(heapType: HeapType.min)
        minQueue.insert(value: 7)
        minQueue.insert(value: 2)
        minQueue.insert(value: 8)
        minQueue.insert(value: 10)
        minQueue.insert(value: 29)
        minQueue.insert(value: 34)
        minQueue.insert(value: 67)
        minQueue.insert(value: 88)
        minQueue.insert(value: 72)
        minQueue.insert(value: 59)
        minQueue.insert(value: 26)
        minQueue.insert(value: 10674)
        minQueue.insert(value: 39)
        minQueue.insert(value: 2)
        var calculatedOutput = ""
        while(!minQueue.isEmpty()) {
            calculatedOutput += "\(minQueue.remove()!) "
        }
        var expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max)
        maxQueue.insert(value: 7)
        maxQueue.insert(value: 2)
        maxQueue.insert(value: 8)
        maxQueue.insert(value: 10)
        maxQueue.insert(value: 29)
        maxQueue.insert(value: 34)
        maxQueue.insert(value: 67)
        maxQueue.insert(value: 88)
        maxQueue.insert(value: 72)
        maxQueue.insert(value: 59)
        maxQueue.insert(value: 26)
        maxQueue.insert(value: 10674)
        maxQueue.insert(value: 39)
        maxQueue.insert(value: 2)
        calculatedOutput = ""
        while(!maxQueue.isEmpty()) {
            calculatedOutput += "\(maxQueue.remove()!) "
        }
        expectedOutput = "10674 88 72 67 59 39 34 29 26 10 8 7 2 2 "
        expectEqual(expectedOutput, calculatedOutput)
    }


    func test_isEmpty() {
        var minQueue = Heap<Int>(heapType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.isEmpty(), true)
        minQueue.insert(value: 55);
        minQueue.insert(value: 24)
        minQueue.insert(value: 69)
        minQueue.insert(value: 32)
        expectEqual(minQueue.isEmpty(), false)
        intermediateValues = minQueue.remove()!
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.isEmpty(), false)
        intermediateValues = minQueue.remove()!
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.isEmpty(), true)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max);
        expectEqual(maxQueue.isEmpty(), true)
        maxQueue.insert(value: 55);
        maxQueue.insert(value: 24)
        maxQueue.insert(value: 69)
        maxQueue.insert(value: 32)
        expectEqual(maxQueue.isEmpty(), false)
        intermediateValues = maxQueue.remove()!
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.isEmpty(), false)
        intermediateValues = maxQueue.remove()!
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.isEmpty(), true)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_count() {
        var minQueue = Heap<Int>(heapType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.count(), 0)
        minQueue.insert(value: 55);
        minQueue.insert(value: 24)
        minQueue.insert(value: 69)
        minQueue.insert(value: 32)
        expectEqual(minQueue.count(), 4)
        intermediateValues = minQueue.remove()!
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.count(), 2)
        intermediateValues = minQueue.remove()!
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.count(), 0)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max);
        expectEqual(maxQueue.count(), 0)
        maxQueue.insert(value: 55);
        maxQueue.insert(value: 24)
        maxQueue.insert(value: 69)
        maxQueue.insert(value: 32)
        expectEqual(maxQueue.count(), 4)
        intermediateValues = maxQueue.remove()!
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.count(), 2)
        intermediateValues = maxQueue.remove()!
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.count(), 0)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_getHeapType() {
        var minQueue = Heap<Int>(heapType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.getHeapType(), .min)
        minQueue.insert(value: 55)
        minQueue.insert(value: 63)
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.getHeapType(), .min)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max);
        expectEqual(maxQueue.getHeapType(), .max)
        maxQueue.insert(value: 55)
        maxQueue.insert(value: 63)
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.getHeapType(), .max)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_heapSequenceConformance() {
        var minQueue = Heap<Int>(heapType: HeapType.min)
        minQueue.insert(value: 7)
        minQueue.insert(value: 2)
        minQueue.insert(value: 8)
        minQueue.insert(value: 10)
        minQueue.insert(value: 29)
        minQueue.insert(value: 34)
        minQueue.insert(value: 67)
        minQueue.insert(value: 88)
        minQueue.insert(value: 72)
        minQueue.insert(value: 59)
        minQueue.insert(value: 26)
        minQueue.insert(value: 10674)
        minQueue.insert(value: 39)
        minQueue.insert(value: 2)
        var calculatedOutput = ""
        for value in minQueue {
            calculatedOutput += "\(value) "
        }
        var expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        minQueue.insert(value: 102)
        minQueue.insert(value: 124)
        calculatedOutput = ""
        for value in minQueue {
            calculatedOutput += "\(value) "
        }
        //expectedOutput should be updated with new values
        expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 102 124 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max)
        maxQueue.insert(value: 7)
        maxQueue.insert(value: 2)
        maxQueue.insert(value: 8)
        maxQueue.insert(value: 10)
        maxQueue.insert(value: 29)
        maxQueue.insert(value: 34)
        maxQueue.insert(value: 67)
        maxQueue.insert(value: 88)
        maxQueue.insert(value: 72)
        maxQueue.insert(value: 59)
        maxQueue.insert(value: 26)
        maxQueue.insert(value: 10674)
        maxQueue.insert(value: 39)
        maxQueue.insert(value: 2)
        calculatedOutput = ""
        for value in maxQueue {
            calculatedOutput += "\(value) "
        }
        expectedOutput = "10674 88 72 67 59 39 34 29 26 10 8 7 2 2 "
        expectEqual(expectedOutput, calculatedOutput)
        minQueue.insert(value: 102)
        minQueue.insert(value: 124)
        calculatedOutput = ""
        for value in maxQueue {
            calculatedOutput += "\(value) "
        }
        //expectedOutput should be updated with new values
        expectedOutput = "10674 124 102 88 72 67 59 39 34 29 26 10 8 7 2 2 "
    }
    
    func test_peek() {
        var minQueue = Heap<Int>(heapType: HeapType.min)
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.peek(), nil)
        minQueue.insert(value: 5)
        minQueue.insert(value: 26)
        minQueue.insert(value: 12)
        minQueue.insert(value: 23)
        minQueue.insert(value: 12)
        expectEqual(minQueue.peek(), 5)
        intermediateValues = minQueue.remove()!
        intermediateValues = minQueue.remove()!
        expectEqual(minQueue.peek(), 12)
        
        var maxQueue = Heap<Int>(heapType: HeapType.max)
        expectEqual(maxQueue.peek(), nil)
        maxQueue.insert(value: 5)
        maxQueue.insert(value: 26)
        maxQueue.insert(value: 12)
        maxQueue.insert(value: 23)
        maxQueue.insert(value: 12)
        expectEqual(maxQueue.peek(), 26)
        intermediateValues = maxQueue.remove()!
        intermediateValues = maxQueue.remove()!
        expectEqual(maxQueue.peek(), 12)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }

}
