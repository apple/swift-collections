//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An abstract representation of a hash value.
@usableFromInline
@frozen
internal struct _HashValue {
  @usableFromInline
  internal var value: UInt

  @inlinable
  internal init<Key: Hashable>(_ key: Key) {
    let hashValue = key._rawHashValue(seed: 0)
    self.value = UInt(bitPattern: hashValue)
  }
}

extension _HashValue: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }
}
