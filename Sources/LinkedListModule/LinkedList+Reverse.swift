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
import SpanPreview
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  /// Reverse the order of items in this list, by rearranging its nodes.
  ///
  /// - Note: unlike `MutableContainer` algorithms, this operation
  ///    invalidates all previously vended indices.
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func reverse() {
    self._version.bump()
    var prev: UnsafeMutablePointer<_Node>? = nil
    var next = unsafe _first
    while let n = unsafe next {
      unsafe next = exchange(&n.pointee.next, with: prev)
      unsafe prev = n
    }
    unsafe precondition(prev == _last)
    unsafe swap(&self._first, &self._last)
  }

  /// Reverse the order of items in the given subrange of this list,
  /// by rearranging the nodes contained within it.
  ///
  /// - Note: unlike `MutableContainer` algorithms, this operation
  ///    invalidates all previously vended indices.
  ///
  /// - Returns: A valid index range in the resulting list addressing the
  ///     items that got reversed.
  /// - Complexity: O(`range.count`)
  @_alwaysEmitIntoClient
  public mutating func reverseSubrange(_ range: Range<Index>) -> Range<Index> {
    var range = range
    var extract = self.extract(&range)
    extract.reverse()
    return self.insert(consuming: extract, at: range.lowerBound)
  }
}
#endif
