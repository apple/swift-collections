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

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  /// Returns a Boolean value indicating whether two
  /// `UnsafeMutableBufferPointer` instances refer to the same region in
  /// memory.
  @inlinable @inline(__always)
  package func _isIdentical(to other: Self) -> Bool {
    (self.baseAddress == other.baseAddress) && (self.count == other.count)
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
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
  public func _extracting(first maxLength: Int) -> Self {
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
  /// buffer from which they are extracted.
  ///
  /// - Parameter maxLength: The maximum number of elements to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A buffer pointer with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func _extracting(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length")
    let newCount = Swift.min(maxLength, count)
    return extracting(Range(uncheckedBounds: (count - newCount, count)))
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  @inlinable
  package func _moveInitializePrefix(
    from source: UnsafeMutableBufferPointer<Element>
  ) -> Int {
    if source.isEmpty { return 0 }
    precondition(source.count <= self.count)
    self.baseAddress.unsafelyUnwrapped.moveInitialize(
      from: source.baseAddress.unsafelyUnwrapped, count: source.count)
    return source.count
  }
}

extension UnsafeMutableBufferPointer {
  /// Initialize slots at the start of this buffer by copying data from `source`.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized, while `source` must be fully initialized.
  ///
  /// The `source` buffer must fit entirely in `self`.
  ///
  /// - Returns: The index after the last item that was initialized in this buffer.
  @inlinable
  package func _initializePrefix(
    copying source: UnsafeBufferPointer<Element>
  ) -> Int {
    if source.isEmpty { return 0 }
    precondition(source.count <= self.count)
    self.baseAddress.unsafelyUnwrapped.initialize(
      from: source.baseAddress.unsafelyUnwrapped, count: source.count)
    return source.count
  }

  @inlinable
  package func _initializePrefix(
    copying source: UnsafeMutableBufferPointer<Element>
  ) -> Int {
    _initializePrefix(copying: UnsafeBufferPointer(source))
  }

#if compiler(>=6.2)
  /// Initialize slots at the start of this buffer by copying data from `source`.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized.
  ///
  /// The `source` span must fit entirely in `self`.
  ///
  /// - Returns: The index after the last item that was initialized in this buffer.
  @available(SwiftStdlib 5.0, *)
  @inlinable
  package func _initializePrefix(copying source: Span<Element>) -> Int {
    source.withUnsafeBufferPointer { self._initializePrefix(copying: $0) }
  }
#endif

  /// Initialize slots at the start of this buffer by copying data from `buffer`, then
  /// shrink `self` to drop all initialized items from its front, leaving it addressing the
  /// uninitialized remainder.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized, while `buffer` must be fully initialized.
  ///
  /// The count of `buffer` must not be greater than `self.count`.
  @inlinable
  package mutating func _initializeAndDropPrefix(copying source: UnsafeBufferPointer<Element>) {
    let i = _initializePrefix(copying: source)
    self = self.extracting(i...)
  }

#if compiler(>=6.2)
  /// Initialize slots at the start of this buffer by copying data from `span`, then
  /// shrink `self` to drop all initialized items from its front, leaving it addressing the
  /// uninitialized remainder.
  ///
  /// If `Element` is not bitwise copyable, then the memory region addressed by `self` must be
  /// entirely uninitialized.
  ///
  /// The count of `span` must not be greater than `self.count`.
  @available(SwiftStdlib 5.0, *)
  @inlinable
  package mutating func _initializeAndDropPrefix(copying span: Span<Element>) {
    span.withUnsafeBufferPointer { buffer in
      self._initializeAndDropPrefix(copying: buffer)
    }
  }
#endif
}

extension UnsafeMutableBufferPointer {
  @inlinable
  package func initialize(fromContentsOf source: Self) -> Index {
    guard source.count > 0 else { return 0 }
    precondition(
      source.count <= self.count,
      "buffer cannot contain every element from source.")
    baseAddress.unsafelyUnwrapped.initialize(
      from: source.baseAddress.unsafelyUnwrapped,
      count: source.count)
    return source.count
  }

  @inlinable
  package func initialize(fromContentsOf source: Slice<Self>) -> Index {
    let sourceCount = source.count
    guard sourceCount > 0 else { return 0 }
    precondition(
      sourceCount <= self.count,
      "buffer cannot contain every element from source.")
    baseAddress.unsafelyUnwrapped.initialize(
      from: source.base.baseAddress.unsafelyUnwrapped + source.startIndex,
      count: sourceCount)
    return sourceCount
  }
}

extension Slice {
  @inlinable @inline(__always)
  package func initialize<Element>(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) -> Index
  where Base == UnsafeMutableBufferPointer<Element>
  {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    let i = target.initialize(fromContentsOf: source)
    return self.startIndex + i
  }

  @inlinable @inline(__always)
  package func initialize<Element>(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) -> Index
  where Base == UnsafeMutableBufferPointer<Element>
  {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    let i = target.initialize(fromContentsOf: source)
    return self.startIndex + i
  }
}

extension UnsafeMutableBufferPointer {
  @inlinable @inline(__always)
  package func initializeAll<C: Collection>(
    fromContentsOf source: C
  ) where C.Element == Element {
    let i = self.initialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }

  @inlinable @inline(__always)
  package func initializeAll(fromContentsOf source: Self) {
    let i = self.initialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }

  @inlinable @inline(__always)
  package func initializeAll(fromContentsOf source: Slice<Self>) {
    let i = self.initialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  @inlinable @inline(__always)
  package func moveInitializeAll(fromContentsOf source: Self) {
    let i = self.moveInitialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }
}

extension UnsafeMutableBufferPointer {
  @inlinable @inline(__always)
  package func moveInitializeAll(fromContentsOf source: Slice<Self>) {
    let i = self.moveInitialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }
}

extension Slice {
  @inlinable @inline(__always)
  package func initializeAll<C: Collection>(
    fromContentsOf source: C
  ) where Base == UnsafeMutableBufferPointer<C.Element> {
    let i = self.initialize(fromContentsOf: source)
    assert(i == self.endIndex)
  }

  @inlinable @inline(__always)
  package func initializeAll<Element>(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) where Base == UnsafeMutableBufferPointer<Element> {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    target.initializeAll(fromContentsOf: source)
  }

  @inlinable @inline(__always)
  package func initializeAll<Element>(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) where Base == UnsafeMutableBufferPointer<Element> {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    target.initializeAll(fromContentsOf: source)
  }

  @inlinable @inline(__always)
  package func moveInitializeAll<Element>(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) where Base == UnsafeMutableBufferPointer<Element> {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    target.moveInitializeAll(fromContentsOf: source)
  }

  @inlinable @inline(__always)
  package func moveInitializeAll<Element>(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) where Base == UnsafeMutableBufferPointer<Element> {
    let target = UnsafeMutableBufferPointer(rebasing: self)
    target.moveInitializeAll(fromContentsOf: source)
  }
}
