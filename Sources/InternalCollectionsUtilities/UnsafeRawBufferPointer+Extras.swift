//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension UnsafeRawBufferPointer {
  /// Returns a Boolean value indicating whether two `UnsafeRawBufferPointer`
  /// instances refer to the same region in memory.
  @inlinable @inline(__always)
    package func _isIdentical(to other: Self) -> Bool {
    (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}
