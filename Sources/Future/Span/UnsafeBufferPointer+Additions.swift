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

extension UnsafeBufferPointer where Element: ~Copyable {
  /// Returns a Boolean value indicating whether two `UnsafeBufferPointer`
  /// instances refer to the same region in memory.
  @inlinable @inline(__always)
  public func isIdentical(to other: Self) -> Bool {
    unsafe (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  /// Returns a Boolean value indicating whether two
  /// `UnsafeMutableBufferPointer` instances refer to the same region in
  /// memory.
  @inlinable @inline(__always)
  public func isIdentical(to other: Self) -> Bool {
    unsafe (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}

extension UnsafeRawBufferPointer {
  /// Returns a Boolean value indicating whether two `UnsafeRawBufferPointer`
  /// instances refer to the same region in memory.
  @inlinable @inline(__always)
  public func isIdentical(to other: Self) -> Bool {
    unsafe (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}

extension UnsafeMutableRawBufferPointer {
  /// Returns a Boolean value indicating whether two
  /// `UnsafeMutableRawBufferPointer` instances refer to the same region in
  /// memory.
  @inlinable @inline(__always)
  public func isIdentical(to other: Self) -> Bool {
    unsafe (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}
