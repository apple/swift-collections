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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Removes and returns the element at the specified position.
  ///
  /// Existing elements in the deque's storage are moved as needed to close the
  /// gap left by the removed item. (The direction of the move depends on the
  /// location of the removal, minimizing the cost.)
  ///
  /// - Parameter i: The position of the element to remove. `index` must be
  ///   a valid index of the deque that is not equal to the end index.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`count`)
  @discardableResult
  @_alwaysEmitIntoClient
  public mutating func remove(at index: Int) -> Element {
    _checkItemIndex(index)
    return _handle.uncheckedRemove(at: index)
  }
  
  /// Removes all elements from the deque, preserving its allocated capacity.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeAll() {
    _handle.uncheckedRemoveAll()
  }
  
  /// Removes and returns the first element of the deque.
  ///
  /// The deque must not be empty.
  ///
  /// - Returns: The first element of the original deque.
  ///
  /// - Complexity: O(1)
  @discardableResult
  @_alwaysEmitIntoClient
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty RigidDeque")
    return _handle.uncheckedRemoveFirst()
  }
  
  /// Removes and returns the last element of the deque.
  ///
  /// The deque must not be empty.
  ///
  /// - Returns: The last element of the original deque.
  ///
  /// - Complexity: O(1)
  @discardableResult
  @_alwaysEmitIntoClient
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty RigidDeque")
    return _handle.uncheckedRemoveLast()
  }
  
  /// Removes and discards the specified number of elements from the start of
  /// the deque.
  ///
  /// Attempting to remove more elements than exist in the deque
  /// triggers a runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the deque.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///   the count of the deque.
  ///
  /// - Complexity: O(`k`)
  @_alwaysEmitIntoClient
  public mutating func removeFirst(_ k: Int) {
    precondition(k >= 0, "Cannot remove a negative number of elements")
    precondition(k <= count, "Cannot remove more elements than there are in the container")
    _handle.uncheckedRemoveFirst(k)
  }
  
  /// Removes and discards the specified number of elements from the end of the
  /// deque.
  ///
  /// Attempting to remove more elements than exist in the deque
  /// triggers a runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the deque.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///   the count of the deque.
  ///
  /// - Complexity: O(`k`)
  @_alwaysEmitIntoClient
  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Cannot remove a negative number of elements")
    precondition(n <= count, "Cannot remove more elements than there are in the container")
    _handle.uncheckedRemoveLast(n)
  }
  
  /// Removes the specified subrange of elements from the deque.
  ///
  /// - Parameter bounds: The subrange to remove. The bounds of the
  ///   range must be valid indices of the deque.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    precondition(
      bounds.lowerBound >= 0 && bounds.upperBound <= count,
      "Subrange out of bounds")
    _handle.uncheckedRemove(offsets: bounds)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Removes and returns the first element of the deque, if there is one.
  ///
  /// - Returns: The first element of the original deque if it was not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveFirst()
  }

  /// Removes and returns the last element of the deque, if there is one.
  ///
  /// - Returns: The last element of the original deque if it was not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveLast()
  }
}

#endif
