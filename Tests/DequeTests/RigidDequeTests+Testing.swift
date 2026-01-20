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

import Testing
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import DequeModule
import ContainersPreview
#endif

#if compiler(>=6.2)
@Suite("RigidDeque Tests")
struct RigidDequeTests_Testing {
  // MARK: - Initializers
  
  @Test("Init with capacity")
  func initWithCapacity() {
    let deque = RigidDeque<Int>(capacity: 5)
    #expect(deque.capacity == 5)
    #expect(deque.count == 0)
    #expect(deque.freeCapacity == 5)
  }
  
  @Test("Init repeating value")
  func initRepeatingValue() {
    let deque = RigidDeque(repeating: 42, count: 3)
    #expect(deque.count == 3)
    #expect(deque.capacity == 3)
    #expect(deque[0] == 42)
    #expect(deque[1] == 42)
    #expect(deque[2] == 42)
  }
  
  @Test("Init copying sequence")
  func initCopyingSequence() {
    let source = [1, 2, 3, 4, 5]
    let deque = RigidDeque(capacity: 10, copying: source)
    #expect(deque.count == 5)
    #expect(deque.capacity == 10)
    for i in 0..<5 {
      #expect(deque[i] == source[i])
    }
  }
  
  @Test("Init copying collection")
  func initCopyingCollection() {
    let source = [1, 2, 3, 4, 5]
    let deque = RigidDeque(copying: source)
    #expect(deque.count == 5)
    #expect(deque.capacity == 5)
    for i in 0..<5 {
      #expect(deque[i] == source[i])
    }
  }
  
  @Test("Init with initializing closure")
  func initWithInitializingClosure() {
    let deque = RigidDeque<Int>(capacity: 5) { span in
      span.append(10)
      span.append(20)
      span.append(30)
    }
    #expect(deque.count == 3)
    #expect(deque.capacity == 5)
    #expect(deque[0] == 10)
    #expect(deque[1] == 20)
    #expect(deque[2] == 30)
  }
  
  // MARK: - Basic Properties
  
  @Test("Basic properties")
  func basicProperties() {
    var deque = RigidDeque<Int>(capacity: 10)
    
    // Empty deque
    #expect(deque.isEmpty == true)
    #expect(deque.isFull == false)
    #expect(deque.count == 0)
    #expect(deque.capacity == 10)
    #expect(deque.freeCapacity == 10)
    #expect(deque.startIndex == 0)
    #expect(deque.endIndex == 0)
    
    // Add some elements
    deque.append(1)
    deque.append(2)
    deque.append(3)
    
    #expect(deque.isEmpty == false)
    #expect(deque.isFull == false)
    #expect(deque.count == 3)
    #expect(deque.capacity == 10)
    #expect(deque.freeCapacity == 7)
    #expect(deque.startIndex == 0)
    #expect(deque.endIndex == 3)
    
    // Fill to capacity
    for i in 4...10 {
      deque.append(i)
    }
    
    #expect(deque.isEmpty == false)
    #expect(deque.isFull == true)
    #expect(deque.count == 10)
    #expect(deque.freeCapacity == 0)
  }
  
  // MARK: - Element Access
  
  @Test("Subscript access")
  func subscriptAccess() {
    var deque = RigidDeque(copying: [10, 20, 30, 40, 50])
    
    // Read access
    #expect(deque[0] == 10)
    #expect(deque[2] == 30)
    #expect(deque[4] == 50)
    
    // Write access
    deque[1] = 99
    #expect(deque[1] == 99)
  }
  
#if false
  @Test("Borrow element")
  func borrowElement() {
    let deque = RigidDeque(copying: [1, 2, 3])
    let ref = deque.borrowElement(at: 1)
    #expect(ref[] == 2)
  }
  
  @Test("Mutate element")
  func mutateElement() {
    var deque = RigidDeque(copying: [1, 2, 3])
    var mut = deque.mutateElement(at: 1)
    mut[] = 99
    #expect(deque[1] == 99)
  }
#endif
  
  // MARK: - Append Operations
  
  @Test("Append single element")
  func appendSingleElement() {
    var deque = RigidDeque<Int>(capacity: 5)
    
    deque.append(10)
    #expect(deque.count == 1)
    #expect(deque[0] == 10)
    
    deque.append(20)
    #expect(deque.count == 2)
    #expect(deque[1] == 20)
  }
  
  @Test("PushLast returns element when full")
  func pushLastReturnsBehavior() {
    var deque = RigidDeque<Int>(capacity: 2)
    deque.append(1)
    deque.append(2)
    
    let result = deque.pushLast(99)
    #expect(result == 99) // Should return the item when full
    #expect(deque.count == 2) // Count unchanged
    
    // When not full, should return nil
    let result2 = deque.pushLast(3) // This should fail since deque is full
    #expect(result2 == 3)
  }
  
  @Test("Append copying buffer")
  func appendCopyingBuffer() {
    var deque = RigidDeque<Int>(capacity: 10)
    let buffer = [1, 2, 3, 4, 5]
    
    buffer.withUnsafeBufferPointer { ptr in
      deque.append(copying: ptr)
    }
    
    #expect(deque.count == 5)
    for i in 0..<5 {
      #expect(deque[i] == buffer[i])
    }
  }
  
