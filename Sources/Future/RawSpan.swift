//===--- RawSpan.swift ----------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Builtin

// A RawSpan represents a span of initialized memory
// of unspecified type.
@frozen
public struct RawSpan: Copyable, ~Escapable {
  @usableFromInline let _start: UnsafeRawPointer
  @usableFromInline let _count: Int

  @inlinable @inline(__always)
  internal init<Owner: ~Copyable & ~Escapable>(
    _unchecked start: UnsafeRawPointer,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self._start = start
    self._count = count
  }
}

@available(*, unavailable)
extension RawSpan: Sendable {}

extension RawSpan {

  //FIXME: make failable once Optional can be non-escapable
  /// Unsafely create a `RawSpan` over initialized memory.
  ///
  /// The memory in `buffer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeRawBufferPointer` to initialized memory.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `RawSpan`.
  @inlinable @inline(__always)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeBytes buffer: UnsafeRawBufferPointer,
    owner: borrowing Owner
  ) {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("RawSpan requires a non-nil base address")
    }
    self.init(_unchecked: baseAddress, count: buffer.count, owner: owner)
  }

  /// Unsafely create a `RawSpan` over initialized memory.
  ///
  /// The memory over `count` bytes starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the view.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `RawSpan`.
  @inlinable @inline(__always)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeStart pointer: UnsafeRawPointer,
    byteCount: Int,
    owner: borrowing Owner
  ) {
    precondition(byteCount >= 0, "Count must not be negative")
    self.init(_unchecked: pointer, count: byteCount, owner: owner)
  }

  /// Create a `RawSpan` over the memory represented by a `Span<T>`
  ///
  /// - Parameters:
  ///   - span: An existing `Span<T>`, which will define both this
  ///           `RawSpan`'s lifetime and the memory it represents.
  @inlinable @inline(__always)
  public init<T: BitwiseCopyable>(
    _ span: borrowing Span<T>
  ) {
    self.init(
      _unchecked: UnsafeRawPointer(span._start),
      count: span.count * MemoryLayout<T>.stride,
      owner: span
    )
  }
}

extension RawSpan {

  /// The number of bytes in the span.
  ///
  /// To check whether the span is empty, use its `isEmpty` property
  /// instead of comparing `count` to zero.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var count: Int { _count }

  /// A Boolean value indicating whether the span is empty.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var isEmpty: Bool { count == 0 }

  /// The indices that are valid for subscripting the span, in ascending
  /// order.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var indices: Range<Int> {
    .init(uncheckedBounds: (0, count))
  }
}

//MARK: Bounds Checking
extension RawSpan {

  /// Traps if `offset` is not a valid offset into this `RawSpan`
  ///
  /// - Parameters:
  ///   - position: an offset to validate
  @inlinable @inline(__always)
  public func boundsCheckPrecondition(_ offset: Int) {
    precondition(
      0 <= offset && offset < count,
      "Offset out of bounds"
    )
  }

  /// Traps if `bounds` is not a valid range of offsets into this `RawSpan`
  ///
  /// - Parameters:
  ///   - offsets: a range of offsets to validate
  @inlinable @inline(__always)
  public func boundsCheckPrecondition(_ offsets: Range<Int>) {
    precondition(
      0 <= offsets.lowerBound && offsets.upperBound <= count,
      "Range of offsets out of bounds"
    )
  }
}

//MARK: extracting sub-spans
extension RawSpan {

  /// Constructs a new span over the bytes within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first byte is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `RawSpan`.
  ///
  /// - Returns: A `Span` over the bytes within `bounds`
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func extracting(_ bounds: Range<Int>) -> Self {
    boundsCheckPrecondition(bounds)
    return extracting(uncheckedBounds: bounds)
  }

  /// Constructs a new span over the bytes within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first byte is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `RawSpan`.
  ///
  /// - Returns: A `Span` over the bytes within `bounds`
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func extracting(uncheckedBounds bounds: Range<Int>) -> Self {
    RawSpan(
      _unchecked: _start.advanced(by: bounds.lowerBound),
      count: bounds.count,
      owner: self
    )
  }

  /// Constructs a new span over the bytes within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first byte is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `RawSpan`.
  ///
  /// - Returns: A `Span` over the bytes within `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
    extracting(bounds.relative(to: indices))
  }

  /// Constructs a new span over the bytes within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first byte is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `RawSpan`.
  ///
  /// - Returns: A `Span` over the bytes within `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(
    uncheckedBounds bounds: some RangeExpression<Int>
  ) -> Self {
    extracting(uncheckedBounds: bounds.relative(to: indices))
  }

  /// Constructs a new span over all the bytes of this span.
  ///
  /// The returned span's first byte is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Returns: A `RawSpan` over all the items of this span.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(_: UnboundedRange) -> Self {
    self
  }
}

