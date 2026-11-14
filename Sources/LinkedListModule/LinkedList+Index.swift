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
  @frozen
  @safe
  public struct Index {
    @usableFromInline
    package var _version: _LinkedListVersion

    @usableFromInline
    package var _previousNode: UnsafeMutablePointer<_Node>?

    @usableFromInline
    package var _offset: Int

    @_alwaysEmitIntoClient
    package init(
      _version: _LinkedListVersion,
      previousNode: UnsafeMutablePointer<_Node>?,
      offset: Int
    ) {
      self._version = _version
      unsafe self._previousNode = previousNode
      self._offset = offset
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _index(
    previousNode: UnsafeMutablePointer<_Node>?, offset: Int
  ) -> Index {
    unsafe assert(offset == 0 || previousNode != nil)
    return unsafe Index(
      _version: self._version, previousNode: previousNode, offset: offset)
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _isValid(_ index: Index) -> Bool {
    index._version == self._version
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _currentNode(of index: Index) -> UnsafeMutablePointer<_Node>? {
    precondition(_isValid(index), "Invalid index")
    guard let prev = unsafe index._previousNode else {
      return unsafe _first
    }
    return unsafe prev.pointee.next
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.Index: Equatable where Element: ~Copyable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    precondition(
      left._version == right._version,
      "Cannot compare indices from different containers")
    return left._offset == right._offset
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.Index: Comparable where Element: ~Copyable {
  @inlinable
  public static func <(left: Self, right: Self) -> Bool {
    precondition(
      left._version == right._version,
      "Cannot compare indices from different containers")
    return left._offset < right._offset
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.Index: Hashable where Element: ~Copyable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_offset)
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.Index: CustomDebugStringConvertible where Element: ~Copyable {
  public var debugDescription: String {
    "@\(_offset):\(_version)"
  }
}


#endif
