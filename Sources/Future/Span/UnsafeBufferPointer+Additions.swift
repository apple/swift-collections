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


extension UnsafeMutableBufferPointer {
  /// Initialize slots at the start of this buffer by copying data from `buffer`, then
  /// shrink `self` to drop all initialized items from its front, leaving it addressing the
  /// uninitialized remainder.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized, while `buffer` must be fully initialized.
  ///
  /// The count of `buffer` must not be greater than `self.count`.
  @inlinable
  internal mutating func _initializeAndDropPrefix(copying buffer: UnsafeBufferPointer<Element>) {
    if buffer.isEmpty { return }
    precondition(buffer.count <= self.count)
    unsafe self.baseAddress.unsafelyUnwrapped.initialize(
      from: buffer.baseAddress.unsafelyUnwrapped, count: buffer.count)
    unsafe self = self.extracting(buffer.count...)
  }

  /// Initialize slots at the start of this buffer by copying data from `span`, then
  /// shrink `self` to drop all initialized items from its front, leaving it addressing the
  /// uninitialized remainder.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized.
  ///
  /// The count of `span` must not be greater than `self.count`.
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  internal mutating func _initializeAndDropPrefix(copying span: Span<Element>) {
    unsafe span.withUnsafeBufferPointer { buffer in
      unsafe self._initializeAndDropPrefix(copying: buffer)
    }
  }

  /// Initialize all slots in this buffer by copying data from `items`, which must fit entirely
  /// in this buffer.
  ///
  /// If `items` contains more elements than can fit into this buffer, then this function
  /// will return an index other than `items.endIndex`. In that case, `self` may not be fully
  /// populated.
  ///
  /// If `Element` is not bitwise copyable, then this function must be called on an
  /// entirely uninitialized buffer.
  ///
  /// - Returns: A pair of values `(count, end)`, where `count` is the number of items that were
  ///    successfully initialized, and `end` is the index into `items` after the last copied item.
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  internal func _initializePrefix<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing C
  ) -> (copied: Int, end: C.Index) {
    var target = unsafe self
    var i = items.startIndex
    while true {
      let start = i
      let span = items.nextSpan(after: &i)
      if span.isEmpty { break }
      guard span.count <= target.count else {
        return (self.count - target.count, start)
      }
      unsafe target._initializeAndDropPrefix(copying: span)
    }
    return (self.count - target.count, i)
  }
}
