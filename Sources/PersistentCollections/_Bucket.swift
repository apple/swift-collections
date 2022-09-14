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

/// Identifies an entry in the hash table inside a node.
/// (Internally, a number between 0 and 31.)
@usableFromInline
@frozen
internal struct _Bucket {
  @usableFromInline
  internal var value: UInt

  @inlinable @inline(__always)
  internal init(_ value: UInt) { self.value = value }

  @inlinable @inline(__always)
  static var bitWidth: Int { _Bitmap.capacity.trailingZeroBitCount }

  @inlinable @inline(__always)
  static var bitMask: UInt { UInt(bitPattern: _Bitmap.capacity) &- 1 }

  @inlinable @inline(__always)
  static var invalid: _Bucket { _Bucket(.max) }
}

extension _Bucket: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }
}

extension _Bucket: Comparable {
  @inlinable @inline(__always)
  internal static func <(left: Self, right: Self) -> Bool {
    left.value < right.value
  }
}
