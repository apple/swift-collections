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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedPrepend(_ newElement: consuming Element) {
    _handle.uncheckedPrepend(newElement)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func prepend(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque is full")
    uncheckedPrepend(newElement)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidDeque capacity overflow")
    guard newElements.count > 0 else { return }
    _handle.uncheckedPrepend(contentsOf: newElements)
  }
  
  /// Copies the elements of a buffer to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///        the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.prepend(copying: UnsafeBufferPointer(newElements))
  }
  
  /// Copies the elements of a span to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(copying newElements: Span<Element>) {
    unsafe newElements.withUnsafeBufferPointer { source in
      unsafe self.prepend(copying: source)
    }
  }
  
  /// Copies the elements of a collection to the front of the rigid deque.
  ///
  /// Use this method to prepend the elements of a collection to the front of
  /// this deque. This example prepends the elements of a `Range<Int>` instance
  /// to a rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(contentsOf: [1, 2, 3, 4, 5])
  ///     numbers.prepend(contentsOf: 10...15)
  ///     print(numbers)
  ///     // Prints "[10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]"
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: some Collection<Element>
  ) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    let c = newElements.count
    guard c > 0 else { return }
    precondition(c <= freeCapacity, "RigidDeque capacity overflow")
    _handle.uncheckedPrepend(contentsOf: newElements, count: c)
  }
  
  /// Copies the elements of a sequence to the front of the rigid deque.
  ///
  /// Use this method to prepend the elements of a sequence to the front of this
  /// deque. This example prepends the elements of a `Range<Int>` instance to a
  /// rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(contentsOf: [1, 2, 3, 4, 5])
  ///     numbers.prepend(contentsOf: 10...15)
  ///     print(numbers)
  ///     // Prints "[10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]"
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    
    // Add new elements as suffix and check that all elements were copied.
    let oldEndSlot = _handle.endSlot
    var it = self._append(prefixOf: newElements)
    precondition(it.next() == nil, "RigidDeque capacity overflow")
    _handle.rotate(toStartAt: oldEndSlot)
  }
}

#endif
