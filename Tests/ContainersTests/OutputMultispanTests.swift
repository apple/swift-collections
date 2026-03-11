//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
@testable import Collections
#else
import _CollectionsTestSupport
@testable import BasicContainers
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.2, *)
class OutputMultispanTests: CollectionTestCase {
  
  // MARK: - Basic Initialization Tests
  
  func test_init_empty() {
    let multispan = OutputMultispan<Int>()
    expectEqual(multispan.spanCount, 0)
    expectEqual(multispan.totalCount, 0)
    expectEqual(multispan.totalFreeCapacity, 0)
    expectTrue(multispan.isEmpty)
    expectTrue(multispan.isFull)
  }
  
  func test_init_withSingleSpan() {
    var buffer = [Int](repeating: 0, count: 10)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      expectEqual(multispan.spanCount, 1)
      expectEqual(multispan.totalCount, 0)
      expectEqual(multispan.totalFreeCapacity, 10)
      expectTrue(multispan.isEmpty)
      expectFalse(multispan.isFull)
      
      expectEqual(multispan.count(at: 0), 0)
      expectEqual(multispan.freeCapacity(at: 0), 10)
    }
  }
  
  func test_init_withMultipleSpans() {
    var buffer1 = [Int](repeating: 0, count: 5)
    var buffer2 = [Int](repeating: 0, count: 10)
    var buffer3 = [Int](repeating: 0, count: 7)
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        buffer3.withUnsafeMutableBufferPointer { buf3 in
          var multispan = OutputMultispan<Int>()
          multispan._append(buffer: buf1, initializedCount: 0)
          multispan._append(buffer: buf2, initializedCount: 0)
          multispan._append(buffer: buf3, initializedCount: 0)
          
          expectEqual(multispan.spanCount, 3)
          expectEqual(multispan.totalCount, 0)
          expectEqual(multispan.totalFreeCapacity, 22)
          expectTrue(multispan.isEmpty)
          expectFalse(multispan.isFull)
          
          expectEqual(multispan.count(at: 0), 0)
          expectEqual(multispan.freeCapacity(at: 0), 5)
          expectEqual(multispan.count(at: 1), 0)
          expectEqual(multispan.freeCapacity(at: 1), 10)
          expectEqual(multispan.count(at: 2), 0)
          expectEqual(multispan.freeCapacity(at: 2), 7)
        }
      }
    }
  }
  
  func test_init_withPartiallyInitializedSpan() {
    var buffer = [Int](repeating: 0, count: 10)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      // Initialize first 3 elements
      bufferPtr[0] = 100
      bufferPtr[1] = 200
      bufferPtr[2] = 300
      
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 3)
      
      expectEqual(multispan.spanCount, 1)
      expectEqual(multispan.totalCount, 3)
      expectEqual(multispan.totalFreeCapacity, 7)
      expectFalse(multispan.isEmpty)
      expectFalse(multispan.isFull)
    }
  }
  
  // MARK: - Append Tests
  
  func test_append_singleElement() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(42)
      
      expectEqual(multispan.totalCount, 1)
      expectEqual(multispan.totalFreeCapacity, 4)
      expectFalse(multispan.isEmpty)
      expectFalse(multispan.isFull)
      expectEqual(multispan.count(at: 0), 1)
    }
    expectEqual(buffer[0], 42)
  }
  
  func test_append_multipleElements() {
    var buffer = [Int](repeating: 0, count: 10)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(1)
      multispan.append(2)
      multispan.append(3)
      
      expectEqual(multispan.totalCount, 3)
      expectEqual(multispan.totalFreeCapacity, 7)
      expectEqual(multispan.count(at: 0), 3)
    }
  }
  
  func test_append_acrossMultipleSpans() {
    var buffer1 = [Int](repeating: 0, count: 3)
    var buffer2 = [Int](repeating: 0, count: 3)
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        var multispan = OutputMultispan<Int>()
        multispan._append(buffer: buf1, initializedCount: 0)
        multispan._append(buffer: buf2, initializedCount: 0)
        
        // Fill first span
        multispan.append(1)
        multispan.append(2)
        multispan.append(3)
        
        expectEqual(multispan.count(at: 0), 3)
        expectEqual(multispan.count(at: 1), 0)
        
        // Should go to second span
        multispan.append(4)
        multispan.append(5)
        
        expectEqual(multispan.count(at: 0), 3)
        expectEqual(multispan.count(at: 1), 2)
        expectEqual(multispan.totalCount, 5)
      }
    }
    expectEqual(buffer1, [1, 2, 3])
    expectEqual(buffer2, [4, 5, 0])
  }
  
  func test_append_repeating() {
    var buffer = [Int](repeating: 0, count: 10)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(repeating: 99, count: 5)
      
      expectEqual(multispan.totalCount, 5)
      expectEqual(multispan.totalFreeCapacity, 5)
    }
    expectEqual(buffer, [99, 99, 99, 99, 99, 0, 0, 0, 0, 0])
  }
  
  // MARK: - Remove Tests
  
  func test_removeLast_singleElement() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 5)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = OutputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.append(42)
    multispan.append(99)
    
    let removed = multispan.removeLast()
    
    expectEqual(removed, 99)
    expectEqual(multispan.totalCount, 1)
    expectEqual(multispan.totalFreeCapacity, 4)
    expectEqual(multispan.finalize(), 1)
    /*
     Can't test that the 99 was actually removed from the buffer because
     deinitializing an Int doesn't set it to 0 it just makes it formally
     invalid to refer to again until it's re-initialized
     */
  }
  
  func test_removeLast_multipleElements() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = OutputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.append(1)
    multispan.append(2)
    multispan.append(3)
    multispan.append(4)
    multispan.append(5)
    
    multispan.removeLast(3)
    
    expectEqual(multispan.totalCount, 2)
    expectEqual(multispan.totalFreeCapacity, 8)
    expectEqual(multispan.finalize(), 2)
    /*
     Can't test that the elements were actually removed from the buffer because
     deinitializing an Int doesn't set it to 0 it just makes it formally
     invalid to refer to again until it's re-initialized
     */
  }
  
  func test_removeAll() {
    let bufferPtr = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    bufferPtr.initialize(repeating: 0)
    defer { bufferPtr.deallocate() }
    
    var multispan = OutputMultispan<Int>()
    multispan._append(buffer: bufferPtr, initializedCount: 0)
    
    multispan.append(1)
    multispan.append(2)
    multispan.append(3)
    
    multispan.removeAll()
    
    expectEqual(multispan.totalCount, 0)
    expectEqual(multispan.totalFreeCapacity, 10)
    expectTrue(multispan.isEmpty)
    expectFalse(multispan.isFull)
  }
  
  func test_removeAll_multipleSpans() {
    let buf1 = UnsafeMutableBufferPointer<Int>.allocate(capacity: 5)
    buf1.initialize(repeating: 0)
    defer { buf1.deallocate() }
    let buf2 = UnsafeMutableBufferPointer<Int>.allocate(capacity: 5)
    buf2.initialize(repeating: 0)
    defer { buf2.deallocate() }
    
    var multispan = OutputMultispan<Int>()
    multispan._append(buffer: buf1, initializedCount: 0)
    multispan._append(buffer: buf2, initializedCount: 0)
    
    // Add elements to both spans
    for i in 1...7 {
      multispan.append(i)
    }
    
    multispan.removeAll()
    
    expectEqual(multispan.totalCount, 0)
    expectEqual(multispan.count(at: 0), 0)
    expectEqual(multispan.count(at: 1), 0)
    expectTrue(multispan.isEmpty)
  }
  
  // MARK: - Index and Subscript Tests
  
  func test_indices() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(10)
      multispan.append(20)
      multispan.append(30)
      
      let startIdx = multispan.startIndex
      let endIdx = multispan.endIndex
      
      expectEqual(startIdx.bufferIndex, 0)
      expectEqual(startIdx.elementIndex, 0)
      expectEqual(endIdx.bufferIndex, 1)
      expectEqual(endIdx.elementIndex, 0)
    }
  }
  
  func test_subscript_access() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(100)
      multispan.append(200)
      multispan.append(300)
      
      let idx0 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
      let idx2 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 2)
      
      expectEqual(multispan[idx0], 100)
      expectEqual(multispan[idx1], 200)
      expectEqual(multispan[idx2], 300)
    }
  }
  
  func test_subscript_modify() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(100)
      multispan.append(200)
      
      let idx0 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
      
      multispan[idx0] = 999
      multispan[idx1] = 888
      
      expectEqual(multispan[idx0], 999)
      expectEqual(multispan[idx1], 888)
    }
  }
  
  func test_swapAt() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(10)
      multispan.append(20)
      multispan.append(30)
      
      let idx0 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx2 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 2)
      
      multispan.swapAt(idx0, idx2)
      
      expectEqual(multispan[idx0], 30)
      expectEqual(multispan[idx2], 10)
    }
  }
  
  func test_index_after() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      let idx0 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
      let idx1 = multispan.index(after: idx0)
      
      expectEqual(idx1.bufferIndex, 0)
      expectEqual(idx1.elementIndex, 1)
    }
  }
  
  func test_index_comparison() {
    let idx0 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 0)
    let idx1 = OutputMultispan<Int>.Index(bufferIndex: 0, elementIndex: 1)
    let idx2 = OutputMultispan<Int>.Index(bufferIndex: 1, elementIndex: 0)
    
    expectTrue(idx0 < idx1)
    expectTrue(idx1 < idx2)
    expectTrue(idx0 < idx2)
    expectFalse(idx1 < idx0)
  }
  
  // MARK: - withOutputSpan Tests
  
  func test_withOutputSpan_access() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(1)
      multispan.append(2)
      multispan.append(3)
      
      let result = multispan.withOutputSpan(at: 0) { span in
        return span.count
      }
      
      expectEqual(result, 3)
    }
  }
  
  // MARK: - isFull Tests
  
  func test_isFull_empty() {
    let multispan = OutputMultispan<Int>()
    expectTrue(multispan.isFull)
  }
  
  func test_isFull_partiallyFilled() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(1)
      expectFalse(multispan.isFull)
    }
  }
  
  func test_isFull_filled() {
    var buffer = [Int](repeating: 0, count: 3)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(1)
      multispan.append(2)
      multispan.append(3)
      
      expectTrue(multispan.isFull)
      expectEqual(multispan.totalFreeCapacity, 0)
    }
  }
  
  // MARK: - Extension Tests (OutputMultispan+Extras.swift)
  
  func test_rigidArray_appendWithOutputMultispan() async {
    var array = RigidArray<Int>(capacity: 10)
    
    await array.append(addingCount: 5) { (multispan: inout OutputMultispan<Int>) in
      multispan.append(1)
      multispan.append(2)
      multispan.append(3)
      multispan.append(4)
      multispan.append(5)
      print("is this thing on? Span count: \(multispan.totalCount)") 
    }
    
    expectEqual(array.count, 5) 
    expectEqual(array.freeCapacity, 5)
    expectEqual(array[0], 1)
    expectEqual(array[4], 5)
  }
  
  func test_rigidArray_initWithOutputMultispan() async throws {
    let array = await RigidArray<Int>(capacity: 7) { multispan in
      for i in 0..<7 {
        multispan.append(i * 10)
      }
    }
    
    expectEqual(array.count, 7)
    expectEqual(array.capacity, 7)
    expectEqual(array[0], 0)
    expectEqual(array[3], 30)
    expectEqual(array[6], 60)
  }
  
  func test_uniqueArray_appendWithOutputMultispan() async {
    var array = UniqueArray<Int>(capacity: 8)
    
    await array.append(addingCount: 4) { (multispan: inout OutputMultispan<Int>) in
      multispan.append(100)
      multispan.append(200)
      multispan.append(300)
      multispan.append(400)
    }
    
    expectEqual(array.count, 4)
    expectEqual(array[0], 100)
    expectEqual(array[3], 400)
  }
  
  func test_uniqueArray_initWithOutputMultispan() async throws {
    let array = await UniqueArray<Int>(capacity: 5) { multispan in
      multispan.append(repeating: 42, count: 5)
    }
    
    expectEqual(array.count, 5)
    for i in 0..<5 {
      expectEqual(array[i], 42)
    }
  }
  
  // MARK: - Error Handling Tests
  
  func test_rigidArray_appendWithError() async {
    enum TestError: Error {
      case intentional
    }
    
    var array = RigidArray<Int>(capacity: 10)
    
    do {
      try await array.append(addingCount: 5) { (multispan: inout OutputMultispan<Int>) throws(TestError) in
        multispan.append(1)
        multispan.append(2)
        throw TestError.intentional
      }
      XCTFail("Expected error to be thrown")
    } catch {
      // Expected error
    }
  }
  
  // MARK: - Edge Cases
  
  func test_finalize() {
    var buffer = [Int](repeating: 0, count: 5)
    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      var multispan = OutputMultispan<Int>()
      multispan._append(buffer: bufferPtr, initializedCount: 0)
      
      multispan.append(1)
      multispan.append(2)
      multispan.append(3)
      
      let finalizedCount = multispan.finalize()
      expectEqual(finalizedCount, 3)
    }
  }
  
  func test_multipleSpans_complexScenario() {
    var buffer1 = [Int](repeating: 0, count: 3)
    var buffer2 = [Int](repeating: 0, count: 4)
    var buffer3 = [Int](repeating: 0, count: 5)
    
    buffer1.withUnsafeMutableBufferPointer { buf1 in
      buffer2.withUnsafeMutableBufferPointer { buf2 in
        buffer3.withUnsafeMutableBufferPointer { buf3 in
          var multispan = OutputMultispan<Int>()
          multispan._append(buffer: buf1, initializedCount: 0)
          multispan._append(buffer: buf2, initializedCount: 0)
          multispan._append(buffer: buf3, initializedCount: 0)
          
          // Fill all spans
          for i in 1...12 {
            multispan.append(i * 10)
          }
          
          expectEqual(multispan.spanCount, 3)
          expectEqual(multispan.totalCount, 12)
          expectEqual(multispan.count(at: 0), 3)
          expectEqual(multispan.count(at: 1), 4)
          expectEqual(multispan.count(at: 2), 5)
          expectTrue(multispan.isFull)
          
          // Remove some elements
          multispan.removeLast(5)
          
          expectEqual(multispan.totalCount, 7)
          expectFalse(multispan.isFull)
        }
      }
    }
  }
}

#endif
