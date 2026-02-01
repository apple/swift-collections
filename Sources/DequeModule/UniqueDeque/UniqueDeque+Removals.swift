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
extension UniqueDeque where Element: ~Copyable {
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
  @inline(__always)
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }
  
  /// Removes all elements from the deque, preserving its allocated capacity.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func removeAll() {
    _storage.removeAll()
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
  @inline(__always)
  public mutating func removeFirst() -> Element {
    _storage.removeFirst()
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
  @inline(__always)
  public mutating func removeLast() -> Element {
    _storage.removeLast()
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
  @inline(__always)
  public mutating func removeFirst(_ k: Int) {
    _storage.removeFirst(k)
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
  @inline(__always)
  public mutating func removeLast(_ k: Int) {
    _storage.removeLast(k)
  }
  
  /// Removes the specified subrange of elements from the deque.
  ///
  /// - Parameter bounds: The subrange to remove. The bounds of the
  ///   range must be valid indices of the deque.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Removes and returns the first element of the deque, if there is one.
  ///
  /// - Returns: The first element of the original deque if it was not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func popFirst() -> Element? {
    _storage.popFirst()
  }

  /// Removes and returns the last element of the deque, if there is one.
  ///
  /// - Returns: The last element of the original deque if it was not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func popLast() -> Element? {
    _storage.popLast()
  }
}

#endif
