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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol BidirectionalContainer<Element>: Container, ~Copyable, ~Escapable
where Element: ~Copyable
{
  func index(before i: Index) -> Index

  func formIndex(before i: inout Index)

  @_lifetime(borrow self)
  func previousSpan(before index: inout Index, maximumCount: Int) -> Span<Element>
}

@available(SwiftStdlib 5.0, *)
extension BidirectionalContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public func formIndex(before i: inout Index) {
    i = self.index(before: i)
  }

  @inlinable
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Index) -> Span<Element> {
    previousSpan(before: &index, maximumCount: Int.max)
  }
}
#endif
