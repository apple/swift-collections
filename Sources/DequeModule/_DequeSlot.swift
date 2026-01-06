//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
@frozen
internal struct _DequeSlot {
  @usableFromInline
  internal var position: Int

  @_alwaysEmitIntoClient
  @_transparent
  init(at position: Int) {
    assert(position >= 0)
    self.position = position
  }
}

extension _DequeSlot {
  @_alwaysEmitIntoClient
  @_transparent
  internal static var zero: Self { Self(at: 0) }

  @_alwaysEmitIntoClient
  @_transparent
  internal func advanced(by delta: Int) -> Self {
    Self(at: position &+ delta)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func orIfZero(_ value: Int) -> Self {
    guard position > 0 else { return Self(at: value) }
    return self
  }
}

extension _DequeSlot: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    "@\(position)"
  }
}

extension _DequeSlot: Equatable {
  @_alwaysEmitIntoClient
  @_transparent
  static func ==(left: Self, right: Self) -> Bool {
    left.position == right.position
  }
}

extension _DequeSlot: Comparable {
  @_alwaysEmitIntoClient
  @_transparent
  static func <(left: Self, right: Self) -> Bool {
    left.position < right.position
  }
}

extension Range where Bound == _DequeSlot {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _count: Int { upperBound.position - lowerBound.position }

  @_alwaysEmitIntoClient
  @_transparent
  internal var _offsets: Range<Int> {
    Range<Int>(uncheckedBounds: (lowerBound.position, upperBound.position))
  }
}
