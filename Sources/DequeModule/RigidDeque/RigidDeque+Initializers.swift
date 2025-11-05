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
  /// Creates an empty rigid deque with the specified capacity.
  @_alwaysEmitIntoClient
  @_transparent
  public init(capacity: Int) {
    self.init(_handle: .allocate(capacity: capacity))
  }
  
  /// Creates a rigid deque with the specified capacity, then calls the given
  /// closure with an output span covering the deque's uninitialized memory.
  ///
  /// - Parameters:
  ///   - capacity: The number of elements to allocate space for in the new
  ///     rigid deque.
  ///   - initializer: A closure that initializes the elements of the new deque.
  ///     - Parameter outputSpan: An `OutputSpan` allowing initialization of the
  ///       deque's initial elements.
  @inlinable
  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws -> Void
  ) rethrows {
    self.init(_handle: .allocate(capacity: capacity))
    let buffer = _handle.mutableBuffer(for: .zero ..< _Slot(at: capacity))
    var span = OutputSpan(buffer: buffer, initializedCount: 0)
    defer {
      _handle.count = span.finalize(for: buffer)
      span = OutputSpan()
    }
    try initializer(&span)
  }

  /// Creates a rigid deque with the specified capacity, then calls the given
  /// closure with a buffer covering the deque's uninitialized memory.
  ///
  /// Inside the closure, set the `initializedCount` parameter to the number of
  /// elements that are initialized by the closure. The memory in the range
  /// `buffer[0..<initializedCount]` must be initialized at the end of the
  /// closure's execution, and the memory in the range
  /// `buffer[initializedCount...]` must be uninitialized. This postcondition
  /// must hold even if the `initializer` closure throws an error.
  ///
  /// - Parameters:
  ///   - unsafeUninitializedCapacity: The number of elements to allocate
  ///     space for in the new rigid deque.
  ///   - initializer: A closure that initializes elements and sets the count
  ///     of the new deque.
  ///     - Parameters:
  ///       - buffer: A buffer covering uninitialized memory with room for the
  ///         specified number of elements.
  ///       - initializedCount: The count of initialized elements in the deque,
  ///         which begins as zero. Set `initializedCount` to the number of
  ///         elements you initialize.
  @inlinable
  public init(
    unsafeUninitializedCapacity capacity: Int,
    initializingWith initializer:
      (inout UnsafeMutableBufferPointer<Element>, inout Int) throws -> Void
  ) rethrows {
    self.init(_handle: .allocate(capacity: capacity))
    var newCount = 0
    var buffer = _handle.mutableBuffer(for: .zero ..< _Slot(at: capacity))
    
    defer {
      precondition(newCount <= capacity,
        "Initialized count set to greater than specified capacity")
      let b = _handle.mutableBuffer(for: .zero ..< _Slot(at: capacity))
      precondition(buffer.baseAddress == b.baseAddress && buffer.count == b.count,
        "Initializer relocated Deque storage")
      _handle.count = newCount
    }
    try initializer(&buffer, &newCount)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Creates a new deque containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  ///
  /// - Complexity: O(`count`)
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(capacity: count)
    _handle.mutableBuffer.initialize(repeating: repeatedValue)
    _handle.count = count
  }

  /// Creates a new deque with the specified capacity, holding a copy
  /// of the contents of a given sequence.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new deque.
  ///   - contents: The sequence whose contents to copy into the new deque.
  ///      The sequence must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }

  /// Creates a new rigid deque from the given collection, with the capacity
  /// derived from the collection's count.
  ///
  /// - Parameters:
  ///   - contents: The contents whose contents to copy into the new deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    copying contents: some Collection<Element>
  ) {
    self.init(capacity: contents.count)
    self.append(copying: contents)
  }
}

#endif
