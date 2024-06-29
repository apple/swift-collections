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
  ) {
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

  //FIXME: make properly non-failable
  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory in `buffer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeBufferPointer` to initialized elements.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeElements buffer: UnsafeBufferPointer<Element>,
    owner: borrowing Owner
  ) {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    self.init(unsafeStart: baseAddress, count: buffer.count, owner: owner)
  }

  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory representing `count` instances starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the span.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeStart start: UnsafePointer<Element>,
    count: Int,
    owner: borrowing Owner
  ) {
    precondition(count >= 0, "Count must not be negative")
    precondition(
      start.isAligned,
      "baseAddress must be properly aligned for accessing \(Element.self)"
    )
    self.init(_unchecked: start, count: count, owner: owner)
  }
}

extension Span where Element: BitwiseCopyable {

  //FIXME: make properly non-failable
  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory in `buffer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeBufferPointer` to initialized elements.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeElements buffer: UnsafeBufferPointer<Element>,
    owner: borrowing Owner
  ) {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    self.init(unsafeStart: baseAddress, count: buffer.count, owner: owner)
  }

  /// Unsafely create a `Span` over initialized memory.
  ///
  /// The memory representing `count` instances starting at
  /// `pointer` must be owned by the instance `owner`,
  /// meaning that as long as `owner` is alive the memory will remain valid.
  ///
  /// - Parameters:
  ///   - pointer: a pointer to the first initialized element.
  ///   - count: the number of initialized elements in the span.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeStart start: UnsafePointer<Element>,
    count: Int,
    owner: borrowing Owner
  ) {
    precondition(count >= 0, "Count must not be negative")
    self.init(_unchecked: start, count: count, owner: owner)
  }

  //FIXME: make properly non-failable
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
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeBytes buffer: UnsafeRawBufferPointer,
    owner: borrowing Owner
  ) {
    guard let baseAddress = buffer.baseAddress else {
      fatalError("Span requires a non-nil base address")
    }
    let (c, s) = (buffer.count, MemoryLayout<Element>.stride)
    let (q, r) = c.quotientAndRemainder(dividingBy: s)
    precondition(r == 0)
    self.init(
      unsafeStart: baseAddress.assumingMemoryBound(to: Element.self),
      count: q,
      owner: owner
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
  ///   - count: the number of initialized elements in the span.
  ///   - owner: a binding whose lifetime must exceed that of
  ///            the newly created `Span`.
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeStart pointer: UnsafeRawPointer,
    byteCount: Int,
    owner: borrowing Owner
  ) {
    let stride = MemoryLayout<Element>.stride
    let (q, r) = byteCount.quotientAndRemainder(dividingBy: stride)
    precondition(r == 0)
    self.init(
      unsafeStart: pointer.assumingMemoryBound(to: Element.self),
      count: q,
      owner: owner
    )
  }
}

extension Span where Element: Equatable {

  /// Returns a Boolean value indicating whether this and another span
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A span to compare to this one.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  public func _elementsEqual(_ other: Self) -> Bool {
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

  /// Returns a Boolean value indicating whether this span and a Collection
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A Collection to compare to this span.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  @inlinable
  public func _elementsEqual(_ other: some Collection<Element>) -> Bool {
    guard count == other.count else { return false }
    if count == 0 { return true }

    return _elementsEqual(AnySequence(other))
  }

  /// Returns a Boolean value indicating whether this span and a Sequence
  /// contain equal elements in the same order.
  ///
  /// - Parameters:
  ///   - other: A Sequence to compare to this span.
  /// - Returns: `true` if this sequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the lesser of the length of the
  ///   sequence and the length of `other`.
  @inlinable
  public func _elementsEqual(_ other: some Sequence<Element>) -> Bool {
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

  /// The number of elements in the span.
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
  public var isEmpty: Bool { _count == 0 }

  /// The indices that are valid for subscripting the span, in ascending
  /// order.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var _indices: Range<Int> {
    .init(uncheckedBounds: (0, _count))
  }
}

//MARK: Bounds Checking
extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Return true if `offset` is a valid offset into this `Span`
  ///
  /// - Parameters:
  ///   - position: an index to validate
  /// - Returns: true if `offset` is a valid index
  @inlinable @inline(__always)
  public func validateBounds(_ offset: Int) -> Bool {
    0 <= offset && offset < count
  }

  /// Traps if `offset` is not a valid offset into this `Span`
  ///
  /// - Parameters:
  ///   - position: an index to validate
  @inlinable @inline(__always)
  public func assertValidity(_ offset: Int) {
    precondition(
      validateBounds(offset), "Offset out of bounds"
    )
  }

  /// Return true if `offsets` is a valid range of offsets into this `Span`
  ///
  /// - Parameters:
  ///   - offsets: a range of indices to validate
  /// - Returns: true if `offsets` is a valid range of indices
  @inlinable @inline(__always)
  public func validateBounds(_ offsets: Range<Int>) -> Bool {
    0 <= offsets.lowerBound && offsets.upperBound <= count
  }

  /// Traps if `offsets` is not a valid range of offsets into this `Span`
  ///
  /// - Parameters:
  ///   - offsets: a range of indices to validate
  @inlinable @inline(__always)
  public func assertValidity(_ offsets: Range<Int>) {
    precondition(
      validateBounds(offsets), "Range of offsets out of bounds"
    )
  }
}

