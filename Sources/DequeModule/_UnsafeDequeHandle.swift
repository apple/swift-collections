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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

@frozen
@usableFromInline
@unsafe // FIXME: This doesn't own its storage; should we dissolve it into RigidDeque?
package struct _UnsafeDequeHandle<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  package typealias Slot = _DequeSlot

  @usableFromInline
  package var _buffer: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  @unsafe // Setter
  package var _count: Int

  @usableFromInline
  @unsafe // Setter
  package var _startSlot: Slot

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    buffer: UnsafeMutableBufferPointer<Element>,
    count: Int,
    startSlot: _DequeSlot
  ) {
    unsafe self._buffer = buffer
    unsafe self._count = count
    unsafe self._startSlot = startSlot
  }

  @inlinable
  internal consuming func dispose() {
    unsafe _checkInvariants()
    unsafe self.mutableSegments().deinitialize()
    unsafe _buffer.deallocate()
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal static var empty: Self {
    unsafe Self(buffer: ._empty, count: 0, startSlot: .zero)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal static func allocate(
    capacity: Int
  ) -> Self {
    unsafe Self(
      buffer: capacity > 0 ? .allocate(capacity: capacity) : ._empty,
      count: 0,
      startSlot: .zero)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    precondition(unsafe capacity >= 0)
    precondition(unsafe count >= 0 && count <= capacity)
    precondition(unsafe startSlot.position >= 0 && startSlot.position <= capacity)
  }
#else
  @inlinable @inline(__always)
  internal func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @usableFromInline
  @safe
  internal var description: String {
    "(capacity: \(capacity), count: \(count), start: \(startSlot))"
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _baseAddress: UnsafeMutablePointer<Element> {
    unsafe _buffer.baseAddress.unsafelyUnwrapped
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal var count: Int {
    unsafe _assumeNonNegative(_count)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal var capacity: Int {
    unsafe _assumeNonNegative(_buffer.count)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal var startSlot: Slot {
    unsafe _startSlot
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func isIdentical(to other: borrowing Self) -> Bool {
    unsafe self._buffer._isIdentical(to: other._buffer)
    && self.count == other.count
    && self.startSlot == other.startSlot
  }
}

// MARK: Test initializer

extension _UnsafeDequeHandle where Element: ~Copyable {
  internal static func allocate(
    capacity: Int,
    startSlot: Slot,
    count: Int,
    generator: (Int) -> Element
  ) -> Self {
    precondition(capacity >= 0)
    precondition(
      startSlot.position >= 0 &&
      (startSlot.position < capacity || (capacity == 0 && startSlot.position == 0)))
    precondition(count <= capacity)

    var h = unsafe Self.allocate(capacity: capacity)
    unsafe h._count = count
    unsafe h._startSlot = startSlot
    if h.count > 0 {
      let segments = unsafe h.mutableSegments()
      let c = unsafe segments.first.count
      for i in 0 ..< c {
        unsafe segments.first.initializeElement(at: i, to: generator(i))
      }
      if let second = unsafe segments.second {
        for i in c ..< h.count {
          unsafe second.initializeElement(at: i - c, to: generator(i))
        }
      }
    }
    return unsafe h
  }
}

// MARK: Slots

extension _UnsafeDequeHandle where Element: ~Copyable {
  /// The slot immediately following the last valid one. (`endSlot` refers to
  /// the valid slot corresponding to `endIndex`, which is a different thing
  /// entirely.)
  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal var limSlot: Slot {
    Slot(at: capacity)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func slot(after slot: Slot) -> Slot {
    assert(slot.position < capacity)
    let position = slot.position + 1
    if position >= capacity {
      return Slot(at: 0)
    }
    return Slot(at: position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func slot(before slot: Slot) -> Slot {
    assert(slot.position < capacity)
    if slot.position == 0 { return Slot(at: capacity - 1) }
    return Slot(at: slot.position - 1)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func slot(_ slot: Slot, offsetBy delta: Int) -> Slot {
    assert(slot.position <= capacity)
    let position = slot.position + delta
    if delta >= 0 {
      if position >= capacity { return Slot(at: position - capacity) }
    } else {
      if position < 0 { return Slot(at: position + capacity) }
    }
    return Slot(at: position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal var endSlot: Slot {
    slot(startSlot, offsetBy: count)
  }

  /// Return the storage slot corresponding to the specified offset, which may
  /// or may not address an existing element.
  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func slot(forOffset offset: Int) -> Slot {
    assert(offset >= 0)
    assert(offset <= capacity) // Not `count`!

    // Note: The use of wrapping addition/subscription is justified here by the
    // fact that `offset` is guaranteed to fall in the range `0 ..< capacity`.
    // Eliminating the overflow checks leads to a measurable speedup for
    // random-access subscript operations. (Up to 2x on some microbenchmarks.)
    let position = startSlot.position &+ offset
    guard position < capacity else { return Slot(at: position &- capacity) }
    return Slot(at: position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func distance(from start: Slot, to end: Slot) -> Int {
    assert(start.position >= 0 && start.position <= capacity)
    assert(end.position >= 0 && end.position <= capacity)

    if end.position >= start.position {
      return end.position - start.position
    } else {
      // Handle wrap-around case
      return capacity - start.position + end.position
    }
  }
}

// MARK: Element Access

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal func ptr(at slot: Slot) -> UnsafePointer<Element> {
    assert(slot.position >= 0 && slot.position <= capacity)
    return unsafe UnsafePointer(_baseAddress + slot.position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutablePtr(
    at slot: Slot
  ) -> UnsafeMutablePointer<Element> {
    assert(slot.position >= 0 && slot.position <= capacity)
    return unsafe _baseAddress + slot.position
  }
}

// MARK: Access to contiguous regions

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var mutableBuffer: UnsafeMutableBufferPointer<Element> {
    mutating get {
      unsafe _buffer
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func buffer(for range: Range<Slot>) -> UnsafeBufferPointer<Element> {
    assert(range.upperBound.position <= capacity)
    return unsafe .init(_buffer._extracting(unchecked: range._offsets))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableBuffer(
    for range: Range<Slot>
  ) -> UnsafeMutableBufferPointer<Element> {
    assert(range.upperBound.position <= capacity)
    return unsafe _buffer._extracting(unchecked: range._offsets)
  }
}

extension _UnsafeDequeHandle {
  @discardableResult
  @_alwaysEmitIntoClient
  internal mutating func initialize(
    at start: Slot,
    from source: UnsafeBufferPointer<Element>
  ) -> Slot {
    assert(start.position + source.count <= capacity)
    guard source.count > 0 else { return start }
    unsafe mutablePtr(at: start).initialize(from: source.baseAddress!, count: source.count)
    return Slot(at: start.position + source.count)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @discardableResult
  @_alwaysEmitIntoClient
  internal mutating func moveInitialize(
    at start: Slot,
    from source: UnsafeMutableBufferPointer<Element>
  ) -> Slot {
    assert(start.position + source.count <= capacity)
    guard source.count > 0 else { return start }
    unsafe mutablePtr(at: start)
      .moveInitialize(from: source.baseAddress!, count: source.count)
    return Slot(at: start.position + source.count)
  }
}

// MARK: Access to Segments

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal func nextSegment(
    after offset: Int
  ) -> UnsafeBufferPointer<Element> {
    assert(offset >= 0 && offset <= count)
    guard unsafe _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let position = startSlot.position &+ offset
    if position < capacity {
      return unsafe UnsafeBufferPointer(
        start: ptr(at: Slot(at: position)),
        count: Swift.min(count &- offset, capacity &- position))
    }
    // We're after the wrap
    return unsafe UnsafeBufferPointer(
      start: ptr(at: Slot(at: position &- capacity)),
      count: startSlot.position &+ count &- position)
  }

  @_alwaysEmitIntoClient
  internal func nextSegment(
    after offset: inout Int,
    maxCount: Int,
    limitedBy limit: Int
  ) -> UnsafeBufferPointer<Element> {
    assert(limit >= 0 && limit <= count)
    assert(maxCount > 0)
    var segment = unsafe self.nextSegment(after: offset)
      ._extracting(first: maxCount)
    if limit >= offset, segment.count > limit &- offset {
      unsafe segment = segment._extracting(first: limit &- offset)
    }
    offset &+= segment.count
    return unsafe segment
  }

  @_alwaysEmitIntoClient
  internal func previousSegment(
    before offset: Int
  ) -> UnsafeBufferPointer<Element> {
    assert(offset >= 0 && offset <= count)
    guard unsafe _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let slot = startSlot.position &+ offset
    if slot <= capacity {
      return unsafe UnsafeBufferPointer(
        start: ptr(at: startSlot),
        count: offset)
    }
    // We're after the wrap
    return unsafe UnsafeBufferPointer(
      start: ptr(at: Slot(at: 0)),
      count: slot - capacity)
  }

  @_alwaysEmitIntoClient
  internal func spanBoundary(
    before startOffset: Int
  ) -> (offset: Int, distance: Int) {
    assert(startOffset >= 0 && startOffset <= count)
    let wrapOffset = capacity &- startSlot.position
    if startOffset <= wrapOffset {
      return (0, startOffset)
    }
    return (wrapOffset, startOffset &- wrapOffset)
  }

  @_alwaysEmitIntoClient
  internal func spanBoundary(
    before startOffset: Int, maxDistance: Int, limitedBy limitOffset: Int
  ) -> (offset: Int, distance: Int) {
    assert(startOffset >= 0 && startOffset <= count)
    assert(limitOffset >= 0 && limitOffset <= count)
    let wrapOffset = capacity &- startSlot.position
    let p = startOffset._clampedDown(
      towards: startOffset <= wrapOffset ? 0 : wrapOffset,
      maxDistance: maxDistance,
      limitedBy: limitOffset)
    return (p, p &- startOffset)
  }

  @_alwaysEmitIntoClient
  internal func segments() -> _UnsafeDequeSegments<Element> {
    guard unsafe _buffer.baseAddress != nil else {
      return unsafe .init(._empty)
    }
    let wrap = capacity &- startSlot.position
    if count <= wrap {
      return unsafe .init(start: ptr(at: startSlot), count: count)
    }
    return unsafe .init(
      first: ptr(at: startSlot), count: wrap,
      second: ptr(at: .zero), count: count &- wrap)
  }

  @_alwaysEmitIntoClient
  internal func segments(
    forOffsets offsets: Range<Int>
  ) -> _UnsafeDequeSegments<Element> {
    // Note: no asserts for bounds checks, as this is used to implement
    // appends/prepends
    assert(offsets.count <= capacity)
    guard unsafe _buffer.baseAddress != nil else {
      return unsafe .init(._empty)
    }
    let start = slot(forOffset: offsets.lowerBound)
    let wrap = capacity &- start.position
    if offsets.count <= wrap {
      return unsafe .init(start: ptr(at: start), count: offsets.count)
    }
    return unsafe .init(
      first: ptr(at: start), count: capacity &- start.position,
      second: ptr(at: .zero), count: offsets.count &- wrap)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableSegments() -> _UnsafeMutableDequeSegments<Element> {
    unsafe .init(mutating: segments())
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableSegments(
    forOffsets range: Range<Int>
  ) -> _UnsafeMutableDequeSegments<Element> {
    unsafe .init(mutating: segments(forOffsets: range))
  }

  @_alwaysEmitIntoClient
  internal mutating func mutableSegments(
    between start: Slot,
    and end: Slot
  ) -> _UnsafeMutableDequeSegments<Element> {
    assert(start.position <= capacity)
    assert(end.position <= capacity)
    if start < end {
      return unsafe .init(
        start: mutablePtr(at: start),
        count: end.position - start.position)
    }
    return unsafe .init(
      first: mutablePtr(at: start), count: capacity - start.position,
      second: mutablePtr(at: .zero), count: end.position)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func availableSegments() -> _UnsafeMutableDequeSegments<Element> {
    guard unsafe _buffer.baseAddress != nil else {
      return unsafe .init(._empty)
    }
    let endSlot = self.endSlot
    guard count < capacity else {
      return unsafe .init(start: mutablePtr(at: endSlot), count: 0)
    }
    if endSlot < startSlot {
      return unsafe .init(mutableBuffer(for: endSlot ..< startSlot))
    }
    return unsafe .init(
      mutableBuffer(for: endSlot ..< limSlot),
      mutableBuffer(for: .zero ..< startSlot))
  }
}

// MARK: Wholesale Copying and Reallocation

extension _UnsafeDequeHandle {
  /// Copy elements in `handle` into a newly allocated handle without changing its
  /// capacity or layout.
  @_alwaysEmitIntoClient
  internal borrowing func allocateCopy() -> Self {
    var result: _UnsafeDequeHandle<Element> = unsafe .allocate(capacity: self.capacity)
    unsafe result._count = self.count
    unsafe result._startSlot = self.startSlot
    let src = unsafe self.segments()
    unsafe result.initialize(at: self.startSlot, from: src.first)
    if let second = unsafe src.second {
      unsafe result.initialize(at: .zero, from: second)
    }
    return unsafe result
  }

  /// Copy elements in `handle` into a newly allocated handle with the specified
  /// minimum capacity. This operation does not preserve layout.
  @_alwaysEmitIntoClient
  internal func allocateCopy(capacity: Int) -> Self {
    precondition(capacity >= self.count)
    var result: _UnsafeDequeHandle<Element> = unsafe .allocate(capacity: capacity)
    unsafe result._count = self.count
    let src = unsafe self.segments()
    let next = unsafe result.initialize(at: .zero, from: src.first)
    if let second = unsafe src.second {
      unsafe result.initialize(at: next, from: second)
    }
    return unsafe result
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func reallocate(capacity newCapacity: Int) {
    let newCapacity = Swift.max(newCapacity, count)
    guard newCapacity != capacity else { return }

    var new = unsafe _UnsafeDequeHandle<Element>.allocate(capacity: newCapacity)
    let source = unsafe self.mutableSegments()
    let next = unsafe new.moveInitialize(at: .zero, from: source.first)
    if let second = unsafe source.second {
      unsafe new.moveInitialize(at: next, from: second)
    }
    unsafe _buffer.deallocate()
    unsafe _buffer = new._buffer
    unsafe _startSlot = .zero
  }
}

// MARK: Iteration

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal func slotRange(following offset: inout Int) -> Range<Slot> {
    precondition(offset >= 0 && offset <= count, "Index out of bounds")
    guard unsafe _buffer.baseAddress != nil else {
      return unsafe Range(uncheckedBounds: (Slot.zero, Slot.zero))
    }
    let wrapOffset = Swift.min(capacity - startSlot.position, count)

    if offset < wrapOffset {
      defer { offset += wrapOffset - offset }
      return unsafe Range(
        uncheckedBounds: (startSlot.advanced(by: offset), startSlot.advanced(by: wrapOffset)))
    }
    let lowerSlot = Slot.zero.advanced(by: offset - wrapOffset)
    let upperSlot = lowerSlot.advanced(by: count - wrapOffset)
    defer { offset += count - offset }
    return unsafe Range(uncheckedBounds: (lower: lowerSlot, upper: upperSlot))
  }

  @_alwaysEmitIntoClient
  internal func slotRange(preceding offset: inout Int) -> Range<Slot> {
    precondition(offset >= 0 && offset <= count, "Index out of bounds")
    guard unsafe _buffer.baseAddress != nil else {
      return unsafe Range(uncheckedBounds: (Slot.zero, Slot.zero))
    }
    let wrapOffset = Swift.min(capacity - startSlot.position, count)

    if offset <= wrapOffset {
      defer { offset = 0 }
      return unsafe Range(
        uncheckedBounds: (startSlot, startSlot.advanced(by: offset)))
    }
    let lowerSlot = Slot.zero
    let upperSlot = lowerSlot.advanced(by: offset - wrapOffset)
    defer { offset = wrapOffset }
    return unsafe Range(uncheckedBounds: (lower: lowerSlot, upper: upperSlot))
  }
}

// MARK: Swap

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedSwapAt(_ i: Int, _ j: Int) {
    let slot1 = self.slot(forOffset: i)
    let slot2 = self.slot(forOffset: j)
    unsafe self.mutableBuffer.swapAt(slot1.position, slot2.position)
  }
}

// MARK: Replacement

extension _UnsafeDequeHandle {
  /// Replace the elements in `range` with `newElements`. The deque's count must
  /// not change as a result of calling this function.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  internal mutating func uncheckedReplaceInPlace<C: Collection>(
    inOffsets range: Range<Int>,
    with newElements: C
  ) where C.Element == Element {
    assert(range.upperBound <= count)
    assert(newElements.count == range.count)
    guard !range.isEmpty else { return }
    let target = unsafe mutableSegments(forOffsets: range)
    unsafe target.reassign(copying: newElements)
  }
}

// MARK: Consumption

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func unsafeConsumeAll(
    with body: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    let segments = unsafe mutableSegments()
    unsafe body(segments.first)
    if let second = unsafe segments.second {
      unsafe body(second)
    }
    unsafe self._count = 0
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func unsafeConsumePrefix(
    upTo offset: Int,
    with body: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    assert(offset >= 0 && offset <= count)
    let segments = unsafe mutableSegments(forOffsets: Range(uncheckedBounds: (0, offset)))
    unsafe body(segments.first)
    if let second = unsafe segments.second {
      unsafe body(second)
    }
    unsafe self._startSlot = self.slot(forOffset: offset)
    unsafe self._count &-= offset
  }
}

// MARK: Appending and prepending

extension _UnsafeDequeHandle where Element: ~Copyable {
  /// Append `element` to the end of this buffer. The buffer must have enough
  /// free capacity to insert one new element.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedAppend(_ element: consuming Element) {
    assert(count < capacity)
    unsafe mutablePtr(at: endSlot).initialize(to: element)
    unsafe _count &+= 1
  }

  /// Prepend `element` to the front of this buffer. The buffer must have enough
  /// free capacity to insert one new element.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedPrepend(_ element: consuming Element) {
    assert(count < capacity)
    let slot = self.slot(before: startSlot)
    unsafe mutablePtr(at: slot).initialize(to: element)
    unsafe _startSlot = slot
    unsafe _count &+= 1
  }
}

@available(SwiftStdlib 5.0, *)
extension UnsafeMutableBufferPointer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal func _initialize<E: Error, R: ~Copyable>(
    initializedCount: inout Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    var span = unsafe OutputSpan(buffer: self, initializedCount: 0)
    defer {
      unsafe initializedCount &+= span.finalize(for: self)
      span = OutputSpan()
    }
    return try body(&span)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func _append(
    count: Int
  ) -> _UnsafeMutableDequeSegments<Element>? {
    assert(self.count + count <= capacity)
    guard count > 0 else { return nil }
    let origCount = self.count
    unsafe self._count &+= count
    return unsafe self.mutableSegments(forOffsets: origCount ..< origCount + count)
  }

  @_alwaysEmitIntoClient
  internal mutating func _prepend(
    count: Int
  ) -> _UnsafeMutableDequeSegments<Element>? {
    assert(self.count + count <= capacity)
    guard count > 0 else { return nil }
    let oldStart = self.startSlot
    unsafe self._startSlot = self.slot(startSlot, offsetBy: -count)
    unsafe self._count &+= count
    return unsafe self.mutableSegments(between: self.startSlot, and: oldStart)
  }
}

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  /// Append a given number of items to the end of this deque by populating
  /// a series of storage regions through repeated calls of the specified
  /// callback function.
  ///
  /// This unchecked routine does not verify that the deque has sufficient
  /// capacity to store the new items.
  ///
  /// The newly appended items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease when the callback fails to fully populate its output span or when if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated.
  ///
  /// - Parameters:
  ///    - newItemCount: The maximum number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///       is allowed to initialize fewer than `count` items. The deque is
  ///       appended however many items the callback adds to the output span
  ///       before it returns (or before it throws an error).
  /// - Returns: A valid offset range addressing the newly inserted items.
  /// - Complexity: O(`capacity`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedAppend<E: Error>(
    addingCount newItemCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    let origCount = count
    let gap = unsafe self.mutableSegments(forOffsets: count ..< count + newItemCount)
    let c = unsafe self.count &+ gap.first.count
    unsafe try gap.first._initialize(
      initializedCount: &self._count, initializingWith: body)
    if self.count == c, let second = unsafe gap.second {
      unsafe try second._initialize(
        initializedCount: &self._count, initializingWith: body)
    }
    return unsafe Range(uncheckedBounds: (origCount, count))
  }

  /// Prepend a given number of items to the end of this deque by populating
  /// a series of storage regions through repeated calls of the specified
  /// callback function.
  ///
  /// This unchecked routine does not verify that the deque has sufficient
  /// capacity to store the new items.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(10)
  ///     var i = 0
  ///     buffer.prepend(count: 10) { target in
  ///       while !target.isFull {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  ///
  /// The newly prepended items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease when the callback fails to fully populate its output span or when if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(10)
  ///     var i = 0
  ///     buffer.prepend(count: 10) { target in
  ///       while !target.isFull, i <= 5 {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [0, 1, 2, 3, 4, 5, 10]
  ///
  /// - Parameters:
  ///    - newItemCount: The number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///       is allowed to initialize fewer than `count` items. The deque is
  ///       prepended however many items the callback adds to output span
  ///       before it returns (or before it throws an error).
  /// - Returns: A valid offset range addressing the newly inserted items.
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  package mutating func uncheckedPrepend<E: Error>(
    addingCount newItemCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    guard let gap = unsafe self._prepend(count: newItemCount) else {
      return 0 ..< 0
    }

    var c = 0
    defer {
      if c < newItemCount {
        unsafe closeGap(offsets: c ..< newItemCount)
      }
    }
    unsafe try gap.first._initialize(initializedCount: &c, initializingWith: body)
    if unsafe c == gap.first.count, let second = unsafe gap.second {
      unsafe try second._initialize(initializedCount: &c, initializingWith: body)
    }
    return unsafe Range(uncheckedBounds: (0, c))
  }
}

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  /// Appends the elements of a buffer to the end of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// This unchecked routine does not verify that the deque has sufficient
  /// capacity to store the new items.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  /// - Returns: A valid offset range addressing the newly inserted items.
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedAppend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) -> Range<Int> {
    guard let gap = unsafe _append(count: items.count) else {
      return count ..< count
    }

    unsafe gap.first.moveInitializeAll(
      fromContentsOf: items._extracting(first: gap.first.count))

    if let second = unsafe gap.second {
      assert(unsafe gap.first.count + second.count == items.count)
      unsafe second.moveInitializeAll(
        fromContentsOf: items._extracting(last: second.count))
    }
    return unsafe Range(uncheckedBounds: (count &- items.count, count))
  }

  /// Prepends the elements of a buffer to the front of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// This unchecked routine does not verify that the deque has sufficient
  /// capacity to store the new items.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  /// - Returns: A valid offset range addressing the newly inserted items.
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedPrepend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) -> Range<Int> {
    guard let gap = unsafe _prepend(count: items.count) else { return 0 ..< 0 }

    unsafe gap.first.moveInitializeAll(
      fromContentsOf: items._extracting(first: gap.first.count))

    if let second = unsafe gap.second {
      assert(unsafe gap.first.count + second.count == items.count)
      unsafe second.moveInitializeAll(
        fromContentsOf: items._extracting(last: second.count))
    }
    return unsafe Range(uncheckedBounds: (0, items.count))
  }
}

extension _UnsafeDequeHandle {
  /// Append the contents of `source` to this buffer. The buffer must have
  /// enough free capacity to insert the new elements.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedAppend(
    copying source: UnsafeBufferPointer<Element>
  ) -> Range<Int> {
    guard let gap = unsafe _append(count: source.count) else {
      return count ..< count
    }
    unsafe gap.initialize(copying: source)
    return unsafe Range(uncheckedBounds: (count &- source.count, count))
  }

  /// Prepend the contents of `source` to this buffer. The buffer must have
  /// enough free capacity to insert the new elements.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedPrepend(
    copying source: UnsafeBufferPointer<Element>
  ) -> Range<Int> {
    guard let gap = unsafe _prepend(count: source.count) else { return 0 ..< 0 }
    unsafe gap.initialize(copying: source)
    return unsafe Range(uncheckedBounds: (0, source.count))
  }
}

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle {
  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func uncheckedAppend<S: Sequence<Element>>(
    copyingPrefixOf items: S
  ) -> S.Iterator {
    // Note: You're supposed to handle contiguous sequences before calling
    // this function. You do this by invoking `withContiguousStorageIfAvailable`.
    let (it, c) = unsafe self.availableSegments().initialize(fromSequencePrefix: items)
    unsafe self._count += c
    return it
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func uncheckedPrepend<C: Collection<Element>>(
    copying items: C,
    exactCount: Int
  ) -> Range<Int> {
    // Note: You're supposed to handle contiguous sequences before calling
    // this function. You do this by invoking `withContiguousStorageIfAvailable`.
    guard let gap = unsafe self._prepend(count: exactCount) else {
      return 0 ..< 0
    }
    unsafe gap.initialize(copying: items)
    return unsafe Range(uncheckedBounds: (0, exactCount))
  }
}

// MARK: Opening and Closing Gaps

extension _UnsafeDequeHandle where Element: ~Copyable {
  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func move(
    from source: Slot,
    to target: Slot,
    count: Int
  ) -> (source: Slot, target: Slot) {
    assert(count >= 0)
    assert(source.position + count <= self.capacity)
    assert(target.position + count <= self.capacity)
    guard count > 0 else { return (source, target) }
    unsafe mutablePtr(at: target)
      .moveInitialize(from: mutablePtr(at: source), count: count)
    return (slot(source, offsetBy: count), slot(target, offsetBy: count))
  }

  @_alwaysEmitIntoClient
  @_transparent
  func isLeftLeaning(_ offset: Int) -> Bool {
    offset < count - offset
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  internal func isLeftLeaning(_ subrange: Range<Int>) -> Bool {
    subrange.lowerBound < count - subrange.upperBound
  }

  /// Slide elements around so that there is a gap of uninitialized slots of
  /// size `gapSize` starting at `offset`, and return a (potentially wrapped)
  /// buffer holding the newly inserted slots.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  ///
  /// - Parameter gapSize: The number of uninitialized slots to create.
  /// - Parameter offset: The offset from the start at which the uninitialized
  ///    slots should start.
  @_alwaysEmitIntoClient
  internal mutating func openGap(
    ofSize gapSize: Int,
    atOffset offset: Int
  ) -> _UnsafeMutableDequeSegments<Element> {
    assert(offset >= 0 && offset <= self.count)
    assert(self.count + gapSize <= capacity)
    assert(gapSize > 0)

    let headCount = offset
    let tailCount = count - offset
    if tailCount <= headCount {
      // Open the gap by sliding elements to the right.

      let originalEnd = self.slot(startSlot, offsetBy: count)
      let newEnd = self.slot(startSlot, offsetBy: count + gapSize)
      let gapStart = self.slot(forOffset: offset)
      let gapEnd = self.slot(gapStart, offsetBy: gapSize)

      let sourceIsContiguous = gapStart <= originalEnd.orIfZero(capacity)
      let targetIsContiguous = gapEnd <= newEnd.orIfZero(capacity)

      if sourceIsContiguous && targetIsContiguous {
        // No need to deal with wrapping; we just need to slide
        // elements after the gap.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) ....ABCDE̲F̲G̲H.....      EFG̲H̲.̲........ABCD      .̲.......ABCDEFGH̲.̲
        //   1) ....ABCD.̲.̲.̲EFGH..      EF.̲.̲.̲GH......ABCD      .̲H......ABCDEFG.̲.̲
        unsafe move(from: gapStart, to: gapEnd, count: tailCount)
      } else if targetIsContiguous {
        // The gap itself will be wrapped.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) E̲FGH.........ABC̲D̲
        //   1) .̲..EFGH......ABC̲D̲
        //   2) .̲CDEFGH......AB.̲.̲
        assert(startSlot > originalEnd.orIfZero(capacity))
        unsafe move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: originalEnd.position)
        unsafe move(from: gapStart, to: gapEnd, count: capacity - gapStart.position)
      } else if sourceIsContiguous {
        // Opening the gap pushes subsequent elements across the wrap.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) ........ABC̲D̲E̲FGH.
        //   1) GH......ABC̲D̲E̲F...
        //   2) GH......AB.̲.̲.̲CDEF
        unsafe move(from: limSlot.advanced(by: -gapSize), to: .zero, count: newEnd.position)
        unsafe move(from: gapStart, to: gapEnd, count: tailCount - newEnd.position)
      } else {
        // The rest of the items are wrapped, and will remain so.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) GH.........AB̲C̲D̲EF
        //   1) ...GH......AB̲C̲D̲EF
        //   2) DEFGH......AB̲C̲.̲..
        //   3) DEFGH......A.̲.̲.̲BC
        unsafe move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: originalEnd.position)
        unsafe move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapSize)
        unsafe move(from: gapStart, to: gapEnd, count: tailCount - gapSize - originalEnd.position)
      }
      unsafe _count += gapSize
      return unsafe mutableSegments(between: gapStart, and: gapEnd.orIfZero(capacity))
    }

    // Open the gap by sliding elements to the left.

    let originalStart = self.startSlot
    let newStart = self.slot(originalStart, offsetBy: -gapSize)
    let gapEnd = self.slot(forOffset: offset)
    let gapStart = self.slot(gapEnd, offsetBy: -gapSize)

    let sourceIsContiguous = originalStart <= gapEnd.orIfZero(capacity)
    let targetIsContiguous = newStart <= gapStart.orIfZero(capacity)

    if sourceIsContiguous && targetIsContiguous {
      // No need to deal with any wrapping.

      // Illustrated steps: (underscores mark eventual gap position)
      //
      //   0) ....A̲B̲C̲DEFGH...      GH.........̲A̲B̲CDEF      .̲A̲B̲CDEFGH.......̲.̲
      //   1) .ABC.̲.̲.̲DEFGH...      GH......AB.̲.̲.̲CDEF      .̲.̲.̲CDEFGH....AB.̲.̲
      unsafe move(from: originalStart, to: newStart, count: headCount)
    } else if targetIsContiguous {
      // The gap itself will be wrapped.

      // Illustrated steps: (underscores mark eventual gap position)
      //
      //   0) C̲D̲EFGH.........A̲B̲
      //   1) C̲D̲EFGH.....AB...̲.̲
      //   2) .̲.̲EFGH.....ABCD.̲.̲
      assert(originalStart >= newStart)
      unsafe move(from: originalStart, to: newStart, count: capacity - originalStart.position)
      unsafe move(from: .zero, to: limSlot.advanced(by: -gapSize), count: gapEnd.position)
    } else if sourceIsContiguous {
      // Opening the gap pushes preceding elements across the wrap.

      // Illustrated steps: (underscores mark eventual gap position)
      //
      //   0) .AB̲C̲D̲EFGH.........
      //   1) ...̲C̲D̲EFGH.......AB
      //   2) CD.̲.̲.̲EFGH.......AB
      unsafe move(from: originalStart, to: newStart, count: capacity - newStart.position)
      unsafe move(from: Slot.zero.advanced(by: gapSize), to: .zero, count: gapStart.position)
    } else {
      // The preceding of the items are wrapped, and will remain so.

      // Illustrated steps: (underscores mark eventual gap position)
      //   0) CD̲E̲F̲GHIJKL.........AB
      //   1) CD̲E̲F̲GHIJKL......AB...
      //   2) ..̲.̲F̲GHIJKL......ABCDE
      //   3) F.̲.̲.̲GHIJKL......ABCDE
      unsafe move(from: originalStart, to: newStart, count: capacity - originalStart.position)
      unsafe move(from: .zero, to: limSlot.advanced(by: -gapSize), count: gapSize)
      unsafe move(from: Slot.zero.advanced(by: gapSize), to: .zero, count: gapStart.position)
    }
    unsafe _startSlot = newStart
    unsafe _count += gapSize
    return unsafe mutableSegments(between: gapStart, and: gapEnd.orIfZero(capacity))
  }

  /// Close the gap of already uninitialized elements in `bounds`, sliding
  /// elements outside of the gap to eliminate it, and updating `count` to
  /// reflect the removal.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func closeGap(offsets bounds: Range<Int>) {
    assert(bounds.lowerBound >= 0 && bounds.upperBound <= self.count)
    let gapSize = bounds.count
    guard gapSize > 0 else { return }

    let gapStart = self.slot(forOffset: bounds.lowerBound)
    let gapEnd = self.slot(forOffset: bounds.upperBound)

    let headCount = bounds.lowerBound
    let tailCount = count - bounds.upperBound

    if headCount >= tailCount {
      // Close the gap by sliding elements to the left.
      let originalEnd = endSlot
      let newEnd = self.slot(forOffset: count - gapSize)

      let sourceIsContiguous = gapEnd < originalEnd.orIfZero(capacity)
      let targetIsContiguous = gapStart <= newEnd.orIfZero(capacity)
      if tailCount == 0 {
        // No need to move any elements.
      } else if sourceIsContiguous && targetIsContiguous {
        // No need to deal with wrapping.

        //   0) ....ABCD.̲.̲.̲EFGH..   EF.̲.̲.̲GH........ABCD   .̲.̲.̲E..........ABCD.̲.̲   .̲.̲.̲EF........ABCD .̲.̲.̲DE.......ABC
        //   1) ....ABCDE̲F̲G̲H.....   EFG̲H̲.̲..........ABCD   .̲.̲.̲...........ABCDE̲.̲   E̲F̲.̲..........ABCD D̲E̲.̲.........ABC
        unsafe move(from: gapEnd, to: gapStart, count: tailCount)
      } else if sourceIsContiguous {
        // The gap lies across the wrap from the subsequent elements.

        //   0) .̲.̲.̲EFGH.......ABCD.̲.̲      EFGH.......ABCD.̲.̲.̲
        //   1) .̲.̲.̲..GH.......ABCDE̲F̲      ..GH.......ABCDE̲F̲G̲
        //   2) G̲H̲.̲...........ABCDE̲F̲      GH.........ABCDE̲F̲G̲
        let c = capacity - gapStart.position
        assert(tailCount > c)
        let next = unsafe move(from: gapEnd, to: gapStart, count: c)
        unsafe move(from: next.source, to: .zero, count: tailCount - c)
      } else if targetIsContiguous {
        // We need to move elements across a wrap, but the wrap will
        // disappear when we're done.

        //   0) HI....ABCDE.̲.̲.̲FG
        //   1) HI....ABCDEF̲G̲.̲..
        //   2) ......ABCDEF̲G̲H̲I.
        let next = unsafe move(from: gapEnd, to: gapStart, count: capacity - gapEnd.position)
        unsafe move(from: .zero, to: next.target, count: originalEnd.position)
      } else {
        // We need to move elements across a wrap that won't go away.

        //   0) HIJKL....ABCDE.̲.̲.̲FG
        //   1) HIJKL....ABCDEF̲G̲.̲..
        //   2) ...KL....ABCDEF̲G̲H̲IJ
        //   3) KL.......ABCDEF̲G̲H̲IJ
        var next = unsafe move(from: gapEnd, to: gapStart, count: capacity - gapEnd.position)
        next = unsafe move(from: .zero, to: next.target, count: gapSize)
        unsafe move(from: next.source, to: .zero, count: newEnd.position)
      }
      unsafe _count -= gapSize
    } else {
      // Close the gap by sliding elements to the right.
      let originalStart = startSlot
      let newStart = slot(startSlot, offsetBy: gapSize)

      let sourceIsContiguous = originalStart < gapStart.orIfZero(capacity)
      let targetIsContiguous = newStart <= gapEnd.orIfZero(capacity)

      if headCount == 0 {
        // No need to move any elements.
      } else if sourceIsContiguous && targetIsContiguous {
        // No need to deal with wrapping.

        //   0) ....ABCD.̲.̲.̲EFGH.....   EFGH........AB.̲.̲.̲CD   .̲.̲.̲CDEFGH.......AB.̲.̲   DEFGH.......ABC.̲.̲
        //   1) .......AB̲C̲D̲EFGH.....   EFGH...........̲A̲B̲CD   .̲A̲B̲CDEFGH..........̲.̲   DEFGH.........AB̲C̲     ABCDEFGH........̲.̲.̲
        unsafe move(from: originalStart, to: newStart, count: headCount)
      } else if sourceIsContiguous {
        // The gap lies across the wrap from the preceding elements.

        //   0) .̲.̲DEFGH.......ABC.̲.̲     .̲.̲.̲EFGH.......ABCD
        //   1) B̲C̲DEFGH.......A...̲.̲     B̲C̲D̲DEFGH......A...
        //   2) B̲C̲DEFGH...........̲A̲     B̲C̲D̲DEFGH.........A
        unsafe move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapEnd.position)
        unsafe move(from: startSlot, to: newStart, count: headCount - gapEnd.position)
      } else if targetIsContiguous {
        // We need to move elements across a wrap, but the wrap will
        // disappear when we're done.

        //   0) CD.̲.̲.̲EFGHI.....AB
        //   1) ...̲C̲D̲EFGHI.....AB
        //   1) .AB̲C̲D̲EFGHI.......
        unsafe move(from: .zero, to: gapEnd.advanced(by: -gapStart.position), count: gapStart.position)
        unsafe move(from: startSlot, to: newStart, count: headCount - gapStart.position)
      } else {
        // We need to move elements across a wrap that won't go away.
        //   0) FG.̲.̲.̲HIJKLMNO....ABCDE
        //   1) ...̲F̲G̲HIJKLMNO....ABCDE
        //   2) CDE̲F̲G̲HIJKLMNO....AB...
        //   3) CDE̲F̲G̲HIJKLMNO.......AB
        unsafe move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: gapStart.position)
        unsafe move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapSize)
        unsafe move(from: startSlot, to: newStart, count: headCount - gapEnd.position)
      }
      unsafe _startSlot = newStart
      unsafe _count -= gapSize
    }
  }
}

// MARK: Rotating elements

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func rotate(
    toStartAtOffset newStart: Int
  ) {
    let oldCount = count
    // Open a gap at `newStart` that's the size of the free capacity, swapping
    // the positions of the prefix (`startSlot..<newStart`) and suffix
    // (newStart..<endSlot`). The `openGap` method decides whether to move the
    // prefix or suffix.

    // Illustrated steps: (underscores mark suffix)
    //
    //   0) ....ABCDE̲F̲G̲....      ....ABC̲D̲E̲F̲G̲....
    //   1) .E̲F̲G̲ABCD.......      ......C̲D̲E̲F̲G̲AB..

    let gapSize = capacity - count
    if gapSize > 0 {
      _ = unsafe openGap(ofSize: gapSize, atOffset: newStart)
    }

    // With the prefix and suffix swapped, update the starting slot and
    // restore the count.
    unsafe _startSlot = slot(startSlot, offsetBy: newStart - oldCount)
    unsafe _count = oldCount
  }
}

// MARK: Insertion

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedInsert(
    _ newElement: consuming Element, at offset: Int
  ) -> Int {
    assert(count < capacity)
    if offset == 0 {
      unsafe uncheckedPrepend(newElement)
      return offset
    }
    if offset == count {
      unsafe uncheckedAppend(newElement)
      return offset
    }
    let gap = unsafe openGap(ofSize: 1, atOffset: offset)
    assert(unsafe gap.first.count == 1)
    unsafe gap.first.baseAddress!.initialize(to: newElement)
    return offset
  }
}

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func uncheckedInsert<E: Error>(
    addingCount newItemCount: Int,
    at offset: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    guard newItemCount > 0 else { return offset ..< offset }
    let gap = unsafe self.openGap(ofSize: newItemCount, atOffset: offset)

    var c = 0
    defer {
      if c < newItemCount {
        unsafe closeGap(offsets: offset + c ..< offset + newItemCount)
      }
    }
    unsafe try gap.first._initialize(initializedCount: &c, initializingWith: body)
    if unsafe c == gap.first.count, let second = unsafe gap.second {
      unsafe try second._initialize(initializedCount: &c, initializingWith: body)
    }
    return unsafe Range(uncheckedBounds: (offset, offset &+ c))
  }
}

extension _UnsafeDequeHandle {
  /// Insert all elements from `newElements` into this deque, starting at
  /// `offset`.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  ///
  /// - Parameter newElements: The elements to insert.
  /// - Parameter newCount: Must be equal to `newElements.count`. Used to
  ///    prevent calling `count` more than once.
  /// - Parameter offset: The desired offset from the start at which to place
  ///    the first element.
  @_alwaysEmitIntoClient
  internal mutating func uncheckedInsert<C: Collection>(
    contentsOf newElements: __owned C,
    count newCount: Int,
    atOffset offset: Int
  ) where C.Element == Element {
    assert(offset <= count)
    assert(newElements.count == newCount)
    guard newCount > 0 else { return }
    let gap = unsafe openGap(ofSize: newCount, atOffset: offset)
    unsafe gap.initialize(copying: newElements)
  }
}

// MARK: Removal

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemove(at offset: Int) -> Element {
    let slot = self.slot(forOffset: offset)
    let result = unsafe mutablePtr(at: slot).move()
    unsafe closeGap(offsets: Range(uncheckedBounds: (offset, offset + 1)))
    return result
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveFirst() -> Element {
    assert(count > 0)
    let result = unsafe mutablePtr(at: startSlot).move()
    unsafe _startSlot = slot(after: startSlot)
    unsafe _count -= 1
    return result
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveLast() -> Element {
    assert(count > 0)
    let slot = self.slot(forOffset: count - 1)
    let result = unsafe mutablePtr(at: slot).move()
    unsafe _count -= 1
    return result
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveFirst(_ n: Int) {
    assert(count >= n)
    guard n > 0 else { return }
    let target = unsafe mutableSegments(forOffsets: 0 ..< n)
    unsafe target.deinitialize()
    unsafe _startSlot = slot(startSlot, offsetBy: n)
    unsafe _count -= n
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveLast(_ n: Int) {
    assert(count >= n)
    guard n > 0 else { return }
    let target = unsafe mutableSegments(forOffsets: count - n ..< count)
    unsafe target.deinitialize()
    unsafe _count -= n
  }

  /// Remove all elements stored in this instance, deinitializing their storage.
  ///
  /// This method does not ensure that the storage buffer is uniquely
  /// referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveAll() {
    guard count > 0 else { return }
    let target = unsafe mutableSegments()
    unsafe target.deinitialize()
    unsafe _count = 0
    unsafe _startSlot = .zero
  }

  /// Remove all elements in `bounds`, deinitializing their storage and sliding
  /// remaining elements to close the resulting gap.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemove(offsets bounds: Range<Int>) -> Int {
    assert(bounds.lowerBound >= 0 && bounds.upperBound <= self.count)

    // Deinitialize elements in `bounds`.
    unsafe mutableSegments(forOffsets: bounds).deinitialize()
    unsafe closeGap(offsets: bounds)
    return bounds.lowerBound
  }
}

// MARK: Replacement

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func _insertAfterReplace<E: Error>(
    _ subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    // Note: we're careful to open/close the gap in a direction that does not
    // lead to trying to move slots we deinitialized above.
    let delta = newItemCount - subrange.count
    let left = isLeftLeaning(subrange)
    if delta > 0 {
      _ = unsafe self.openGap(
        ofSize: delta,
        atOffset: (left ? subrange.lowerBound : subrange.upperBound))
    } else {
      unsafe self.closeGap(
        offsets: (left ? subrange.prefix(-delta) : subrange.suffix(-delta)))
    }
    let newRange = unsafe Range(
      uncheckedBounds: (
        subrange.lowerBound,
        subrange.lowerBound &+ newItemCount))
    let gap = unsafe self.mutableSegments(forOffsets: newRange)

    var c = 0
    defer {
      if c < newItemCount {
        unsafe closeGap(offsets: newRange.dropFirst(c))
      }
    }
    try unsafe gap.first._initialize(initializedCount: &c, initializingWith: initializer)
    if unsafe c == gap.first.count, let second = unsafe gap.second {
      unsafe try second._initialize(initializedCount: &c, initializingWith: initializer)
    }
    return unsafe Range(uncheckedBounds: (newRange.lowerBound, newRange.lowerBound &+ c))
  }

  @_alwaysEmitIntoClient
  internal mutating func uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    assert(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Subrange out of bounds")
    assert(newItemCount >= 0, "Cannot add a negative number of items")
    assert(count + newItemCount - subrange.count <= capacity, "RigidDeque capacity overflow")
    unsafe self.mutableSegments(forOffsets: subrange).deinitialize()
    return unsafe try _insertAfterReplace(
      subrange,
      addingCount: newItemCount,
      initializingWith: initializer)
  }

#if UnstableContainersPreview
  @_alwaysEmitIntoClient
  internal mutating func uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    assert(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Subrange out of bounds")
    assert(newItemCount >= 0, "Cannot add a negative number of items")
    assert(count + newItemCount - subrange.count <= capacity, "RigidDeque capacity overflow")
    do {
      let removed = unsafe self.mutableSegments(forOffsets: subrange)
      var span = unsafe InputSpan(
        buffer: removed.first,
        initializedCount: removed.first.count)
      consumer(&span)
      if let second = unsafe removed.second {
        span = unsafe InputSpan(buffer: second, initializedCount: second.count)
        consumer(&span)
      }
    }
    return unsafe try _insertAfterReplace(
      subrange,
      addingCount: newItemCount,
      initializingWith: initializer)
  }
#endif
}
