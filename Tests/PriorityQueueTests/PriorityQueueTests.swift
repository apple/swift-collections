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

final class PriorityQueueTests: CollectionTestCase {
    
    func test_enqueue(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min)
        minQueue.enqueue(value: 5)
        minQueue.enqueue(value: 26)
        minQueue.enqueue(value: 12)
        minQueue.enqueue(value: 23)
        minQueue.enqueue(value: 12)
        expectEqual(minQueue.size(), 5)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max)
        maxQueue.enqueue(value: 5)
        maxQueue.enqueue(value: 26)
        maxQueue.enqueue(value: 12)
        maxQueue.enqueue(value: 23)
        maxQueue.enqueue(value: 12)
        expectEqual(maxQueue.size(), 5)
    }
    
    func test_dequeue(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min)
        minQueue.enqueue(value: 7)
        minQueue.enqueue(value: 2)
        minQueue.enqueue(value: 8)
        minQueue.enqueue(value: 10)
        minQueue.enqueue(value: 29)
        minQueue.enqueue(value: 34)
        minQueue.enqueue(value: 67)
        minQueue.enqueue(value: 88)
        minQueue.enqueue(value: 72)
        minQueue.enqueue(value: 59)
        minQueue.enqueue(value: 26)
        minQueue.enqueue(value: 10674)
        minQueue.enqueue(value: 39)
        minQueue.enqueue(value: 2)
        var calculatedOutput = ""
        while(!minQueue.isEmpty()){
            calculatedOutput += "\(minQueue.dequeue()!) "
        }
        var expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max)
        maxQueue.enqueue(value: 7)
        maxQueue.enqueue(value: 2)
        maxQueue.enqueue(value: 8)
        maxQueue.enqueue(value: 10)
        maxQueue.enqueue(value: 29)
        maxQueue.enqueue(value: 34)
        maxQueue.enqueue(value: 67)
        maxQueue.enqueue(value: 88)
        maxQueue.enqueue(value: 72)
        maxQueue.enqueue(value: 59)
        maxQueue.enqueue(value: 26)
        maxQueue.enqueue(value: 10674)
        maxQueue.enqueue(value: 39)
        maxQueue.enqueue(value: 2)
        calculatedOutput = ""
        while(!maxQueue.isEmpty()){
            calculatedOutput += "\(maxQueue.dequeue()!) "
        }
        expectedOutput = "10674 88 72 67 59 39 34 29 26 10 8 7 2 2 "
        expectEqual(expectedOutput, calculatedOutput)
    }
    
    func test_isFull(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.isFull(), false)
        minQueue.enqueue(value: 55);
        minQueue.enqueue(value: 24)
        minQueue.enqueue(value: 69)
        minQueue.enqueue(value: 32)
        expectEqual(minQueue.isFull(), false)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.isFull(), false)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.isFull(), false)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max);
        expectEqual(maxQueue.isFull(), false)
        maxQueue.enqueue(value: 55);
        maxQueue.enqueue(value: 24)
        maxQueue.enqueue(value: 69)
        maxQueue.enqueue(value: 32)
        expectEqual(maxQueue.isFull(), false)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.isFull(), false)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.isFull(), false)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }

    func test_isEmpty(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.isEmpty(), true)
        minQueue.enqueue(value: 55);
        minQueue.enqueue(value: 24)
        minQueue.enqueue(value: 69)
        minQueue.enqueue(value: 32)
        expectEqual(minQueue.isEmpty(), false)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.isEmpty(), false)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.isEmpty(), true)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max);
        expectEqual(maxQueue.isEmpty(), true)
        maxQueue.enqueue(value: 55);
        maxQueue.enqueue(value: 24)
        maxQueue.enqueue(value: 69)
        maxQueue.enqueue(value: 32)
        expectEqual(maxQueue.isEmpty(), false)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.isEmpty(), false)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.isEmpty(), true)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_size(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.size(), 0)
        minQueue.enqueue(value: 55);
        minQueue.enqueue(value: 24)
        minQueue.enqueue(value: 69)
        minQueue.enqueue(value: 32)
        expectEqual(minQueue.size(), 4)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.size(), 2)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.size(), 0)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max);
        expectEqual(maxQueue.size(), 0)
        maxQueue.enqueue(value: 55);
        maxQueue.enqueue(value: 24)
        maxQueue.enqueue(value: 69)
        maxQueue.enqueue(value: 32)
        expectEqual(maxQueue.size(), 4)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.size(), 2)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.size(), 0)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_getPriorityQueueType(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min);
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.getPriorityQueueType(), .min)
        minQueue.enqueue(value: 55)
        minQueue.enqueue(value: 63)
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.getPriorityQueueType(), .min)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max);
        expectEqual(maxQueue.getPriorityQueueType(), .max)
        maxQueue.enqueue(value: 55)
        maxQueue.enqueue(value: 63)
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.getPriorityQueueType(), .max)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }
    
    func test_priorityQueueSequenceConformance(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min)
        minQueue.enqueue(value: 7)
        minQueue.enqueue(value: 2)
        minQueue.enqueue(value: 8)
        minQueue.enqueue(value: 10)
        minQueue.enqueue(value: 29)
        minQueue.enqueue(value: 34)
        minQueue.enqueue(value: 67)
        minQueue.enqueue(value: 88)
        minQueue.enqueue(value: 72)
        minQueue.enqueue(value: 59)
        minQueue.enqueue(value: 26)
        minQueue.enqueue(value: 10674)
        minQueue.enqueue(value: 39)
        minQueue.enqueue(value: 2)
        var calculatedOutput = ""
        for value in minQueue{
            calculatedOutput += "\(value) "
        }
        var expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        minQueue.enqueue(value: 102)
        minQueue.enqueue(value: 124)
        calculatedOutput = ""
        for value in minQueue{
            calculatedOutput += "\(value) "
        }
        //expectedOutput should be updated with new values
        expectedOutput = "2 2 7 8 10 26 29 34 39 59 67 72 88 102 124 10674 "
        expectEqual(expectedOutput, calculatedOutput)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max)
        maxQueue.enqueue(value: 7)
        maxQueue.enqueue(value: 2)
        maxQueue.enqueue(value: 8)
        maxQueue.enqueue(value: 10)
        maxQueue.enqueue(value: 29)
        maxQueue.enqueue(value: 34)
        maxQueue.enqueue(value: 67)
        maxQueue.enqueue(value: 88)
        maxQueue.enqueue(value: 72)
        maxQueue.enqueue(value: 59)
        maxQueue.enqueue(value: 26)
        maxQueue.enqueue(value: 10674)
        maxQueue.enqueue(value: 39)
        maxQueue.enqueue(value: 2)
        calculatedOutput = ""
        for value in maxQueue{
            calculatedOutput += "\(value) "
        }
        expectedOutput = "10674 88 72 67 59 39 34 29 26 10 8 7 2 2 "
        expectEqual(expectedOutput, calculatedOutput)
        minQueue.enqueue(value: 102)
        minQueue.enqueue(value: 124)
        calculatedOutput = ""
        for value in maxQueue{
            calculatedOutput += "\(value) "
        }
        //expectedOutput should be updated with new values
        expectedOutput = "10674 124 102 88 72 67 59 39 34 29 26 10 8 7 2 2 "
    }
    
    func test_peek(){
        var minQueue = PriorityQueue<Int>(priorityQueueType: HeapType.min)
        var intermediateValues:Int //to prevent a lot of warnings
        expectEqual(minQueue.peek(), nil)
        minQueue.enqueue(value: 5)
        minQueue.enqueue(value: 26)
        minQueue.enqueue(value: 12)
        minQueue.enqueue(value: 23)
        minQueue.enqueue(value: 12)
        expectEqual(minQueue.peek(), 5)
        intermediateValues = minQueue.dequeue()!
        intermediateValues = minQueue.dequeue()!
        expectEqual(minQueue.peek(), 12)
        
        var maxQueue = PriorityQueue<Int>(priorityQueueType: HeapType.max)
        expectEqual(maxQueue.peek(), nil)
        maxQueue.enqueue(value: 5)
        maxQueue.enqueue(value: 26)
        maxQueue.enqueue(value: 12)
        maxQueue.enqueue(value: 23)
        maxQueue.enqueue(value: 12)
        expectEqual(maxQueue.peek(), 26)
        intermediateValues = maxQueue.dequeue()!
        intermediateValues = maxQueue.dequeue()!
        expectEqual(maxQueue.peek(), 12)
        
        //to prevent warnings of variable written to but not read
        intermediateValues = 0
        expectEqual(intermediateValues, 0)
    }

}
