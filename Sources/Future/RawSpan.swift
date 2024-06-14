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
  ///            the returned `RawSpan`.
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
  ///            the returned `Span`.
  @inlinable @inline(__always)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeRawPointer pointer: UnsafeRawPointer,
    count: Int,
    owner: borrowing Owner
  ) {
    precondition(count >= 0, "Count must not be negative")
    self.init(_unchecked: pointer, count: count, owner: owner)
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

//MARK: Offset Manipulation
extension RawSpan {

  @inlinable @inline(__always)
  public var count: Int {
    borrowing get { self._count }
  }

  @inlinable @inline(__always)
  public var isEmpty: Bool { count == 0 }

  @inlinable @inline(__always)
  public var indices: Range<Int> {
    .init(uncheckedBounds: (0, count))
  }
}

//MARK: integer offset subscripts
extension RawSpan {

  @inlinable @inline(__always)
  public subscript(offsets offsets: Range<Int>) -> Self {
    borrowing get {
      boundsCheckPrecondition(offsets)
      return self[uncheckedOffsets: offsets]
    }
  }

  @inlinable @inline(__always)
  public subscript(uncheckedOffsets offsets: Range<Int>) -> Self {
    borrowing get {
      RawSpan(
        _unchecked: _start.advanced(by: offsets.lowerBound),
        count: offsets.count,
        owner: self
      )
    }
  }

  @_alwaysEmitIntoClient
  public subscript(offsets offsets: some RangeExpression<Int>) -> Self {
    borrowing get {
      self[offsets: offsets.relative(to: indices)]
    }
  }

  @_alwaysEmitIntoClient
  public subscript(uncheckedOffsets offsets: some RangeExpression<Int>) -> Self {
    borrowing get {
      self[uncheckedOffsets: offsets.relative(to: indices)]
    }
  }

  @_alwaysEmitIntoClient
  public subscript(offsets _: UnboundedRange) -> Self {
    borrowing get { copy self }
  }
}

//MARK: withUnsafeBytes
extension RawSpan {

  //FIXME: mark closure parameter as non-escaping
  @_alwaysEmitIntoClient
  borrowing public func withUnsafeBytes<
    E: Error, Result: ~Copyable & ~Escapable
  >(
    _ body: (_ buffer: borrowing UnsafeRawBufferPointer) throws(E) -> Result
  ) throws(E) -> dependsOn(self) Result {
    try body(.init(start: (count==0) ? nil : _start, count: count))
  }

  borrowing public func view<T: BitwiseCopyable>(
    as: T.Type
  ) -> dependsOn(self) Span<T> {
    let (c, r) = count.quotientAndRemainder(dividingBy: MemoryLayout<T>.stride)
    precondition(r == 0, "Returned span must contain whole number of T")
    return Span(
      unsafeRawPointer: _start, as: T.self, count: c, owner: self
    )
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

  borrowing public func prefix(upTo offset: Int) -> dependsOn(self) Self {
    if offset != 0 {
      boundsCheckPrecondition(offset &- 1)
    }
    return Self(_unchecked: _start, count: offset, owner: self)
  }

  borrowing public func prefix(through offset: Int) -> dependsOn(self) Self {
    boundsCheckPrecondition(offset)
    return Self(_unchecked: _start, count: offset &+ 1, owner: self)
  }

  borrowing public func prefix(_ maxLength: Int) -> dependsOn(self) Self {
    precondition(maxLength >= 0, "Can't have a prefix of negative length.")
    let nc = maxLength < count ? maxLength : count
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  borrowing public func dropLast(_ k: Int = 1) -> dependsOn(self) Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let nc = k < count ? count&-k : 0
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  borrowing public func suffix(from offset: Int) -> dependsOn(self) Self {
    if offset != count {
      boundsCheckPrecondition(offset)
    }
    return Self(
      _unchecked: _start.advanced(by: offset),
      count: count &- offset,
      owner: self
    )
  }

  borrowing public func suffix(_ maxLength: Int) -> dependsOn(self) Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length.")
    let nc = maxLength < count ? maxLength : count
    let newStart = _start.advanced(by: count&-nc)
    return Self(_unchecked: newStart, count: nc, owner: self)
  }

  borrowing public func dropFirst(_ k: Int = 1) -> dependsOn(self) Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let dc = k < count ? k : count
    let newStart = _start.advanced(by: dc)
    return Self(_unchecked: newStart, count: count&-dc, owner: self)
  }
}
