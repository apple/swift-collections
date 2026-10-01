//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension UnsafeBufferPointer where Element: ~Copyable{
  @inlinable
  @inline(__always)
  @unsafe
  package func _ptr(at index: Int) -> UnsafePointer<Element> {
    assert(index >= 0 && index < count)
    return unsafe baseAddress.unsafelyUnwrapped + index
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  /// Returns a Boolean value indicating whether two `UnsafeBufferPointer`
  /// instances refer to the same region in memory.
  @inlinable @inline(__always)
  @safe
  package func _isIdentical(to other: Self) -> Bool {
    unsafe (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }

  @inlinable
  @inline(__always)
  @safe
  package static var _empty: Self {
    unsafe .init(start: nil, count: 0)
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @unsafe
  package func _extracting(uncheckedFrom start: Int, to end: Int) -> Self {
    guard let base = self.baseAddress else {
      return Self(_empty: ())
    }
    return unsafe Self(start: base + start, count: end - start)
  }

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
  @safe
  package func _extracting(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let newCount = Swift.min(maxLength, count)
    return unsafe Self(start: baseAddress, count: newCount)
  }

  /// Returns a buffer pointer containing all but the given number of initial
  /// elements.
  ///
  /// If the number of elements to drop exceeds the number of elements in the
  /// buffer, the result is an empty buffer.
  ///
  /// The returned buffer's first item is always at offset 0; unlike buffer
  /// slices, extracted buffers do not share their indices with the
  /// buffer from which they are extracted.
  ///
  /// - Parameter maxLength: The maximum number of elements to drop.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A buffer pointer with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  @safe
  package func _extracting(droppingFirst maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let cut = Swift.min(maxLength, count)
    return unsafe Self(start: baseAddress?.advanced(by: cut), count: count &- cut)
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
  @safe
  package func _extracting(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a suffix of negative length")
    let newCount = Swift.min(maxLength, count)
    return unsafe extracting(Range(uncheckedBounds: (count - newCount, count)))
  }
  
  /// Returns a buffer pointer containing all but the given number of trailing
  /// elements.
  ///
  /// If the number of elements to drop exceeds the number of elements in the
  /// buffer, the result is an empty buffer.
  ///
  /// The returned buffer's first item is always at offset 0; unlike buffer
  /// slices, extracted buffers do not share their indices with the
  /// buffer from which they are extracted.
  ///
  /// - Parameter maxLength: The maximum number of elements to drop.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A buffer pointer with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  @safe
  package func _extracting(droppingLast maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let newCount = count &- Swift.min(maxLength, count)
    return unsafe Self(start: baseAddress, count: newCount)
  }

}

extension UnsafeBufferPointer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @safe
  package mutating func _trim(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return unsafe .init(start: nil, count: 0) }
    let oldStart = unsafe baseAddress.unsafelyUnwrapped
    unsafe self = Self(start: oldStart + cut, count: count - cut)
    return unsafe Self(start: oldStart, count: cut)
  }

  @_alwaysEmitIntoClient
  @safe
  package mutating func _trim(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a suffix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return unsafe .init(start: nil, count: 0) }
    let oldStart = unsafe baseAddress.unsafelyUnwrapped
    let newCount = count &- cut
    unsafe self = .init(start: oldStart, count: newCount)
    return unsafe Self(start: oldStart + newCount, count: cut)
  }
}
