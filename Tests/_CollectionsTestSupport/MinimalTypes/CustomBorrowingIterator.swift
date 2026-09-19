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

import XCTest

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import ContainersPreview
import BasicContainers
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
package struct CustomBorrowingIterator<Element: ~Copyable, Failure: Error>: ~Copyable {
  package let _underestimatedCount: Int
  package let _generator: (Int) throws(Failure) -> Element?
  package var _offset: Int
  package var _scratch: RigidArray<Element>
  package var _pendingError: Failure?

  package init(
    underestimatedCount: Int = 0,
    chunkSize: Int,
    generatingWith generator: borrowing @escaping (Int) throws(Failure) -> Element?
  ) {
    self._underestimatedCount = underestimatedCount
    self._generator = copy generator
    self._offset = 0
    self._scratch = RigidArray(capacity: chunkSize)
    self._pendingError = nil
  }

  package var offset: Int { _offset }
}


@available(SwiftStdlib 5.0, *)
extension CustomBorrowingIterator: BorrowingIteratorProtocol where Element: ~Copyable {
  @_lifetime(&self)
  package mutating func nextSpan(maxCount: Int) throws(Failure) -> Span<Element> {
    // Errors must only be thrown before we have generated any items, or the abstraction gets broken.
    if let error = _pendingError.take() { throw error }
    _scratch.removeAll()
    let c = Swift.min(maxCount, _scratch.capacity)
    try _scratch.append(addingCount: c) { target throws(Failure) in
      while !target.isFull {
        do throws(Failure) { // FIXME: Why is this necessary?
          guard let next = try _generator(_offset) else { return }
          target.append(next)
          _offset += 1
        } catch {
          guard !target.isEmpty else { throw error }
          _pendingError = error
          return
        }
      }
    }
    return _scratch.span
  }

  package mutating func skip(by maxOffset: Int) throws(Failure) -> Int {
    // Note: we still generate items, so that we throw when expected.
    var c = 0
    while c < maxOffset {
      guard let _ = try _generator(_offset) else { break }
      _offset += 1
      c += 1
    }
    return c
  }
}

#endif
