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

#if false // TODO
extension UniqueArray /*where Element: Copyable*/ {
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Sequence<Element>>(
    capacity: Int? = nil,
    copying contents: C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }
}
#endif

#if false // TODO
extension UniqueArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.borrowElement(at: index)
  }
}
#endif

#if false // TODO
extension UniqueArray where Element: ~Copyable {
  @inlinable
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Mut<Element> {
    _storage.mutateElement(at: index)
  }
}
#endif

#if false // TODO
@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func _edit<R: ~Copyable>(
    freeCapacity: Int,
    inPlaceMutation: (inout OutputSpan<Element>) -> R,
    reallocatingMutation: (inout InputSpan<Element>, inout OutputSpan<Element>) -> R
  ) -> R {
    if _storage.freeCapacity >= freeCapacity {
      return edit(inPlaceMutation)
    }
    let newCapacity = _grow(freeCapacity: freeCapacity)
    return _storage.reallocate(capacity: newCapacity, with: reallocatingMutation)
  }
}
#endif

#if false // TODO
@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
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
