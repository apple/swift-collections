//===--- SpanExtensions.swift ---------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

private let immortalThing: [Void] = []

@available(macOS 9999, *)
extension Span {

  @available(macOS 9999, *)
  public static var empty: Span {
    @lifetime(immortal)
    get {
      let empty = unsafe UnsafeBufferPointer<Element>(start: nil, count: 0)
      let span = Span(_unsafeElements: empty)
      return unsafe _overrideLifetime(span, borrowing: immortalThing)
    }
  }

  @available(macOS 9999, *)
  @lifetime(immortal)
  public init() {
    let empty = unsafe UnsafeBufferPointer<Element>(start: nil, count: 0)
    let span = Span(_unsafeElements: empty)
    self = unsafe _overrideLifetime(span, borrowing: immortalThing)
  }
}

@available(macOS 9999, *)
extension Span where Element: Equatable {

  /// Returns a Boolean value indicating whether this and another span
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A span to compare to this one.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: Self) -> Bool {
    guard count == other.count else { return false }
    if count == 0 { return true }

    //FIXME: This could be short-cut
    //       with a layout constraint where stride equals size,
    //       as long as there is at most 1 unused bit pattern.
    // if Element is BitwiseEquatable {
    // return _swift_stdlib_memcmp(lhs.baseAddress, rhs.baseAddress, count) == 0
    // }
    for o in 0..<count {
      if unsafe self[unchecked: o] != other[unchecked: o] { return false }
    }
    return true
  }

  /// Returns a Boolean value indicating whether this span and a Collection
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A Collection to compare to this span.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Collection<Element>) -> Bool {
    let equal = other.withContiguousStorageIfAvailable {
      _elementsEqual(Span(_unsafeElements: $0))
    }
    if let equal { return equal }

    guard count == other.count else { return false }
    if count == 0 { return true }

    return _elementsEqual(AnySequence(other))
  }

  /// Returns a Boolean value indicating whether this span and a Sequence
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A Sequence to compare to this span.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Sequence<Element>) -> Bool {
    var offset = 0
    for otherElement in other {
      if offset >= count { return false }
      if unsafe self[unchecked: offset] != otherElement { return false }
      offset += 1
    }
    return offset == count
  }
}
