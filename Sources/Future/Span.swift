//===--- Span.swift -------------------------------------------------------===//
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

// A Span<Element> represents a span of memory which
// contains initialized instances of `Element`.
@frozen
public struct Span<Element: ~Copyable /*& ~Escapable*/>: Copyable, ~Escapable {
  @usableFromInline let _start: UnsafePointer<Element>
  @usableFromInline let _count: Int

  @inlinable @inline(__always)
  internal init<Owner: ~Copyable & ~Escapable>(
    _unchecked start: UnsafePointer<Element>,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self._start = start
    self._count = count
  }
}

@available(*, unavailable)
extension Span: Sendable {}

extension UnsafePointer where Pointee: ~Copyable /*& ~Escapable*/ {

  @inline(__always)
  fileprivate var isAligned: Bool {
    (Int(bitPattern: self) & (MemoryLayout<Pointee>.alignment-1)) == 0
  }
}

extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory representing `count` instances starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the view.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafePointer start: UnsafePointer<Element>,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    precondition(count >= 0, "Count must not be negative")
    precondition(
      start.isAligned,
      "baseAddress must be properly aligned for accessing \(Element.self)"
    )
    self.init(_unchecked: start, count: count, owner: owner)
  }

  //FIXME: make failable once Optional can be non-escapable
  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory in `buffer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeBufferPointer` to initialized elements.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeBufferPointer buffer: UnsafeBufferPointer<Element>,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    self.init(unsafePointer: baseAddress, count: buffer.count, owner: owner)
  }
}

