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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

// FIXME: Figure out if it would be possible to add the container-based
// `relative(to:)` to the existing `RangeExpression`.
@available(SwiftStdlib 5.0, *)
public protocol RangeExpression2<Bound> {
  associatedtype Bound: Comparable

  func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound

  func contains(_ element: Bound) -> Bool
}

@available(SwiftStdlib 5.0, *)
extension Range: RangeExpression2 {
  @inlinable
  public func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound {
    self
  }
}

@available(SwiftStdlib 5.0, *)
extension ClosedRange: RangeExpression2 {
  @inlinable
  public func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound {
    let end = container.index(after: self.upperBound)
    return self.lowerBound ..< end
  }
}

@available(SwiftStdlib 5.0, *)
extension PartialRangeFrom: RangeExpression2 {
  @inlinable
  public func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound {
    self.lowerBound ..< container.endIndex
  }
}

@available(SwiftStdlib 5.0, *)
extension PartialRangeUpTo: RangeExpression2 {
  @inlinable
  public func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound {
    return container.startIndex ..< self.upperBound
  }
}

@available(SwiftStdlib 5.0, *)
extension PartialRangeThrough: RangeExpression2 {
  @inlinable
  public func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound {
    let end = container.index(after: self.upperBound)
    return container.startIndex ..< end
  }
}
#endif
