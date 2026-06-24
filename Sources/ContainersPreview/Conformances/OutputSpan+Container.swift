//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
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

#if compiler(>=6.2) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension OutputSpan: RandomAccessContainer, MutableContainer
where Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @inline(__always)
  public var startIndex: Index { 0 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var endIndex: Index { count }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maximumCount > 0, "maximumCount must be positive")
    let limit = Swift.min(count &- index, maximumCount)
    return self.span.extracting(unchecked: Range(uncheckedBounds: (index, limit)))
  }

  @inlinable
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Index, maximumCount: Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maximumCount > 0, "maximumCount must be positive")
    let limit = Swift.min(count &- index, maximumCount)
    return self.mutableSpan._consumingExtracting(Range(uncheckedBounds: (index, limit)))
  }

  @inlinable
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maximumCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maximumCount > 0, "maximumCount must be positive")
    let limit = Swift.max(0, index - maximumCount)
    return self.span.extracting(unchecked: Range(uncheckedBounds: (limit, index)))
  }
}
#endif