extension Span where Element: BitwiseCopyable {

  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory representing `count` instances starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the view.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafePointer start: UnsafePointer<Element>,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    precondition(count >= 0, "Count must not be negative")
    self.init(_unchecked: start, count: count, owner: owner)
  }

  //FIXME: make failable once Optional can be non-escapable
  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory in `buffer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeBufferPointer` to initialized elements.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeBufferPointer buffer: UnsafeBufferPointer<Element>,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    self.init(unsafePointer: baseAddress, count: buffer.count, owner: owner)
  }

  //FIXME: make failable once Optional can be non-escapable
  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory in `unsafeBytes` must be owned by the instance `owner`
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// `unsafeBytes` must be correctly aligned for accessing
  /// an element of type `Element`, and must contain a number of bytes
  /// that is an exact multiple of `Element`'s stride.
  ///
  /// - Parameters:
  ///   - unsafeBytes: a buffer to initialized elements.
  ///   - type: the type to use when interpreting the bytes in memory.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeBytes buffer: UnsafeRawBufferPointer,
    as type: Element.Type,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    let (c, s) = (buffer.count, MemoryLayout<Element>.stride)
    let (q, r) = c.quotientAndRemainder(dividingBy: s)
    precondition(r == 0)
    self.init(
      unsafeRawPointer: baseAddress, as: Element.self, count: q, owner: owner
    )
  }

  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory representing `count` instances starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the view.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the returned `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeRawPointer pointer: UnsafeRawPointer,
    as type: Element.Type,
    count: Int,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self.init(
      unsafePointer: pointer.assumingMemoryBound(to: Element.self),
      count: count,
      owner: owner
    )
  }
}

extension Span where Element: Equatable {

  public func elementsEqual(_ other: Self) -> Bool {
    guard count == other.count else { return false }
    if count == 0 { return true }

    //FIXME: This could be short-cut
    //       with a layout constraint where stride equals size,
    //       as long as there is at most 1 unused bit pattern.
    // if Element is BitwiseEquatable {
    // return _swift_stdlib_memcmp(lhs.baseAddress, rhs.baseAddress, count) == 0
    // }
    for o in 0..<count {
      if self[unchecked: o] != other[unchecked: o] { return false }
    }
    return true
  }

  @inlinable
  public func elementsEqual(_ other: some Collection<Element>) -> Bool {
    guard count == other.count else { return false }
    if count == 0 { return true }

    return elementsEqual(AnySequence(other))
  }

  @inlinable
  public func elementsEqual(_ other: some Sequence<Element>) -> Bool {
    var offset = 0
    for otherElement in other {
      if offset >= count { return false }
      if self[unchecked: offset] != otherElement { return false }
      offset += 1
    }
    return offset == count
  }
}

extension Span where Element: ~Copyable /*& ~Escapable*/ {

  @inlinable @inline(__always)
  public var count: Int { _count }

  @inlinable @inline(__always)
  public var isEmpty: Bool { _count == 0 }

  @inlinable @inline(__always)
  public var indices: Range<Int> {
    .init(uncheckedBounds: (0, _count))
  }
}

//MARK: Bounds Checking
extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Traps if `offset` is not a valid offset into this `Span`
  ///
  /// - Parameters:
  ///   - position: an Index to validate
  @inlinable @inline(__always)
  public func boundsCheckPrecondition(_ offset: Int) {
    precondition(
      0 <= offset && offset < count,
      "Offset out of bounds"
    )
  }

  /// Traps if `offsets` is not a valid range of offsets into this `Span`
  ///
  /// - Parameters:
  ///   - offsets: a range of indices to validate
  @inlinable @inline(__always)
  public func boundsCheckPrecondition(_ offsets: Range<Int>) {
    precondition(
      0 <= offsets.lowerBound && offsets.upperBound <= count,
      "Range of offsets out of bounds"
    )
  }
}

extension Span where Element: BitwiseCopyable {

  @inlinable @inline(__always)
  public var rawSpan: RawSpan { RawSpan(self) }
}

//MARK: integer offset subscripts
extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public subscript(_ position: Int) -> Element {
    borrowing _read {
      boundsCheckPrecondition(position)
      yield self[unchecked: position]
    }
  }

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public subscript(unchecked position: Int) -> Element {
    borrowing _read {
      yield _start.advanced(by: position).pointee
    }
  }
}

extension Span where Element: BitwiseCopyable {

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public subscript(_ position: Int) -> Element {
    get {
      boundsCheckPrecondition(position)
      return self[unchecked: position]
    }
  }

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public subscript(unchecked position: Int) -> Element {
    get {
      UnsafeRawPointer(_start + position).loadUnaligned(as: Element.self)
    }
  }
}

//MARK: extracting sub-spans
extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items at `bounds`
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func extracting(_ bounds: Range<Int>) -> Self {
    boundsCheckPrecondition(bounds)
    return extracting(uncheckedBounds: bounds)
  }

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items at `bounds`
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func extracting(uncheckedBounds bounds: Range<Int>) -> Self {
    Span(
      _unchecked: _start.advanced(by: bounds.lowerBound),
      count: bounds.count,
      owner: self
    )
  }

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items at `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
    extracting(bounds.relative(to: indices))
  }

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items at `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(
    uncheckedBounds bounds: some RangeExpression<Int>
  ) -> Self {
    extracting(uncheckedBounds: bounds.relative(to: indices))
  }

  /// Constructs a new span over all the items of this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Returns: A `Span` over all the items of this span.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(_: UnboundedRange) -> Self {
    self
  }
}

//MARK: withUnsafePointer, etc.
extension Span where Element: ~Copyable {

  //FIXME: mark closure parameter as non-escaping
  /// Calls a closure with a pointer to the viewed contiguous storage.
  ///
  /// The buffer pointer passed as an argument to `body` is valid only
  /// during the execution of `withUnsafeBufferPointer(_:)`.
  /// Do not store or return the pointer for later use.
  ///
  /// - Parameter body: A closure with an `UnsafeBufferPointer` parameter
  ///   that points to the viewed contiguous storage. If `body` has
  ///   a return value, that value is also used as the return value
  ///   for the `withUnsafeBufferPointer(_:)` method. The closure's
  ///   parameter is valid only for the duration of its execution.
  /// - Returns: The return value of the `body` closure parameter.
  borrowing public func withUnsafeBufferPointer<
    E: Error, Result: ~Copyable & ~Escapable
  >(
    _ body: (_ buffer: borrowing UnsafeBufferPointer<Element>) throws(E) -> Result
  ) throws(E) -> dependsOn(self) Result {
    try body(.init(start: (count==0) ? nil : _start, count: count))
  }
}

extension Span where Element: BitwiseCopyable {

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
  ) throws(E) -> Result {
    try RawSpan(self).withUnsafeBytes(body)
  }
}

// `first` and `last` can't exist where Element: ~Copyable
// because we can't construct an Optional of a borrow
extension Span where Element: Copyable {
  @inlinable
  public var first: Element? {
    isEmpty ? nil : self[unchecked: 0]
  }

  @inlinable
  public var last: Element? {
    isEmpty ? nil : self[unchecked: count &- 1]
  }
}

//MARK: one-sided slicing operations
extension Span where Element: ~Copyable /*& ~Escapable*/ {

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