extension RawSpan {

  //FIXME: mark closure parameter as non-escaping
  /// Calls the given closure with a pointer to the underlying bytes of
  /// the viewed contiguous storage.
  ///
  /// The buffer pointer passed as an argument to `body` is valid only
  /// during the execution of `withUnsafeBytes(_:)`.
  /// Do not store or return the pointer for later use.
  ///
  /// - Parameter body: A closure with an `UnsafeRawBufferPointer`
  ///   parameter that points to the viewed contiguous storage.
  ///   If `body` has a return value, that value is also
  ///   used as the return value for the `withUnsafeBytes(_:)` method.
  ///   The closure's parameter is valid only for the duration of
  ///   its execution.
  /// - Returns: The return value of the `body` closure parameter.
  borrowing public func withUnsafeBytes<
    E: Error, Result: ~Copyable & ~Escapable
  >(
    _ body: (_ buffer: borrowing UnsafeRawBufferPointer) throws(E) -> Result
  ) throws(E) -> dependsOn(self) Result {
    try body(.init(start: (count==0) ? nil : _start, count: count))
  }
}

extension RawSpan {
  /// View the bytes of this span as a given type
  ///
  /// - Parameter type: The type as which we should view <reword>
  /// - Returns: A typed span viewing these bytes as T
  borrowing public func view<T: BitwiseCopyable>(
    as type: T.Type
  ) -> dependsOn(self) Span<T> {
    Span(unsafeStart: _start, byteCount: count, owner: self)
  }
}

//MARK: load
extension RawSpan {

  public func load<T>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    boundsCheckPrecondition(
      Range(uncheckedBounds: (offset, offset+MemoryLayout<T>.size))
    )
    return load(fromUncheckedByteOffset: offset, as: T.self)
  }

  public func load<T>(
    fromUncheckedByteOffset offset: Int, as: T.Type
  ) -> T {
    _start.load(fromByteOffset: offset, as: T.self)
  }

  public func loadUnaligned<T: BitwiseCopyable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    boundsCheckPrecondition(
      Range(uncheckedBounds: (offset, offset+MemoryLayout<T>.size))
    )
    return loadUnaligned(fromUncheckedByteOffset: offset, as: T.self)
  }

  public func loadUnaligned<T: BitwiseCopyable>(
    fromUncheckedByteOffset offset: Int, as: T.Type
  ) -> T {
    _start.loadUnaligned(fromByteOffset: offset, as: T.self)
  }
}

//MARK: one-sided slicing operations
extension RawSpan {

  /// Returns a span containing the initial bytes of this span,
  /// up to the specified maximum byte count.
  ///
  /// If the maximum length exceeds the length of this span,
  /// the result contains all the bytes.
  ///
  /// - Parameter maxLength: The maximum number of bytes to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A span with at most `maxLength` bytes.
  ///
  /// - Complexity: O(1)
  borrowing public func extracting(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a prefix of negative length.")
    let nc = maxLength < count ? maxLength : count
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  /// Returns a span over all but the given number of trailing bytes.
  ///
  /// If the number of elements to drop exceeds the number of elements in
  /// the span, the result is an empty span.
  ///
  /// - Parameter k: The number of bytes to drop off the end of
  ///   the span. `k` must be greater than or equal to zero.
  /// - Returns: A span leaving off the specified number of bytes at the end.
  ///
  /// - Complexity: O(1)
  borrowing public func extracting(droppingLast k: Int) -> Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let nc = k < count ? count&-k : 0
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  /// Returns a span containing the trailing bytes of the span,
  /// up to the given maximum length.
  ///
  /// If the maximum length exceeds the length of this span,
  /// the result contains all the bytes.
  ///
  /// - Parameter maxLength: The maximum number of bytes to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A span with at most `maxLength` bytes.
  ///
  /// - Complexity: O(1)
  borrowing public func extracting(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length.")
    let nc = maxLength < count ? maxLength : count
    let newStart = _start.advanced(by: count&-nc)
    return Self(_unchecked: newStart, count: nc, owner: self)
  }

  /// Returns a span over all but the given number of initial bytes.
  ///
  /// If the number of elements to drop exceeds the number of bytes in
  /// the span, the result is an empty span.
  ///
  /// - Parameter k: The number of bytes to drop from the beginning of
  ///   the span. `k` must be greater than or equal to zero.
  /// - Returns: A span starting after the specified number of bytes.
  ///
  /// - Complexity: O(1)
  borrowing public func extracting(droppingFirst k: Int = 1) -> Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let dc = k < count ? k : count
    let newStart = _start.advanced(by: dc)
    return Self(_unchecked: newStart, count: count&-dc, owner: self)
  }
}
