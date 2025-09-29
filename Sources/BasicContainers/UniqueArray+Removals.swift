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
  /// Removes all elements from the array, optionally preserving its
  /// allocated capacity.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @inlinable
  @inline(__always)
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    if keepCapacity {
      _storage.removeAll()
    } else {
      _storage = RigidArray(capacity: 0)
    }
  }

  /// Removes and returns the last element of the array.
  ///
  /// The array must not be empty.
  ///
  /// - Returns: The last element of the original array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeLast() -> Element {
    _storage.removeLast()
  }

  /// Removes and discards the specified number of elements from the end of the
  /// array.
  ///
  /// Attempting to remove more elements than exist in the array triggers a
  /// runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///    the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    _storage.removeLast(k)
  }

  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the
  /// gap.
  ///
  /// - Parameter i: The position of the element to remove. `index` must be
  ///   a valid index of the array that is not equal to the end index.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// All the elements following the specified subrange are moved to close the
  /// resulting gap.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  public mutating func removeSubrange(_  bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    // FIXME: Remove this in favor of a standard algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Removes and returns the last element of the array, if there is one.
  ///
  /// - Returns: The last element of the array if the array is not empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    if isEmpty { return nil }
    return removeLast()
  }
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Remove all items currently in this array, returning an input span to
  /// allow them to be consumed in place.
  /// The input span extends the exclusive mutating access initiated by this
  /// operation to cover the span's lifetime. Once the span is destroyed,
  /// the array becomes empty, but it preserves its original storage.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  public mutating func consumeAll() -> InputSpan<Element> {
    _storage.consumeAll()
  }

  /// Remove the specified number of items from the end of this array,
  /// returning an input span to allow them to be consumed in place.
  /// The input span extends the exclusive mutating access initiated by this
  /// operation to cover the span's lifetime.
  ///
  /// - Parameter n: The number of items to consume from the end of the array.
  ///   `n` must be greater than or equal to zero and must not exceed
  ///   the count of the array.
  ///
  /// - Complexity: O(`n`)
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  public mutating func consumeLast(_ count: Int) -> InputSpan<Element> {
    _storage.consumeLast(count)
  }

  /// Remove the specified subrange of items from this array,
  /// passing an input span to the given function to consume them in place.
  ///
  /// - Parameter bounds: The subrange of items to consume from this array.
  /// - Parameter body: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is not required to consume all items in the span;
  ///    however, the span's remaining items will still be removed from
  ///    the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  public mutating func consumeSubrange<E: Error, Result: ~Copyable>(
    _ bounds: Range<Int>,
    consumingWith body: (inout InputSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try _storage.consumeSubrange(bounds, consumingWith: body)
  }
}
#endif

#endif
