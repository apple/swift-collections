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
  /// Removes all elements from the array, preserving its allocated capacity.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @inlinable
  public mutating func removeAll() {
    unsafe _items.deinitialize()
    _count = 0
  }

  /// Removes and returns the last element of the array.
  ///
  /// The array must not be empty.
  ///
  /// - Returns: The last element of the original array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element from an empty array")
    let old = unsafe _storage.moveElement(from: _count - 1)
    _count -= 1
    return old
  }

  /// Removes and discards the specified number of elements from the end of the
  /// array.
  ///
  /// Attempting to remove more elements than exist in the array
  /// triggers a runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///   the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    precondition(
      k >= 0 && k <= _count,
      "Count of elements to remove is out of bounds")
    unsafe _storage.extracting(
      Range(uncheckedBounds: (_count - k, _count))
    ).deinitialize()
    _count &-= k
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
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    let old = unsafe _storage.moveElement(from: index)
    _closeGap(at: index, count: 1)
    _count -= 1
    return old
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// All the elements following the specified subrange are moved to close the
  /// resulting gap.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeSubrange(_  bounds: Range<Int>) {
    precondition(
      bounds.lowerBound >= 0 && bounds.upperBound <= _count,
      "Subrange out of bounds")
    guard !bounds.isEmpty else { return }
    unsafe _storage.extracting(bounds).deinitialize()
    _closeGap(at: bounds.lowerBound, count: bounds.count)
    _count -= bounds.count
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds of the
  ///   range must be valid indices of the array.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    // FIXME: Remove this in favor of a standard algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SpanAvailability 1.0, *)
extension RigidArray where Element: ~Copyable {
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  public mutating func consumeAll() -> InputSpan<Element> {
    let span = InputSpan(buffer: _items, initializedCount: self.count)
    self._count = 0
    return _overrideLifetime(span, mutating: &self)
  }

  @_lifetime(&self)
  @_alwaysEmitIntoClient
  public mutating func consumeLast(_ count: Int) -> InputSpan<Element> {
    precondition(count >= 0, "Cannot consume a negative number of items")
    let c = Swift.min(count, self.count)
    self._count &-= c
    let span = InputSpan(
      buffer: self._storage._extracting(first: c),
      initializedCount: c)
    return _overrideLifetime(span, mutating: &self)
  }

  @_alwaysEmitIntoClient
  public mutating func consumeSubrange<E: Error, Result: ~Copyable>(
    _ bounds: Range<Int>,
    consumingWith body: (inout InputSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    precondition(
      bounds.lowerBound >= 0 && bounds.upperBound <= _count,
      "Subrange out of bounds")
    guard !bounds.isEmpty else {
      var span = InputSpan<Element>()
      return try body(&span)
    }
    let buffer = unsafe _storage.extracting(bounds)
    var span = InputSpan(buffer: buffer, initializedCount: buffer.count)
    defer {
      let remainder = span.finalize(for: buffer)
      buffer._extracting(last: remainder).deinitialize()
      _closeGap(at: bounds.lowerBound, count: bounds.count)
      _count -= bounds.count
      span = InputSpan()
    }
    return try body(&span)
  }
}
#endif

@available(SpanAvailability 1.0, *)
extension RigidArray where Element: ~Copyable {
  /// Removes and returns the last element of the array, if there is one.
  ///
  /// - Returns: The last element of the array if the array is not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isEmpty { return nil }
    return removeLast()
  }
}

#endif
