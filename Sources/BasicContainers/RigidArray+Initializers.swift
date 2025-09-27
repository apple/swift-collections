//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
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

@available(SpanAvailability 1.0, *)
extension RigidArray where Element: ~Copyable {
  @inlinable
  public init<E: Error>(
    capacity: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(capacity: capacity)
    try edit(body)
  }
}

@available(SpanAvailability 1.0, *)
extension RigidArray /*where Element: Copyable*/ {
  /// Creates a new array containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(capacity: count)
    unsafe _freeSpace.initialize(repeating: repeatedValue)
    _count = count
  }
}

@available(SpanAvailability 1.0, *)
extension RigidArray /*where Element: Copyable*/ {
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<Source: Container<Element> & Sequence<Element>>(
    capacity: Int,
    copying contents: Source
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<Source: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing Source
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
#endif

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
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<Source: Container<Element> & Collection<Element>>(
    capacity: Int? = nil,
    copying contents: Source
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
#endif
}

// FIXME: Add init(moving:), init(consuming:)

#endif
