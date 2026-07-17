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

  func spanBoundary(before index: Index, maxDistance: Int) -> Index?

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
  public func spanBoundary(before index: Index) -> Index? {
    self.spanBoundary(before: index, maxDistance: Int.max)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Index) -> Span<Element> {
    previousSpan(before: &index, maxCount: Int.max)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Index, maxCount: Int
  ) -> Span<Element> {
    guard let i = spanBoundary(before: index, maxDistance: maxCount) else {
      return .init()
    }
    var j = i
    let span = nextSpan(after: &j, maxCount: maxCount)
    precondition(j == index, "Invalid BidirectionalContainer")
    index = i
    return span
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Index,
    limitedBy limit: Index
  ) -> Span<Element> {
    var j = index
    let span = self.previousSpan(before: &j)
    if limit <= index, limit > j {
      let d = self.distance(from: limit, to: index)
      index = limit
      return span.extracting(last: d)
    }
    index = j
    return span
  }
}

@available(SwiftStdlib 6.4, *)
extension BidirectionalContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  public func formIndex(before i: inout Index) {
    i = self.index(before: i)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    var index = index
    var n = n
    if n >= 0 {
      while n > 0 {
        self.formIndex(after: &index)
        n &-= 1
      }
    } else {
      while n < 0 {
        self.formIndex(before: &index)
        n &+= 1
      }
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
        var j = index
        let c = self.nextSpan(after: &j, limitedBy: limit).count
        if c == 0 {
          // We hit the limit (or the end)
          break
        }
        if c > n {
          index = self.index(index, offsetBy: n)
          n = 0
          break
        }
        index = j
        n &-= c
      }
      return
    }
    // Note: Don't negate `n` -- it may be `Int.min`.
    while n < 0 {
      let c = self.previousSpan(before: &index, limitedBy: limit).count
      if c == 0 {
        // We hit the limit (or the start)
        return
      }
      n &+= c
      if n > 0 {
        index = self.index(index, offsetBy: n)
        n = 0
        return
      }
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

// FIXME: Add ambiguity resolvers against BidirectionCollection algorithms.

#endif
