//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension UnsafeBufferPointer {
  @inlinable
  @inline(__always)
  package func _ptr(at index: Int) -> UnsafePointer<Element> {
    assert(index >= 0 && index < count)
    return baseAddress.unsafelyUnwrapped + index
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  /// Returns a Boolean value indicating whether two `UnsafeBufferPointer`
  /// instances refer to the same region in memory.
  @inlinable @inline(__always)
  package func _isIdentical(to other: Self) -> Bool {
    (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  /// Returns a buffer pointer containing the initial elements of this buffer,
  /// up to the specified maximum length.
  ///
  /// If the maximum length exceeds the length of this buffer pointer,
  /// then the result contains all the elements.
  ///
  /// The returned buffer's first item is always at offset 0; unlike buffer
  /// slices, extracted buffers do not share their indices with the
  /// buffer from which they are extracted.
  ///
  /// - Parameter maxLength: The maximum number of elements to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A buffer pointer with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  package func _extracting(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a prefix of negative length")
    let newCount = Swift.min(maxLength, count)
    return Self(start: baseAddress, count: newCount)
  }

  /// Returns a buffer pointer containing the final elements of this buffer,
  /// up to the given maximum length.
  ///
  /// If the maximum length exceeds the length of this buffer pointer,
  /// the result contains all the elements.
  ///
  /// The returned buffer's first item is always at offset 0; unlike buffer
  /// slices, extracted buffers do not share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter maxLength: The maximum number of elements to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A buffer pointer with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  package func _extracting(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length")
    let newCount = Swift.min(maxLength, count)
    return extracting(Range(uncheckedBounds: (count - newCount, count)))
  }
}