extension Span where Element: BitwiseCopyable {

  /// Construct a RawSpan over the memory represented by this span
  ///
  /// - Returns: a RawSpan over the memory represented by this span
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
    _read {
      assertValidity(position)
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
    _read {
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
      assertValidity(position)
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
  /// slices, extracted spans do not share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items within `bounds`
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func extracting(_ bounds: Range<Int>) -> Self {
    assertValidity(bounds)
    return extracting(uncheckedBounds: bounds)
  }

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items within `bounds`
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
  /// slices, extracted spans do not share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items within `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
    extracting(bounds.relative(to: _indices))
  }

  /// Constructs a new span over the items within the supplied range of
  /// positions within this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not share their indices with the
  /// span from which they are extracted.
  ///
  /// This function does not validate `bounds`; this is an unsafe operation.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `Span` over the items within `bounds`
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func extracting(
    uncheckedBounds bounds: some RangeExpression<Int>
  ) -> Self {
    extracting(uncheckedBounds: bounds.relative(to: _indices))
  }

  /// Constructs a new span over all the items of this span.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not share their indices with the
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
extension Span where Element: ~Copyable  /*& ~Escapable*/ {

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
  @_alwaysEmitIntoClient
  public func withUnsafeBufferPointer<E: Error, Result: ~Copyable & ~Escapable>(
    _ body: (_ buffer: UnsafeBufferPointer<Element>) throws(E) -> Result
  ) throws(E) -> Result {
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
  @_alwaysEmitIntoClient
  public func withUnsafeBytes<E: Error, Result: ~Copyable & ~Escapable>(
    _ body: (_ buffer: UnsafeRawBufferPointer) throws(E) -> Result
  ) throws(E) -> Result {
    try RawSpan(self).withUnsafeBytes(body)
  }
}

// `first` and `last` can't exist where Element: ~Copyable
// because we can't construct an Optional of a borrow
extension Span where Element: Copyable {

  /// The first element in the span.
  ///
  /// If the span is empty, the value of this property is `nil`.
  ///
  /// - Returns: The first element in the span, or `nil` if empty
  @inlinable
  public var first: Element? {
    isEmpty ? nil : self[unchecked: 0]
  }

  /// The last element in the span.
  ///
  /// If the span is empty, the value of this property is `nil`.
  ///
  /// - Returns: The last element in the span, or `nil` if empty
  @inlinable
  public var last: Element? {
    isEmpty ? nil : self[unchecked: count &- 1]
  }
}

extension Span where Element: ~Copyable /*& ~Escapable*/ {

  @inlinable @inline(__always)
  public func contains(_ span: borrowing Self) -> Bool {
    _start <= span._start &&
    span._start.advanced(by: span._count) <= _start.advanced(by: _count)
  }

  @inlinable @inline(__always)
  public func offsets(of span: borrowing Self) -> Range<Int> {
    precondition(contains(span))
    let s = _start.distance(to: span._start)
    let e = s + span._count
    return Range(uncheckedBounds: (s, e))
  }
}

//MARK: one-sided slicing operations
extension Span where Element: ~Copyable /*& ~Escapable*/ {

  /// Returns a span containing the initial elements of this span,
  /// up to the specified maximum length.
  ///
  /// If the maximum length exceeds the length of this span,
  /// the result contains all the elements.
  ///
  /// - Parameter maxLength: The maximum number of elements to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A span with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  public func extracting(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a prefix of negative length.")
    let nc = maxLength < count ? maxLength : count
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  /// Returns a span over all but the given number of trailing elements.
  ///
  /// If the number of elements to drop exceeds the number of elements in
  /// the span, the result is an empty span.
  ///
  /// - Parameter k: The number of elements to drop off the end of
  ///   the span. `k` must be greater than or equal to zero.
  /// - Returns: A span leaving off the specified number of elements at the end.
  ///
  /// - Complexity: O(1)
  public func extracting(droppingLast k: Int) -> Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let nc = k < count ? count&-k : 0
    return Self(_unchecked: _start, count: nc, owner: self)
  }

  /// Returns a span containing the final elements of the span,
  /// up to the given maximum length.
  ///
  /// If the maximum length exceeds the length of this span,
  /// the result contains all the elements.
  ///
  /// - Parameter maxLength: The maximum number of elements to return.
  ///   `maxLength` must be greater than or equal to zero.
  /// - Returns: A span with at most `maxLength` elements.
  ///
  /// - Complexity: O(1)
  public func extracting(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Can't have a suffix of negative length.")
    let nc = maxLength < count ? maxLength : count
    let newStart = _start.advanced(by: count&-nc)
    return Self(_unchecked: newStart, count: nc, owner: self)
  }

  /// Returns a span over all but the given number of initial elements.
  ///
  /// If the number of elements to drop exceeds the number of elements in
  /// the span, the result is an empty span.
  ///
  /// - Parameter k: The number of elements to drop from the beginning of
  ///   the span. `k` must be greater than or equal to zero.
  /// - Returns: A span starting after the specified number of elements.
  ///
  /// - Complexity: O(1)
  public func extracting(droppingFirst k: Int = 1) -> Self {
    precondition(k >= 0, "Can't drop a negative number of elements.")
    let dc = k < count ? k : count
    let newStart = _start.advanced(by: dc)
    return Self(_unchecked: newStart, count: count&-dc, owner: self)
  }
}
