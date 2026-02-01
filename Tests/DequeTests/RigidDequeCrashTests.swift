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
}

#endif
