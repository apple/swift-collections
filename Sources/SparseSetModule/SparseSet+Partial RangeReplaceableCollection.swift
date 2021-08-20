//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SparseSet {
  /// Removes all keys and their associated values from the sparse set.
  ///
  /// - Parameter keepingCapacity: If `true` then the underlying storage's
  ///   capacity is preserved. The default is `false`.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeAll(keepingCapacity: Bool = false) {
    _dense.removeAll(keepingCapacity: keepingCapacity)
    if !keepingCapacity {
      _sparse = _SparseStorage(withCapacity: 0)
    }
    _checkInvariants()
  }

  /// Removes and returns the element at the specified position.
  ///
  /// Calling this method will invalidate existing indices. When a non-final
  /// element is removed the final element is moved to fill the resulting gap.
  ///
  /// - Parameter index: The position of the element to remove. `index` must be
  ///   a valid index of the collection that is not equal to the collection's
  ///   end index.
  ///
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(1)
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    let existing = _remove(at: index)
    return existing
  }

  /// Removes the specified subrange of elements from the collection.
  ///
  /// Calling this method will invalidate existing indices. When a non-final
  /// subrange is removed the resulting gap is filled or closed by moving the
  /// required number of elements (in an order preserving fashion) from the end
  /// of the collection.
  ///
  /// - Parameter bounds: The subrange of the collection to remove. The bounds
  ///   of the range must be valid indices of the collection.
  ///
  /// - Complexity: O(`bounds.count`)
  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    guard !bounds.isEmpty else { return }
    defer { _checkInvariants() }
    let finalSegment = bounds.endIndex ..< _dense.keys.endIndex
    let regionToMove: Range<Int>?
    if bounds.count <= finalSegment.count {
      regionToMove = finalSegment.endIndex - bounds.count ..< finalSegment.endIndex
    } else if !finalSegment.isEmpty {
      regionToMove = finalSegment
    } else {
      regionToMove = nil
    }
    if let regionToMove = regionToMove {
      _ensureUnique()
      _dense.keys.withUnsafeMutableBufferPointer { ptr in
        ptr.baseAddress!.advanced(by: bounds.startIndex)
          .assign(from: ptr.baseAddress!.advanced(by: regionToMove.startIndex),
                  count: regionToMove.count)
      }
      _dense.values.withUnsafeMutableBufferPointer { ptr in
        ptr.baseAddress!.advanced(by: bounds.startIndex)
          .assign(from: ptr.baseAddress!.advanced(by: regionToMove.startIndex),
                  count: regionToMove.count)
      }
      for (i, key) in _dense.keys[regionToMove].enumerated() {
        _sparse[key] = bounds.startIndex + i
      }
    }
    _dense.keys.removeLast(bounds.count)
    _dense.values.removeLast(bounds.count)
  }

  /// Removes the specified subrange of elements from the collection.
  ///
  /// Calling this method will invalidate existing indices. When a non-final
  /// subrange is removed the resulting gap is filled or closed by moving the
  /// required number of elements (in an order preserving fashion) from the end
  /// of the collection.
  ///
  /// - Parameter bounds: The subrange of the collection to remove. The bounds
  ///   of the range must be valid indices of the collection.
  ///
  /// - Complexity: O(`bounds.count`)
  @inlinable
  public mutating func removeSubrange<R: RangeExpression>(
    _ bounds: R
  ) where R.Bound == Int {
    removeSubrange(bounds.relative(to: _dense.keys))
  }

  /// Removes the last element of a non-empty sparse set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty collection")
    return remove(at: count - 1)
  }

  /// Removes the last `n` element of the sparse set.
  ///
  /// - Parameter n: The number of elements to remove from the collection.
  ///   `n` must be greater than or equal to zero and must not exceed the
  ///   number of elements in the collection.
  ///
  /// - Complexity: O(`n`)
  @inlinable
  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in the collection")
    _dense.keys.removeLast(n)
    _dense.values.removeLast(n)
    _checkInvariants()
  }

  /// Removes the first element of a non-empty sparse set.
  ///
  /// Calling this method will invalidate existing indices - the final element
  /// will be moved to fill the gap left by removing the first element.
  ///
  /// - Complexity: O(1)
  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty collection")
    return remove(at: 0)
  }

  /// Removes the first `n` elements of the sparse set.
  ///
  /// Calling this method will invalidate existing indices. The gap created by
  /// removing initial elements is filled or closed by moving the required
  /// number of elements (in an order preserving fashion) from the end of the
  /// collection.
  ///
  /// - Parameter n: The number of elements to remove from the collection.
  ///   `n` must be greater than or equal to zero and must not exceed the
  ///   number of elements in the set.
  ///
  /// - Complexity: O(`n`)
  @inlinable
  public mutating func removeFirst(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in the collection")
    removeSubrange(0..<n)
  }

  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a collection that meets
  /// particular criteria. The order of the remaining elements is preserved.
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the
  ///   sparse set as its argument and returns a Boolean value indicating
  ///   whether the element should be removed from the collection.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeAll(
    where shouldBeRemoved: (Self.Element) throws -> Bool
  ) rethrows {
    guard !isEmpty else { return }
    for i in (0 ..< count).reversed() {
      let element = (key: _dense.keys[i], value: _dense.values[i])
      if try shouldBeRemoved(element) {
        _remove(at: i)
      }
    }
  }
}
