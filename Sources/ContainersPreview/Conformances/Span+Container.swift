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

#if compiler(>=6.4) && UnstableContainersPreview

extension Span: RandomAccessContainer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var startIndex: Int {
    0
  }

  @_alwaysEmitIntoClient
  public var endIndex: Int {
    count
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int, maximumCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maximumCount > 0, "maximumCount must be positive")
    let limit = index &+ Swift.min(maximumCount, count &- index)
    return self.extracting(unchecked: Range(uncheckedBounds: (index, limit)))
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maximumCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maximumCount > 0, "maximumCount must be positive")
    let limit = index &- Swift.min(maximumCount, index)
    return self.extracting(unchecked: Range(uncheckedBounds: (limit, index)))
  }
}

#endif
