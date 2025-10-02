//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  /// Round up `self` to the nearest power of two, assuming it's representable.
  /// Returns 0 if `self` isn't positive.
  @inlinable
  package func _roundUpToPowerOfTwo() -> Self {
    guard self > 0 else { return 0 }
    let l = Self.bitWidth - (self &- 1).leadingZeroBitCount
    return 1 << l
  }
}
