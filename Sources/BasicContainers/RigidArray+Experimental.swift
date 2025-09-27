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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @inlinable
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    return unsafe Borrow(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      borrowing: self
    )
  }
}
#endif

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @inlinable
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Mut<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe Mut(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      mutating: &self
    )
  }
}
#endif

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func reallocate<E: Error, R: ~Copyable>(
    capacity: Int,
    with body: (
      inout InputSpan<Element>,
      inout OutputSpan<Element>
    ) throws(E) -> R
  ) throws(E) -> R {
    var source = InputSpan(buffer: _storage, initializedCount: _count)
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(
      capacity: capacity)
    var target = OutputSpan(buffer: newStorage, initializedCount: 0)
    defer {
      _ = consume source
      _storage.deallocate()
      _count = target.finalize(for: newStorage)
      _storage = newStorage
      source = .init()
      target = .init()
    }
    return try body(&source, &target)
  }
}
#endif

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a container that meets
  /// particular criteria. The order of the remaining elements is preserved.
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the
  ///   sequence as its argument and returns a Boolean value indicating
  ///   whether the element should be removed from the array.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeAll<E: Error>(
    where shouldBeRemoved: (borrowing Element) throws(E) -> Bool
  ) throws(E) {
    // FIXME: Remove this in favor of a standard algorithm.
    let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    removeSubrange(suffixStart...)
  }
}
#endif

#endif