  @Test("Append copying sequence")
  func appendCopyingSequence() {
    var deque = RigidDeque<Int>(capacity: 10)
    let source = [1, 2, 3, 4]
    
    deque.append(copying: source)
    
    #expect(deque.count == 4)
    for i in 0..<4 {
      #expect(deque[i] == source[i])
    }
  }
  
  // MARK: - Prepend Operations
  
  @Test("Prepend single element")
  func prependSingleElement() {
    var deque = RigidDeque<Int>(capacity: 5)
    
    deque.prepend(10)
    #expect(deque.count == 1)
    #expect(deque[0] == 10)
    
    deque.prepend(20)
    #expect(deque.count == 2)
    #expect(deque[0] == 20)
    #expect(deque[1] == 10)
  }
  
  @Test("Prepend copying buffer")
  func prependCopyingBuffer() {
    var deque = RigidDeque<Int>(capacity: 10)
    deque.append(5)
    
    let buffer = [1, 2, 3, 4]
    buffer.withUnsafeBufferPointer { ptr in
      deque.prepend(copying: ptr)
    }
    
    #expect(deque.count == 5)
    #expect(deque[0] == 1)
    #expect(deque[1] == 2)
    #expect(deque[2] == 3)
    #expect(deque[3] == 4)
    #expect(deque[4] == 5)
  }
  
  @Test("Prepend copying collection")
  func prependCopyingCollection() {
    var deque = RigidDeque<Int>(capacity: 10)
    deque.append(copying: [5, 6])
    
    deque.prepend(copying: [1, 2, 3, 4])
    
    #expect(deque.count == 6)
    #expect(deque[0] == 1)
    #expect(deque[1] == 2)
    #expect(deque[2] == 3)
    #expect(deque[3] == 4)
    #expect(deque[4] == 5)
    #expect(deque[5] == 6)
  }
  
  @Test("Prepend copying sequence")
  func prependCopyingSequence() {
    do {
      var deque = RigidDeque<Int>(capacity: 10)
      deque.append(100)
      
      let seq = stride(from: 10, through: 30, by: 10)
      deque.prepend(copying: seq)
      
      #expect(deque.count == 4)
      #expect(deque[0] == 10)
      #expect(deque[1] == 20)
      #expect(deque[2] == 30)
      #expect(deque[3] == 100)
    }

    do {
      var deque = RigidDeque<Int>(repeating: 100, count: 10)
      deque.removeFirst(9)
      
      let seq = stride(from: 10, through: 30, by: 10)
      deque.prepend(copying: seq)
      
      #expect(deque.count == 4)
      #expect(deque[0] == 10)
      #expect(deque[1] == 20)
      #expect(deque[2] == 30)
      #expect(deque[3] == 100)
    }
  }
  
  // MARK: - Removal Operations
  
  @Test("Remove at index")
  func removeAtIndex() {
    var deque = RigidDeque(copying: [10, 20, 30, 40, 50])
    
    let removed = deque.remove(at: 2)
    #expect(removed == 30)
    #expect(deque.count == 4)
    #expect(deque[0] == 10)
    #expect(deque[1] == 20)
    #expect(deque[2] == 40)
    #expect(deque[3] == 50)
  }
  
  @Test("Remove subrange")
  func removeSubrange() {
    var deque = RigidDeque(copying: [1, 2, 3, 4, 5, 6])
    
    deque.removeSubrange(1..<4)
    #expect(deque.count == 3)
    #expect(deque[0] == 1)
    #expect(deque[1] == 5)
    #expect(deque[2] == 6)
  }
  
  @Test("RemoveFirst operations")
  func removeFirstOperations() {
    var deque = RigidDeque(copying: [1, 2, 3, 4, 5])
    
    // Remove single first
    let first = deque.removeFirst()
    #expect(first == 1)
    #expect(deque.count == 4)
    #expect(deque[0] == 2)
    
    // Remove multiple first
    deque.removeFirst(2)
    #expect(deque.count == 2)
    #expect(deque[0] == 4)
    #expect(deque[1] == 5)
  }
  
  @Test("RemoveLast operations")
  func removeLastOperations() {
    var deque = RigidDeque(copying: [1, 2, 3, 4, 5])
    
    // Remove single last
    let last = deque.removeLast()
    #expect(last == 5)
    #expect(deque.count == 4)
    #expect(deque[3] == 4)
    
    // Remove multiple last
    deque.removeLast(2)
    #expect(deque.count == 2)
    #expect(deque[0] == 1)
    #expect(deque[1] == 2)
  }
  
  @Test("PopFirst and PopLast")
  func popOperations() {
    var deque = RigidDeque(copying: [10, 20])
    
    // Pop when not empty
    let first = deque.popFirst()
    #expect(first == 10)
    #expect(deque.count == 1)
    
    let last = deque.popLast()
    #expect(last == 20)
    #expect(deque.count == 0)
    
    // Pop when empty
    let emptyFirst = deque.popFirst()
    let emptyLast = deque.popLast()
    #expect(emptyFirst == nil)
    #expect(emptyLast == nil)
  }
  
  @Test("Remove all")
  func removeAll() {
    var deque = RigidDeque(copying: [1, 2, 3, 4, 5])
    
    deque.removeAll()
    #expect(deque.isEmpty == true)
    #expect(deque.count == 0)
    #expect(deque.capacity == 5) // Capacity should remain unchanged
  }
    
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
