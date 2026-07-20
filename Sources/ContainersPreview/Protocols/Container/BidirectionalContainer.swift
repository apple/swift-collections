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

@available(SwiftStdlib 6.4, *)
public protocol BidirectionalContainer<Element>: Container, ~Copyable, ~Escapable
where Element: ~Copyable, Index: Comparable
{
  override associatedtype Element: ~Copyable
  override associatedtype Index

  // Note: Some `Container` requirements are redeclared as `override`s to help
  // associated type inference; others are kept separate with `@_nonoverride`.
  //
  // @_nonoverride creates separate witness table entries, allowing divergent
  // implementations in conditional conformances. This enables conforming types
  // to provide distinct implementations depending on whether the caller is
  // generic over `Container` or `BidirectionalContainer`.
  //
  // (Unfortunately, neither `override` nor `@_nonoverride` allows callers
  // that are generic over `Container` to automatically dispatch
  // to a more constrained bidirectional implementation variant. Still, at least
  // `@_nonoverride` enables more refined implementations to take effect
  // when the caller is explicitly generic over `BidirectionalContainer`.)
  //
  // `@_nonoverride` should be used on requirements with new semantic
  // constraints in refining protocols.
  //
  // Collection types usually do not come with conditional conformances to
  // refining collection protocols (as the resulting behavior can be quite
  // confusing), so the separate witness entries rarely if ever get exercised
  // in practice. I don't expect things would be different with Container.
  //
  // FIXME: Consider avoiding using `@_nonoverride`, reducing witness sizes.

  func index(before i: Index) -> Index

  func formIndex(before i: inout Index)

  func spanBoundary(before index: Index) -> (index: Index, distance: Int)

  func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int)

  override func index(after index: Index) -> Index

  override func formIndex(after index: inout Index)

  @_nonoverride func index(_ index: Index, offsetBy n: Int) -> Index

  @_nonoverride func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  )

  @_nonoverride func distance(from start: Index, to end: Index) -> Int
}

@available(SwiftStdlib 6.4, *)
extension BidirectionalContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public func spanBoundary(
    before index: Index
  ) -> (index: Index, distance: Int) {
    self.spanBoundary(
      before: index,
      maxDistance: Int.max,
      limitedBy: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public func spanBoundary(
    before index: Index,
    maxDistance: Int
  ) -> (index: Index, distance: Int) {
    self.spanBoundary(
      before: index,
      maxDistance: maxDistance,
      limitedBy: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Index,
    maxCount: Int = Int.max
  ) -> Span<Element> {
    self.previousSpan(
      before: &index,
      maxCount: maxCount,
      limitedBy: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Index,
    maxCount: Int = Int.max,
    limitedBy limit: Index
  ) -> Span<Element> {
    let (i, d) = spanBoundary(before: index, maxDistance: maxCount, limitedBy: limit)
    if d == 0 { return .init() }
    var j = i
    let span = nextSpan(after: &j, limitedBy: index)
    precondition(j == index && span.count <= maxCount, "Invalid BidirectionalContainer")
    index = i
    return span
  }
}

@available(SwiftStdlib 6.4, *)
extension BidirectionalContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  public func index(before i: Index) -> Index {
    self.spanBoundary(before: i, maxDistance: 1).index
  }

  @_alwaysEmitIntoClient
  public func formIndex(before i: inout Index) {
    i = self.index(before: i)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    var index = index
    var n = n
    let end = self.endIndex
    if n >= 0 {
      while n > 0 {
        let c = self.nextSpan(after: &index, maxCount: n, limitedBy: end).count
        precondition(c > 0, "Cannot advance index beyond the end of the container")
        n &-= c
      }
      return index
    }
    n = -n
    while n > 0 {
      let r = self.spanBoundary(before: index, maxDistance: n, limitedBy: end)
      index = r.index
      n &-= r.distance
    }
    return index
  }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    var n = n
    if n >= 0 {
      while n > 0 {
        let c = self.nextSpan(after: &index, maxCount: n, limitedBy: limit).count
        precondition(c <= n, "Invalid container")
        guard c > 0 else { break }
        n &-= c
      }
      return
    }
    n = -n
    while n > 0 {
      let r = self.spanBoundary(before: index, maxDistance: n, limitedBy: limit)
      if r.distance == 0 {
        // We hit the limit (or the start)
        return
      }
      n &+= r.distance
      index = r.index
    }
  }

  @_alwaysEmitIntoClient
  public func index(
    _ index: Index, offsetBy n: Int, limitedBy limit: Index
  ) -> Index? {
    var index = index
    var n = n
    self.formIndex(&index, offsetBy: &n, limitedBy: limit)
    if n != 0 { return nil }
    return index
  }

  // Note: `distance(from:to:)` comes from `Container where Index: Comparable`.
}

extension Strideable {
  @_alwaysEmitIntoClient
  package func _clampedUp(
    towards boundary: Self, maxDistance: Stride, limitedBy limit: Self
  ) -> Self {
    assert(self <= boundary)
    assert(maxDistance >= 0)
    let limit = (limit >= self ? Swift.min(limit, boundary) : boundary)
    if limit.distance(to: self) <= maxDistance {
      return limit
    }
    return self.advanced(by: maxDistance)
  }

  @_alwaysEmitIntoClient
  package func _clampedDown(
    towards boundary: Self, maxDistance: Stride, limitedBy limit: Self
  ) -> Self {
    assert(self >= boundary)
    assert(maxDistance >= 0)
    let limit = (limit <= self ? Swift.max(limit, boundary) : boundary)
    if self.distance(to: limit) <= maxDistance {
      return limit
    }
    return self.advanced(by: -maxDistance)
  }
}

// FIXME: Add ambiguity resolvers against BidirectionCollection algorithms.

#endif
