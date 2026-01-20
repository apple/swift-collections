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
  
  /// Initializes a new rigid deque with zero capacity and no elements.
  ///
  /// - Complexity: O(1)
  @inlinable
  public init() {
    self.init(_handle: .allocate(capacity: 0))
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
    try self.append(count: capacity, initializingWith: initializer)
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
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Creates a new rigid deque taking over the storage of the specified
  /// unique deque instance, consuming it in the process.
  ///
  /// - Complexity: O(1)
  @inlinable
  public init(consuming array: consuming UniqueDeque<Element>) {
    self = array._storage
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Creates a new deque with the specified capacity, holding a copy
  /// of the contents of a given iterable.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new deque.
  ///   - contents: An iterable whose contents to copy into the new deque.
  ///      The iterable must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    I: Iterable<Element> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    copying contents: borrowing I
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
#endif

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
    capacity: Int? = nil,
    copying contents: some Collection<Element>
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Creates a new deque with the specified capacity, holding a copy
  /// of the contents of a given iterable.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new deque.
  ///   - contents: An iterable whose contents to copy into the new deque.
  ///      The iterable must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    I: Iterable<Element> & Sequence<Element>
  >(
    capacity: Int,
    copying contents: borrowing I
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
#endif

}

#endif
