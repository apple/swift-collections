//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@available(SwiftCompatibilitySpan 5.0, *)
public protocol RandomAccessContainer: BidirectionalContainer, ~Copyable, ~Escapable {
  override associatedtype Element: ~Copyable
}

@available(SwiftCompatibilitySpan 5.0, *)
extension RandomAccessContainer
where Self: ~Copyable & ~Escapable, Index: Strideable, Index.Stride == Int
{
  @inlinable
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @inlinable
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @inlinable
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }
}

// Disambiguate parallel extensions on RandomAccessContainer and RandomAccessCollection

@available(SwiftCompatibilitySpan 5.0, *)
extension RandomAccessCollection
where
  Self: RandomAccessContainer,
  Index: Strideable,
  Index.Stride == Int,
  Indices == Range<Int>
{
  @inlinable
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @inlinable
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @inlinable
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }
}

extension Strideable {
  @inlinable
  public mutating func advance(by distance: inout Stride, limitedBy limit: Self) {
    if distance >= 0 {
      guard limit >= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.min(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    } else {
      guard limit <= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.max(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    }
  }
}

