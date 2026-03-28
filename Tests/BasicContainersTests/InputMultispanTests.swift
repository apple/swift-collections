//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.2, *)
class InputMultispanTests: CollectionTestCase {
   
  // MARK: - Basic Initialization Tests
  
  func test_init_empty() {
    let multispan = InputMultispan<Int>()
    expectEqual(multispan.spanCount, 0)
    expectEqual(multispan.totalCount, 0)
    expectTrue(multispan.isEmpty)
    expectTrue(multispan.isFull)
  }
  
  func test_init_withSingleSpan() {
    var buffer = [1, 2, 3, 4, 5]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 5)
      
      expectEqual(multispan.spanCount, 1)
      expectEqual(multispan.totalCount, 5)
      expectFalse(multispan.isEmpty)
      
      expectEqual(multispan.count(at: 0), 5)
    }
  }
  
  func test_init_withMultipleSpans() {
    var buffer1 = [1, 2, 3]
    var buffer2 = [4, 5, 6, 7]
    var buffer3 = [8, 9]
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        buffer3.withUnsafeMutableBufferPointer { buf3 in
          var multispan = InputMultispan<Int>()
          multispan._append(buffer: buf1, initializedCount: 3)
          multispan._append(buffer: buf2, initializedCount: 4)
          multispan._append(buffer: buf3, initializedCount: 2)
          
          expectEqual(multispan.spanCount, 3)
          expectEqual(multispan.totalCount, 9)
          expectFalse(multispan.isEmpty)
          
          expectEqual(multispan.count(at: 0), 3)
          expectEqual(multispan.count(at: 1), 4)
          expectEqual(multispan.count(at: 2), 2)
        }
      }
    }
  }
  
  func test_init_withPartiallyInitializedSpan() {
    var buffer = [1, 2, 3, 0, 0, 0, 0]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      expectEqual(multispan.spanCount, 1)
      expectEqual(multispan.totalCount, 3)
      expectFalse(multispan.isEmpty)
    }
  }
  
  func test_init_withBuffer() {
    var buffer = [1, 2, 3, 4, 5]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      let multispan = InputMultispan(buffer: bufferPtr, initializedCount: 5)
      
      expectEqual(multispan.spanCount, 1)
      expectEqual(multispan.totalCount, 5)
      expectFalse(multispan.isEmpty)
    }
  }
  
  // MARK: - Prepend Tests
  
  func test_prepend_singleElement() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 5)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = InputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.prepend(42)
    
    expectEqual(multispan.totalCount, 1)
    expectFalse(multispan.isEmpty)
    expectEqual(multispan.count(at: 0), 1)
  }
  
  func test_prepend_multipleElements() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = InputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.prepend(3)
    multispan.prepend(2)
    multispan.prepend(1)
    
    expectEqual(multispan.totalCount, 3)
    expectEqual(multispan.count(at: 0), 3)
  }
  
  func test_prepend_acrossMultipleSpans() {
    let buf1 = UnsafeMutableBufferPointer<Int>.allocate(capacity: 3)
    buf1.initialize(repeating: 0)
    defer { buf1.deallocate() }
    let buf2 = UnsafeMutableBufferPointer<Int>.allocate(capacity: 3)
    buf2.initialize(repeating: 0)
    defer { buf2.deallocate() }
    
    var multispan = InputMultispan<Int>()
    multispan._append(buffer: buf1, initializedCount: 0)
    multispan._append(buffer: buf2, initializedCount: 0)
    
    // Fill second span
    multispan.prepend(3)
    multispan.prepend(2) 
    multispan.prepend(1)
    
    expectEqual(multispan.count(at: 1), 3)
    expectEqual(multispan.count(at: 0), 0)
    
    // Should go to first span
    multispan.prepend(5)
    multispan.prepend(4)
    
    expectEqual(multispan.count(at: 1), 3)
    expectEqual(multispan.count(at: 0), 2)
    expectEqual(multispan.totalCount, 5)
  }
  
  func test_prepend_repeating() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = InputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.prepend(repeating: 99, count: 5)
    
    expectEqual(multispan.totalCount, 5)
  }
  
  func test_prepend_moving() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = InputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    let sourcePtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 3)
    sourcePtr[0] = 100
    sourcePtr[1] = 200
    sourcePtr[2] = 300
    defer { sourcePtr.deallocate() }
    
    multispan.prepend(moving: sourcePtr)
    
    expectEqual(multispan.totalCount, 3)
  }
  
  // MARK: - Remove Tests
  
  func test_removeFirst_singleElement() {
    var buffer = [42, 99, 77]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let removed = multispan.removeFirst()
      
      expectEqual(removed, 42)
      expectEqual(multispan.totalCount, 2)
    }
  }
  
  func test_removeFirst_multipleElements() {
    var buffer = [1, 2, 3, 4, 5]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 5)
      
      multispan.removeFirst(3)
      
      expectEqual(multispan.totalCount, 2)
    }
  }
  
  func test_popFirst() {
    var buffer = [42, 99]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 2)
      
      let first = multispan.popFirst()
      expectEqual(first, 42)
      expectEqual(multispan.totalCount, 1)
      
      let second = multispan.popFirst()
      expectEqual(second, 99)
      expectEqual(multispan.totalCount, 0)
      
      let third = multispan.popFirst()
      expectNil(third)
    }
  }
  
  func test_removeAll() {
    var buffer = [1, 2, 3, 4, 5]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 5)
      
      multispan.removeAll()
      
      expectEqual(multispan.totalCount, 0)
      expectTrue(multispan.isEmpty)
    }
  }
  
  func test_removeAll_multipleSpans() {
    var buffer1 = [1, 2, 3]
    var buffer2 = [4, 5, 6, 7]
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        var multispan = InputMultispan<Int>()
        multispan._append(buffer: buf1, initializedCount: 3)
        multispan._append(buffer: buf2, initializedCount: 4)
        
        multispan.removeAll()
        
        expectEqual(multispan.totalCount, 0)
        expectEqual(multispan.count(at: 0), 0)
        expectEqual(multispan.count(at: 1), 0)
        expectTrue(multispan.isEmpty)
      }
    }
  }
  
  // MARK: - Index and Subscript Tests
  
  func test_indices() {
    var buffer = [10, 20, 30]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let startIdx = multispan.startIndex
      let endIdx = multispan.endIndex
      
      expectEqual(startIdx.bufferIndex, 0)
      expectEqual(startIdx.elementIndex, 0)
      expectEqual(endIdx.bufferIndex, 1)
      expectEqual(endIdx.elementIndex, 0)
    }
  }
  
  func test_subscript_access() {
    var buffer = [100, 200, 300]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let idx0 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
      let idx2 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 2)
      
      expectEqual(multispan[idx0], 100)
      expectEqual(multispan[idx1], 200)
      expectEqual(multispan[idx2], 300)
    }
  }
  
  func test_subscript_modify() {
    var buffer = [100, 200]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 2)
      
      let idx0 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
      
      multispan[idx0] = 999
      multispan[idx1] = 888
      
      expectEqual(multispan[idx0], 999)
      expectEqual(multispan[idx1], 888)
    }
  }
  
  func test_swapAt() {
    var buffer = [10, 20, 30]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let idx0 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx2 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 2)
      
      multispan.swapAt(idx0, idx2)
      
      expectEqual(multispan[idx0], 30)
      expectEqual(multispan[idx2], 10)
    }
  }
  
  func test_index_after() {
    var buffer = [1, 2, 3]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let idx0 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = multispan.index(after: idx0)
      
      expectEqual(idx1.bufferIndex, 0)
      expectEqual(idx1.elementIndex, 1)
    }
  }
  
  func test_index_comparison() {
    let idx0 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
    let idx1 = InputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
    let idx2 = InputMultispan<Int>.Index(bufferIndex: 1, elementIndex: 0)
    
    expectTrue(idx0 < idx1)
    expectTrue(idx1 < idx2)
    expectTrue(idx0 < idx2)
    expectFalse(idx1 < idx0)
  }
  
  // MARK: - withInputSpan Tests
  
  func test_withInputSpan_access() {
    var buffer = [1, 2, 3]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let result = multispan.withInputSpan(at: 0) { span in
        return span.count
      }
      
      expectEqual(result, 3)
    }
  }
  
  // MARK: - isFull Tests
  
  func test_isFull_empty() {
    let multispan = InputMultispan<Int>()
    expectTrue(multispan.isFull)
  }
  
  func test_isFull_withElements() {
    var buffer = [1, 2, 3]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      // Buffer is completely full - no room to prepend more elements
      expectTrue(multispan.isFull)
      expectEqual(multispan.totalFreeCapacity, 0)
    }
  }
  
  func test_isFull_partiallyFilled() {
    var buffer = [1, 2, 3, 0, 0]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      // Buffer has room for 2 more elements
      expectFalse(multispan.isFull)
      expectEqual(multispan.totalFreeCapacity, 2)
    }
  }
  
  // MARK: - Edge Cases
  
  func test_finalize() {
    var buffer = [1, 2, 3]
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = InputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      let finalizedCount = multispan.finalize(for: bufferPtr)
      expectEqual(finalizedCount, 3)
    }
  }
  
  func test_multipleSpans_complexScenario() {
    var buffer1 = [1, 2, 3]
    var buffer2 = [4, 5, 6, 7]
    var buffer3 = [8, 9, 10, 11, 12]
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        buffer3.withUnsafeMutableBufferPointer { buf3 in
          var multispan = InputMultispan<Int>()
          multispan._append(buffer: buf1, initializedCount: 3)
          multispan._append(buffer: buf2, initializedCount: 4)
          multispan._append(buffer: buf3, initializedCount: 5)
          
          expectEqual(multispan.spanCount, 3)
          expectEqual(multispan.totalCount, 12)
          expectEqual(multispan.count(at: 0), 3)
          expectEqual(multispan.count(at: 1), 4)
          expectEqual(multispan.count(at: 2), 5)
          
          // Remove some elements
          multispan.removeFirst(5)
          
          expectEqual(multispan.totalCount, 7)
          expectFalse(multispan.isEmpty)
        }
      }
    }
  }

  // MARK: - Integration with RigidArray
  
  func test_rigidArray_consumption() {
    var array = RigidArray<Int>(capacity: 10)
    array.append(1)
    array.append(2)
    array.append(3)
    array.append(4)
    array.append(5)
    
    var consumedValues: [Int] = []
    array.consume(1..<4, consumingWith: { span in
      while let value = span.popFirst() {
        consumedValues.append(value)
      }
    })
    
    expectEqual(consumedValues, [2, 3, 4])
    expectEqual(array.count, 2)
    expectEqual(array[0], 1)
    expectEqual(array[1], 5)
  }
  
  func test_rigidArray_consumeAll() {
    var array = RigidArray<Int>(capacity: 5)
    array.append(1)
    array.append(2)
    array.append(3)
    
    var consumedValues: [Int] = []
    array.consumeAll(consumingWith: { span in
      while let value = span.popFirst() {
        consumedValues.append(value)
      }
    })
    
    expectEqual(consumedValues, [1, 2, 3])
    expectEqual(array.count, 0)
  }
  
  func test_rigidArray_consumeLast() {
    var array = RigidArray<Int>(capacity: 10)
    for i in 1...5 {
      array.append(i)
    }
    
    var consumedValues: [Int] = []
    array.consumeLast(2, consumingWith: { span in
      while let value = span.popFirst() {
        consumedValues.append(value)
      }
    })
    
    expectEqual(consumedValues, [4, 5])
    expectEqual(array.count, 3)
  }
}

#endif
