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

#if COLLECTIONS_SINGLE_MODULE

#if compiler(>=6.2)
extension _HTable.BucketIterator {
  // FIXME: Remove after 27.0 releases
  @available(*, deprecated, renamed: "advanceToOccupied(maxCount:)")
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  internal mutating func advanceToOccupied(
    maximumCount: Int
  ) -> Bool {
    self.advanceToOccupied(maxCount: maximumCount)
  }

  // FIXME: Remove after 27.0 releases
  @available(*, deprecated, renamed: "advanceToUnoccupied(maxCount:)")
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  internal mutating func advanceToUnoccupied(
    maximumCount: Int
  ) -> Bool {
    self.advanceToUnoccupied(maxCount: maximumCount)
  }

  // FIXME: Remove after 27.0 releases
  @available(*, deprecated, renamed: "nextOccupiedRegion(maxCount:)")
  @usableFromInline
  @_lifetime(self: copy self)
  internal mutating func nextOccupiedRegion(
    maximumCount: Int
  ) -> Range<Bucket>? {
    self.nextOccupiedRegion(maxCount: maximumCount)
  }

  // FIXME: Remove after 27.0 releases
  @available(*, deprecated, renamed: "nextUnoccupiedRegion(maxCount:)")
  @usableFromInline
  @_lifetime(self: copy self)
  internal mutating func nextUnoccupiedRegion(
    maximumCount: Int
  ) -> Range<Bucket>? {
    self.nextUnoccupiedRegion(maxCount: maximumCount)
  }
}
#endif

#endif

