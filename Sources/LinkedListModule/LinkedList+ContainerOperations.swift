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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @inlinable
  @inline(always)
  public var isEmpty: Bool {
    self._count == 0
  }

  @inlinable
  @inline(always)
  public var count: Int {
    _assumeNonNegative(self._count)
  }

  @inlinable
  public var startIndex: Index {
    unsafe self._index(previousNode: nil, offset: 0)
  }

  @inlinable
  public var endIndex: Index {
    unsafe self._index(previousNode: _last, offset: self.count)
  }

  @_alwaysEmitIntoClient
  @discardableResult
  package func _advanceIfNotAtEnd(_ index: inout Index) -> UnsafeMutablePointer<_Node>? {
    guard let node = unsafe _currentNode(of: index) else { return nil }
    unsafe index._previousNode = node
    index._offset &+= 1
    return unsafe node
  }

  /// - Returns: The current node of the original index.
  @_alwaysEmitIntoClient
  @discardableResult
  package func _advance(_ index: inout Index) -> UnsafeMutablePointer<_Node> {
    guard let node = unsafe _advanceIfNotAtEnd(&index) else {
      preconditionFailure("Cannot advance index beyond the end of the container")
    }
    return unsafe node
  }

  @inlinable
  @inline(always)
  public func index(after index: Index) -> Index {
    var index = index
    unsafe _advance(&index)
    return index
  }

  @inlinable
  @inline(always)
  public func formIndex(after index: inout Index) {
    unsafe _advance(&index)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(n >= 0, "Only BidirectionalContainer indices can be advanced by a negative amount")
    precondition(_isValid(index), "Invalid index")
    let end = index._offset + n
    precondition(end <= self.count, "Cannot advance index beyond the end of the container")
    // FIXME: Implement directly instead of calling _advance
    var index = index
    while index._offset < end {
      unsafe _advance(&index)
    }
    return index
  }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    precondition(n >= 0, "Only BidirectionalContainer indices can be advanced by a negative amount")
    precondition(_isValid(index), "Invalid index")
    while n > 0, index != limit {
      unsafe _advance(&index)
      n &-= 1
    }
  }

  @_alwaysEmitIntoClient
  @inline(always)
  public func distance(from start: Index, to end: Index) -> Int {
    precondition(_isValid(start) && _isValid(end), "Invalid index")
    return end._offset - start._offset
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public borrowing func nextSpan(after index: inout Index) -> Span<Element> {
    guard let node = unsafe _advanceIfNotAtEnd(&index) else { return Span() }
    let span = unsafe node._pointee.span // FIXME: This needed a borrow accessor (rdar://192423713)
    return unsafe _overrideLifetime(span, borrowing: self)
  }

  #if false // FIXME: This should work, but we can't override the lifetime of the MutableSpan retrieved from behind a pointer
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(after index: inout Index) -> MutableSpan<Element> {
    let node = unsafe _advance(&index)
    return unsafe _overrideLifetime(node._pointee.mutableSpan, mutating: &self)
  }
  #endif

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index,
    maxCount: Int,
    limitedBy limit: Index
  ) -> Span<Element> {
    precondition(_isValid(limit), "Invalid index")
    let node = unsafe _currentNode(of: index)
    guard limit._offset != index._offset else { return Span() }
    guard let node = unsafe node else { return Span() }
    unsafe index._previousNode = node
    index._offset &+= 1
    return unsafe _overrideLifetime(
      node._pointee.span, // FIXME: This needed a borrow accessor (rdar://192423713)
      borrowing: self)
  }

  @_alwaysEmitIntoClient
  public subscript(index: Index) -> Element {
    @inline(always)
    @_unsafeSelfDependentResult
    borrow {
      guard let node = unsafe _currentNode(of: index) else {
        preconditionFailure("Index out of bounds")
      }
      return unsafe node._pointee._value!
    }

    @inline(always)
    @_unsafeSelfDependentResult
    mutate {
      guard let node = unsafe _currentNode(of: index) else {
        preconditionFailure("Index out of bounds")
      }
      return unsafe &node._pointee._value!
    }
  }

  @_alwaysEmitIntoClient
  public mutating func swapAt(_ i: Index, _ j: Index) {
    switch unsafe (_currentNode(of: i), _currentNode(of: j)) {
    case let (left?, right?):
      guard i._offset != j._offset else { return }
      unsafe swap(&left.pointee, &right.pointee)
    default:
      preconditionFailure("Index out of bounds")
    }
  }
}
#endif
