//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  /// Extract the members in a given subrange into a standalone list,
  /// de-linking them from this one.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameter subrange: The subrange of members to extract into a new list.
  ///     On return, this is set to the empty subrange addressing the location
  ///     of the removed items in `self`.
  /// - Returns: A new list composed of the members of the subrange.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func extract(
    _ subrange: inout Range<Index> 
  ) -> LinkedList {
    // FIXME: We want this to return a tuple of (Index, LinkedList), but we can't do that.
    let r = unsafe _extract(subrange)
    subrange = unsafe r.index ..< r.index
    return unsafe LinkedList(_first: r.first, last: r.last, count: r.count)
  }

  @_alwaysEmitIntoClient
  public mutating func extract(
    upTo index: Index
  ) -> LinkedList {
    let r = unsafe _extract(upTo: index)
    return unsafe LinkedList(_first: r.first, last: r.last, count: r.count)
  }

  @_alwaysEmitIntoClient
  public mutating func extract(
    from index: Index
  ) -> LinkedList {
    let r = unsafe _extract(from: index)
    return unsafe LinkedList(_first: r.first, last: r.last, count: r.count)
  }

  @_alwaysEmitIntoClient
  package mutating func _extract(
    _ subrange: Range<Index>
  ) -> (
    index: Index,
    first: UnsafeMutablePointer<_Node>?,
    last: UnsafeMutablePointer<_Node>?,
    count: Int
  ) {
    precondition(
      _isValid(subrange.lowerBound) && _isValid(subrange.upperBound),
      "Invalid subrange")
    switch (subrange.lowerBound._offset == 0, subrange.upperBound._offset == count) {
    case (false, false):
      break
    case (false, true):
      return unsafe _extract(from: subrange.lowerBound)
    case (true, false):
      return unsafe _extract(upTo: subrange.upperBound)
    case (true, true):
      return unsafe _extractAll()
    }

    self._version.bump()
    let i = unsafe subrange.lowerBound._withVersion(self._version)
    guard !subrange.isEmpty else {
      return (i, nil, nil, 0)
    }

    let lower = unsafe subrange.lowerBound._previousNode.unsafelyUnwrapped
    let last = unsafe subrange.upperBound._previousNode.unsafelyUnwrapped

    let tail = unsafe exchange(&last.pointee.next, with: nil)
    let first = unsafe exchange(&lower.pointee.next, with: tail)

    let c = subrange.upperBound._offset &- subrange.lowerBound._offset
    self._count &-= c

    return unsafe (i, first, last, c)
  }

  @_alwaysEmitIntoClient
  package mutating func _extractAll() -> (
    index: Index,
    first: UnsafeMutablePointer<_Node>?,
    last: UnsafeMutablePointer<_Node>?,
    count: Int
  ) {
    self._version.bump()
    return unsafe (
      index: self.startIndex,
      first: exchange(&self._first, with: nil),
      last: exchange(&self._last, with: nil),
      count: exchange(&self._count, with: 0))
  }

  @_alwaysEmitIntoClient
  package mutating func _extract(
    upTo index: Index
  ) -> (
    index: Index,
    first: UnsafeMutablePointer<_Node>?,
    last: UnsafeMutablePointer<_Node>?,
    count: Int
  ) {
    precondition(_isValid(index), "Invalid index")
    _version.bump()
    guard let last = unsafe index._previousNode else { // index == startIndex
      return (self.startIndex, nil, nil, 0)
    }
    guard unsafe last != self._last else { // index == endIndex
      return unsafe _extractAll()
    }
    self._count &-= index._offset

    let first = unsafe exchange(&self._first, with: exchange(&last.pointee.next, with: nil))

    return unsafe (self.startIndex, first, last, index._offset)
  }

  @_alwaysEmitIntoClient
  package mutating func _extract(
    from index: Index
  ) -> (
    index: Index,
    first: UnsafeMutablePointer<_Node>?,
    last: UnsafeMutablePointer<_Node>?,
    count: Int
  ) {
    precondition(_isValid(index), "Invalid index")
    _version.bump()
    guard let last = unsafe index._previousNode else { // index == startIndex
      return unsafe _extractAll()
    }
    guard unsafe last != self._last else { // index == endIndex
      return (self.endIndex, nil, nil, 0)
    }

    let c = self.count &- index._offset
    self._count = index._offset
    let f = unsafe exchange(&last.pointee.next, with: nil)
    let l = unsafe exchange(&self._last, with: last)
    return unsafe (index: self.endIndex, first: f, last: l, count: c)
  }
}
#endif
