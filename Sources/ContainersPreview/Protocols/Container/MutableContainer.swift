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
public protocol MutableContainer<Element>:
  PermutableContainer, ~Copyable, ~Escapable
where
  Element: ~Copyable
{
  //  subscript(index: Index) -> Element { borrow mutate }

  @_lifetime(&self)
  mutating func nextMutableSpan(
    after index: inout Index,
    maximumCount: Int
  ) -> MutableSpan<Element>

  // FIXME: What about previousMutableSpan?
}

@available(SwiftStdlib 5.0, *)
extension MutableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  @_lifetime(&self)
  mutating func nextMutableSpan(
    after index: inout Index,
  ) -> MutableSpan<Element> {
    nextMutableSpan(after: &index, maximumCount: Int.max)
  }
}

#endif
