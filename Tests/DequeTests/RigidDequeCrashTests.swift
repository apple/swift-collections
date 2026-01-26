//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import DequeModule
import ContainersPreview
#endif

#if compiler(>=6.2)
@Suite("RigidDeque Crash Tests")
struct RigidDequeCrashTests {
    
  // MARK: - Capacity Management

#if false
  @Test("Resize capacity")
  func resizeCapacity() {
    var deque = RigidDeque(copying: [1, 2, 3])
    #expect(deque.capacity == 3)
    
    // Increase capacity
    deque.resize(to: 10)
    #expect(deque.capacity == 10)
    #expect(deque.count == 3)
    #expect(deque[0] == 1)
    #expect(deque[1] == 2)
    #expect(deque[2] == 3)
    
    // Decrease capacity (but still fits existing elements)
    deque.resize(to: 5)
    #expect(deque.capacity == 5)
    #expect(deque.count == 3)
  }
#endif
  
  // MARK: - Edge Cases and Error Conditions
  
  @Test("Append to full deque fails")
  func appendToFullDequeFails() async {
    await #expect(processExitsWith: .failure) {
      var deque = RigidDeque<Int>(capacity: 2)
      deque.append(1)
      deque.append(2)
      
      #expect(deque.isFull == true)
      deque.append(3) // Traps with "RigidDeque is full"
    }
  }
  
  @Test("Prepend to full deque fails")
  func prependToFullDequeFails() async {
    await #expect(processExitsWith: .failure) {
      var deque = RigidDeque<Int>(capacity: 2)
      deque.append(1)
      deque.append(2)
      
      #expect(deque.isFull == true)
      deque.prepend(0) // Traps with "RigidDeque is full"
    }
  }
  
  #if false
  @Test("Resize too small")
  func resizeTooSmall() async {
    await #expect(processExitsWith: .failure) {
      var deque = RigidDeque<Int>(repeating: 0, count: 5)
      deque.resize(to: 3)
    }
  }
  #endif

  @Test("Invalid index access")
  func invalidIndexAccess() async {
    await #expect(processExitsWith: .failure) {
      let deque = RigidDeque(copying: [1, 2, 3])
      let _ = deque[-1]  // Index out of bounds
    }
    await #expect(processExitsWith: .failure) {
      let deque = RigidDeque(copying: [1, 2, 3])
      let _ = deque[3]  // Index out of bounds
    }
    #if false
    await #expect(processExitsWith: .failure) {
      let deque = RigidDeque(copying: [1, 2, 3])
      let _ = deque.borrowElement(at: 5) // Index out of bounds
    }
    #endif
  }
  
  @Test("Remove from empty deque")
  func removeFromEmptyDeque() async {
    await #expect(processExitsWith: .failure) {
      var deque = RigidDeque<Int>(capacity: 5)
      deque.removeFirst() // Can't remove first element of an empty RigidDeque
    }
    await #expect(processExitsWith: .failure) {
      var deque = RigidDeque<Int>(capacity: 5)
      deque.removeLast() // Can't remove last element of an empty RigidDeque
    }
  }
  
  // MARK: - Mixed Operations
  
  @Test("Mixed append and prepend operations")
  func mixedAppendPrependOperations() {
    var deque = RigidDeque<Int>(capacity: 10)
    
    deque.append(5)
    deque.prepend(4)
    deque.append(6)
    deque.prepend(3)
    
    #expect(deque.count == 4)
    #expect(deque[0] == 3)
    #expect(deque[1] == 4)
    #expect(deque[2] == 5)
    #expect(deque[3] == 6)
  }
  
  @Test("Complex operations sequence")
  func complexOperationsSequence() {
    var deque = RigidDeque<Int>(capacity: 20)
    
    // Initial setup
    deque.append(copying: [10, 20, 30])
    deque.prepend(copying: [5, 7])
    #expect(deque.count == 5)
    
    // Remove some elements
    deque.removeFirst()
    deque.removeLast()
    #expect(deque.count == 3)
    #expect(deque[0] == 7)
    #expect(deque[1] == 10)
    #expect(deque[2] == 20)
  }
  
  // MARK: - Type Safety Tests (Non-Copyable)
  
  @Test("Non-copyable element type")
  func nonCopyableElementType() {
    struct NonCopyable: ~Copyable {
      let id: Int
      init(_ id: Int) { self.id = id }
    }
    
    var deque = RigidDeque<NonCopyable>(capacity: 5)
    deque.append(NonCopyable(1))
    deque.append(NonCopyable(2))
    
    #expect(deque.count == 2)
    #expect(deque[0].id == 1)
    #expect(deque[1].id == 2)
    
    let removed = deque.removeFirst()
    #expect(removed.id == 1)
    #expect(deque.count == 1)
  }
}

#else
// RigidDeque requires Swift 6.2+ compiler
@Suite("RigidDeque Tests")
struct RigidDequeTests {
  @Test("Compiler version check")
  func compilerVersionCheck() {
    // This test suite requires Swift 6.2+ for RigidDeque availability
    #expect(true, "RigidDeque requires Swift 6.2+ compiler")
  }
}
#endif
