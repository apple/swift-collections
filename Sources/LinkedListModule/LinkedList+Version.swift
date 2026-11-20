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

import Synchronization

#if compiler(>=6.4)
/// A relatively efficient 64-bit version number with reasonably good
/// expectations of uniqueness within a process.
///
/// This is a composite of two bitfields, a 16-bit local version, and
/// a 48-bit global version number:
///
///     b63:16                                           b15:0
///    ┌────────────────────────────────────────────────┬────────────────┐
///    │ Global version                                 │ Local version  │
///    └────────────────────────────────────────────────┴────────────────┘
///
/// The local version gets incremented with no synchronization.
/// The global version comes from a process-wide global counter, atomically
/// bumped every time the local field overflows.
///
/// When the global counter overflows, we randomly select a new value for it,
/// to avoid predictable collisions.
@available(SwiftStdlib 6.4, *)
@usableFromInline
@frozen
package struct _LinkedListVersion {
  @usableFromInline
  package static let _globalCounter: Atomic<UInt64> = .init(0)

  @usableFromInline
  package var _bits: UInt64

  @_alwaysEmitIntoClient
  @_transparent
  package init(_bits: UInt64) {
    self._bits = _bits
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion: Equatable {
  @_alwaysEmitIntoClient
  @_transparent
  package static func ==(left: Self, right: Self) -> Bool {
    left._bits == right._bits
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion: Hashable {
  @_alwaysEmitIntoClient
  @_transparent
  package func hash(into hasher: inout Hasher) {
    hasher.combine(_bits)
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion: CustomDebugStringConvertible {
  @usableFromInline
  package var debugDescription: String {
    "v\(String(_bits, radix: 16, uppercase: false))"
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion {
  /// The version number of the empty list.
  @_alwaysEmitIntoClient
  @_transparent
  package static var empty: Self { Self(_bits: .max) }

  /// A new, unique version number.
  @_alwaysEmitIntoClient
  @_transparent
  package static func new() -> Self {
    var new = self.empty
    new.bump()
    return new
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion {
  @_alwaysEmitIntoClient
  @_transparent
  package static var _localBitCount: UInt64 { 16 }

  @_alwaysEmitIntoClient
  @_transparent
  package static var _globalMask: UInt64 {
    UInt64.max &<< _localBitCount
  }

  @_alwaysEmitIntoClient
  @_transparent
  package static var _localMask: UInt64 {
    (1 &<< _localBitCount) &- 1
  }

  @_alwaysEmitIntoClient
  @_transparent
  package static var _globalIncrement: UInt64 {
    1 &<< _localBitCount
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion {
  @_alwaysEmitIntoClient
  @_transparent
  package var global: UInt64 {
    _bits & Self._globalMask
  }

  @_alwaysEmitIntoClient
  @_transparent
  package var local: UInt64 {
    _bits & Self._localMask
  }
}

@available(SwiftStdlib 6.4, *)
extension _LinkedListVersion {
  @inlinable
  @inline(always)
  package mutating func bump() {
    _bits &+= 1
    if _bits & Self._localMask == 0 {
      _slowBump()
    }
  }

  @inlinable
  @inline(never)
  package mutating func _slowBump() {
    var expected = Self._globalCounter.load(ordering: .relaxed)
    var done = false
    while true {
      let desired: UInt64
      if expected == Self._globalMask {
        // We've run out of bits; select a next version by random.
        var rng = SystemRandomNumberGenerator()
        desired = rng.next() & Self._globalMask
      } else {
        desired = expected &+ Self._globalIncrement
      }
      (done, expected) = Self._globalCounter.compareExchange(
        expected: expected,
        desired: desired,
        ordering: .relaxed)
      if done {
        _bits = desired
        break
      }
    }
  }
}

#endif
