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
public protocol RandomAccessContainer<Element>
: BidirectionalContainer, ~Copyable, ~Escapable
where Element: ~Copyable {
  // Note: Some requirements are redeclared to help associated type inference;
  // others are kept separate with `@_nonoverride`.
  //
  // See more detailed discussion on `BidirectionalContainer`.
  //
  // `RandomAccessContainer` should technically redeclare single-steppers
  // like `index(after:)` as `@_nonoverride`, as the protocol adds a semantic
  // requirement for O(1) complexity. However, we emulate
  // `RandomAccessCollection`'s (not necessarily well-justified) decision to
  // leave these marked as overrides, forcing all types to have a single
  // implementation that fulfills the (unique) requirement. (I haven't seen a
  // case where these steppers would need to vary their implementation, while
  // offsetting/distance calculations do sometimes want that, at least in
  // theory. Not so much in practice though -- see e.g. `ZipSequence`'s lack of
  // a conditional (random-access) collection conformance.)
  //
  // FIXME: Consider avoiding using `@_nonoverride`, reducing witness sizes.

  override associatedtype Element: ~Copyable
  override associatedtype Index

  override func index(after index: Index) -> Index
  override func index(before index: Index) -> Index

  override func formIndex(after index: inout Index)
  override func formIndex(before index: inout Index)

  @_nonoverride func index(_ index: Index, offsetBy n: Int) -> Index

  @_nonoverride func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  )

  @_nonoverride func distance(from start: Index, to end: Index) -> Int
}

@available(SwiftStdlib 5.0, *)
extension RandomAccessCollection {
  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    let l = self.distance(from: index, to: limit)
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      index = limit
      n -= l
      return
    }
    formIndex(&index, offsetBy: n)
    n = 0
  }
}

@available(SwiftStdlib 6.4, *)
extension RandomAccessContainer
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable,
  Index: Strideable,
  Index.Stride == Int
{
  @_alwaysEmitIntoClient
  public var isEmpty: Bool { startIndex == endIndex }

  @_alwaysEmitIntoClient
  public var count: Int { startIndex.distance(to: endIndex) }

  @_alwaysEmitIntoClient
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @_alwaysEmitIntoClient
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @_alwaysEmitIntoClient
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @_alwaysEmitIntoClient
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @_alwaysEmitIntoClient
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }
}

@available(SwiftStdlib 6.4, *)
extension RandomAccessContainer
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable,
  Index == Int
{
  @_alwaysEmitIntoClient
  @inline(__always)
  public var isEmpty: Bool { startIndex == endIndex }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var count: Int { endIndex - startIndex }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index + 1
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index - 1
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index += 1
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index -= 1
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    end - start
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index + n
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }
}

// Disambiguate parallel extensions on RandomAccessContainer and RandomAccessCollection

@available(SwiftStdlib 6.4, *)
extension RandomAccessCollection
where
  Self: RandomAccessContainer,
  Index: Strideable,
  Index.Stride == Int,
  Indices == Range<Int>
{
  @_alwaysEmitIntoClient
  public var isEmpty: Bool { startIndex == endIndex }

  @_alwaysEmitIntoClient
  public var count: Int { endIndex - startIndex }

  @_alwaysEmitIntoClient
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @_alwaysEmitIntoClient
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @_alwaysEmitIntoClient
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @_alwaysEmitIntoClient
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @_alwaysEmitIntoClient
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }
}

#endif
