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

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  public init<E: Error>(
    capacity: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(capacity: capacity)
    try edit(body)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray /*where Element: Copyable*/ {
  /// Creates a new array containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(consuming: RigidArray(repeating: repeatedValue, count: count))
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  public init(consuming storage: consuming RigidArray<Element>) {
    self._storage = storage
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray /*where Element: Copyable*/ {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<Source: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing Source
  ) {
    self.init(capacity: capacity ?? 0)
    self.append(copying: contents)
  }
#endif

  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int? = nil,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity ?? 0)
    self.append(copying: contents)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<Source: Container<Element> & Sequence<Element>>(
    capacity: Int? = nil,
    copying contents: Source
  ) {
    self.init(capacity: capacity ?? 0)
    self.append(copying: contents)
  }
#endif

}

#endif
