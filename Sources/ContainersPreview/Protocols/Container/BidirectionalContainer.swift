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
where Element: ~Copyable, Index: Comparable
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

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    var i = self.index(alignedDown: start)
    let end = self.index(alignedDown: end)
    var d = 0
    if start <= end {
      // FIXME: Use bulk iteration here, with binary search within the final chunk.
      while i != end {
        self.formIndex(after: &i)
        d += 1
      }
    } else {
      // FIXME: Use bulk iteration here, with binary search within the final chunk.
      while i != end {
        self.formIndex(before: &i)
        d -= 1
      }
    }
    return d
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    var index = self.index(alignedDown: index)
    var n = n
    if n >= 0 {
      while n > 0 {
        let span = self.nextSpan(after: &index, maximumCount: n)
        precondition(
          !span.isEmpty,
          "Cannot advance index beyond the end of the container")
        n &-= span.count
      }
    } else {
      n = -n
      while n > 0 {
        let span = self.previousSpan(before: &index, maximumCount: n)
        precondition(
          !span.isEmpty,
          "Cannot advance index beyond the end of the container")
        n &-= span.count
      }
    }
    return index
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    index = self.index(alignedDown: index)
    var n = n
    let limit = self.index(alignedDown: limit)
    if n >= 0 {
      if index > limit {
        index = self.index(index, offsetBy: n)
        n = 0
        return
      }
      // Skip forward until we find our target or overshoot the limit.
      while n > 0 {
        var j = index
        let span = self.nextSpan(after: &j, maximumCount: n)
        precondition(
          !span.isEmpty,
          "Cannot advance index beyond the end of the container")
        if j > limit {
          break
        }
        index = j
        n &-= span.count
      }
      // Step through to find the precise target when we hit the limit.
      // FIXME: Figure out a way to use binary search here (with `index(_:offsetBy:)`)
      while n != 0 {
        if index == limit {
          return
        }
        formIndex(after: &index)
        n &-= 1
      }
      return
    }
    // n < 0
    if index < limit {
      index = self.index(index, offsetBy: n)
      n = 0
      return
    }
    // Skip backward until we find our target or overshoot the limit.
    while n < 0 {
      var j = index
      let span = self.previousSpan(before: &j, maximumCount: -n)
      precondition(
        !span.isEmpty,
        "Cannot move index before the start of the container")
      if j < limit {
        break
      }
      index = j
      n &+= span.count
    }
    // Step through to find the precise target when we hit the limit.
    // FIXME: Figure out a way to use binary search here (with `index(_:offsetBy:)`)
    while n != 0 {
      if index == limit {
        return
      }
      formIndex(before: &index)
      n &+= 1
    }
  }
}
#endif
