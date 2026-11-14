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
  package static var empty: Self { Self(_bits: 0) }

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
  package mutating func bump() {
    _bits &+= 1
    if _bits & Self._localMask == 0 {
      _bits = Self._globalCounter.wrappingAdd(
        Self._globalIncrement, ordering: .relaxed
      ).newValue
      precondition(_bits != 0, "Linked list version overflow")
    }
  }
}

#endif
