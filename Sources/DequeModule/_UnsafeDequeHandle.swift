//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

@frozen
@usableFromInline
@unsafe
package struct _UnsafeDequeHandle<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  package typealias Slot = _DequeSlot

  @usableFromInline
  package var _buffer: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  package var count: Int

  @usableFromInline
  package var startSlot: Slot

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    buffer: UnsafeMutableBufferPointer<Element>,
    count: Int,
    startSlot: _DequeSlot
  ) {
    self._buffer = buffer
    self.count = count
    self.startSlot = startSlot
  }

  @inlinable
  internal consuming func dispose() {
    _checkInvariants()
    self.mutableSegments().deinitialize()
    _buffer.deallocate()
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal static var empty: Self {
    Self(buffer: ._empty, count: 0, startSlot: .zero)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal static func allocate(
    capacity: Int
  ) -> Self {
    Self(
      buffer: capacity > 0 ? .allocate(capacity: capacity) : ._empty,
      count: 0,
      startSlot: .zero)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    precondition(capacity >= 0)
    precondition(count >= 0 && count <= capacity)
    precondition(startSlot.position >= 0 && startSlot.position <= capacity)
  }
#else
  @inlinable @inline(__always)
  internal func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @usableFromInline
  internal var description: String {
    "(capacity: \(capacity), count: \(count), start: \(startSlot))"
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _baseAddress: UnsafeMutablePointer<Element> {
    _buffer.baseAddress.unsafelyUnwrapped
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal var capacity: Int {
    _buffer.count
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

    var h = Self.allocate(capacity: capacity)
    h.count = count
    h.startSlot = startSlot
    if h.count > 0 {
      let segments = h.mutableSegments()
      let c = segments.first.count
      for i in 0 ..< c {
        segments.first.initializeElement(at: i, to: generator(i))
      }
      if let second = segments.second {
        for i in c ..< h.count {
          second.initializeElement(at: i - c, to: generator(i))
        }
      }
    }
    return h
  }
}

// MARK: Slots

extension _UnsafeDequeHandle where Element: ~Copyable {
  /// The slot immediately following the last valid one. (`endSlot` refers to
  /// the valid slot corresponding to `endIndex`, which is a different thing
  /// entirely.)
  @_alwaysEmitIntoClient
  @_transparent
  internal var limSlot: Slot {
    Slot(at: capacity)
  }

  @_alwaysEmitIntoClient
  @_transparent
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
  internal func slot(before slot: Slot) -> Slot {
    assert(slot.position < capacity)
    if slot.position == 0 { return Slot(at: capacity - 1) }
    return Slot(at: slot.position - 1)
  }

  @_alwaysEmitIntoClient
  @_transparent
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
  internal var endSlot: Slot {
    slot(startSlot, offsetBy: count)
  }

  /// Return the storage slot corresponding to the specified offset, which may
  /// or may not address an existing element.
  @_alwaysEmitIntoClient
  @_transparent
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
    return UnsafePointer(_baseAddress + slot.position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutablePtr(
    at slot: Slot
  ) -> UnsafeMutablePointer<Element> {
    assert(slot.position >= 0 && slot.position <= capacity)
    return _baseAddress + slot.position
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @inlinable
  internal subscript(offset offset: Int) -> Element {
    @inline(__always)
    _read {
      precondition(offset >= 0 && offset < count, "Index out of bounds")
      let slot = slot(forOffset: offset)
      yield ptr(at: slot).pointee
    }
    @inline(__always)
    _modify {
      precondition(offset >= 0 && offset < count, "Index out of bounds")
      let slot = slot(forOffset: offset)
      yield &mutablePtr(at: slot).pointee
    }
  }
}

// MARK: Access to contiguous regions

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var mutableBuffer: UnsafeMutableBufferPointer<Element> {
    mutating get {
      _buffer
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func buffer(for range: Range<Slot>) -> UnsafeBufferPointer<Element> {
    assert(range.upperBound.position <= capacity)
    return .init(_buffer._extracting(unchecked: range._offsets))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableBuffer(
    for range: Range<Slot>
  ) -> UnsafeMutableBufferPointer<Element> {
    assert(range.upperBound.position <= capacity)
    return _buffer._extracting(unchecked: range._offsets)
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
    mutablePtr(at: start).initialize(from: source.baseAddress!, count: source.count)
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
    mutablePtr(at: start)
      .moveInitialize(from: source.baseAddress!, count: source.count)
    return Slot(at: start.position + source.count)
  }
}

// MARK: Access to Segments

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal func nextSegment(
    from startOffset: Int
  ) -> UnsafeBufferPointer<Element> {
    assert(startOffset >= 0 && startOffset <= count)
    guard _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let position = startSlot.position &+ startOffset
    if position < capacity {
      return UnsafeBufferPointer(
        start: ptr(at: Slot(at: position)),
        count: Swift.min(count &- startOffset, capacity &- position))
    }
    // We're after the wrap
    return UnsafeBufferPointer(
      start: ptr(at: Slot(at: position &- capacity)),
      count: startSlot.position &+ count &- position)
  }

  @_alwaysEmitIntoClient
  internal func segments() -> _UnsafeDequeSegments<Element> {
    guard _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let wrap = capacity - startSlot.position
    if count <= wrap {
      return .init(start: ptr(at: startSlot), count: count)
    }
    return .init(first: ptr(at: startSlot), count: wrap,
                 second: ptr(at: .zero), count: count - wrap)
  }

  @_alwaysEmitIntoClient
  internal func segments(
    forOffsets offsets: Range<Int>
  ) -> _UnsafeDequeSegments<Element> {
    // Note: no asserts for bounds checks, as this is used to implement
    // appends/prepends
    assert(offsets.count <= capacity)
    guard _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let lower = slot(forOffset: offsets.lowerBound)
    let upper = slot(forOffset: offsets.upperBound)
    if offsets.count == 0 || lower < upper {
      return .init(start: ptr(at: lower), count: offsets.count)
    }
    return .init(first: ptr(at: lower), count: capacity - lower.position,
                 second: ptr(at: .zero), count: upper.position)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableSegments() -> _UnsafeMutableDequeSegments<Element> {
    .init(mutating: segments())
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func mutableSegments(
    forOffsets range: Range<Int>
  ) -> _UnsafeMutableDequeSegments<Element> {
    .init(mutating: segments(forOffsets: range))
  }

  @_alwaysEmitIntoClient
  internal mutating func mutableSegments(
    between start: Slot,
    and end: Slot
  ) -> _UnsafeMutableDequeSegments<Element> {
    assert(start.position <= capacity)
    assert(end.position <= capacity)
    if start < end {
      return .init(
        start: mutablePtr(at: start),
        count: end.position - start.position)
    }
    return .init(
      first: mutablePtr(at: start), count: capacity - start.position,
      second: mutablePtr(at: .zero), count: end.position)
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func availableSegments() -> _UnsafeMutableDequeSegments<Element> {
    guard _buffer.baseAddress != nil else {
      return .init(._empty)
    }
    let endSlot = self.endSlot
    guard count < capacity else { return .init(start: mutablePtr(at: endSlot), count: 0) }
    if endSlot < startSlot { return .init(mutableBuffer(for: endSlot ..< startSlot)) }
    return .init(mutableBuffer(for: endSlot ..< limSlot),
                 mutableBuffer(for: .zero ..< startSlot))
  }
}

// MARK: Wholesale Copying and Reallocation

extension _UnsafeDequeHandle {
  /// Copy elements in `handle` into a newly allocated handle without changing its
  /// capacity or layout.
  @_alwaysEmitIntoClient
  internal borrowing func allocateCopy() -> Self {
    var result: _UnsafeDequeHandle<Element> = .allocate(capacity: self.capacity)
    result.count = self.count
    result.startSlot = self.startSlot
    let src = self.segments()
    result.initialize(at: self.startSlot, from: src.first)
    if let second = src.second {
      result.initialize(at: .zero, from: second)
    }
    return result
  }

  /// Copy elements in `handle` into a newly allocated handle with the specified
  /// minimum capacity. This operation does not preserve layout.
  @_alwaysEmitIntoClient
  internal func allocateCopy(capacity: Int) -> Self {
    precondition(capacity >= self.count)
    var result: _UnsafeDequeHandle<Element> = .allocate(capacity: capacity)
    result.count = self.count
    let src = self.segments()
    let next = result.initialize(at: .zero, from: src.first)
    if let second = src.second {
      result.initialize(at: next, from: second)
    }
    return result
  }
}

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func reallocate(capacity newCapacity: Int) {
    precondition(newCapacity >= count, "Capacity overflow")
    guard newCapacity != capacity else { return }

    var new = _UnsafeDequeHandle<Element>.allocate(capacity: newCapacity)
    let source = self.mutableSegments()
    let next = new.moveInitialize(at: .zero, from: source.first)
    if let second = source.second {
      new.moveInitialize(at: next, from: second)
    }
    _buffer.deallocate()
    _buffer = new._buffer
    startSlot = .zero
  }
}

// MARK: Iteration

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal func slotRange(following offset: inout Int) -> Range<Slot> {
    precondition(offset >= 0 && offset <= count, "Index out of bounds")
    guard _buffer.baseAddress != nil else {
      return Range(uncheckedBounds: (Slot.zero, Slot.zero))
    }
    let wrapOffset = Swift.min(capacity - startSlot.position, count)

    if offset < wrapOffset {
      defer { offset += wrapOffset - offset }
      return Range(
        uncheckedBounds: (startSlot.advanced(by: offset), startSlot.advanced(by: wrapOffset)))
    }
    let lowerSlot = Slot.zero.advanced(by: offset - wrapOffset)
    let upperSlot = lowerSlot.advanced(by: count - wrapOffset)
    defer { offset += count - offset }
    return Range(uncheckedBounds: (lower: lowerSlot, upper: upperSlot))
  }

  @_alwaysEmitIntoClient
  internal func slotRange(preceding offset: inout Int) -> Range<Slot> {
    precondition(offset >= 0 && offset <= count, "Index out of bounds")
    guard _buffer.baseAddress != nil else {
      return Range(uncheckedBounds: (Slot.zero, Slot.zero))
    }
    let wrapOffset = Swift.min(capacity - startSlot.position, count)

    if offset <= wrapOffset {
      defer { offset = 0 }
      return Range(
        uncheckedBounds: (startSlot, startSlot.advanced(by: offset)))
    }
    let lowerSlot = Slot.zero
    let upperSlot = lowerSlot.advanced(by: offset - wrapOffset)
    defer { offset = wrapOffset }
    return Range(uncheckedBounds: (lower: lowerSlot, upper: upperSlot))
  }
}

// MARK: Swap

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedSwapAt(_ i: Int, _ j: Int) {
    let slot1 = self.slot(forOffset: i)
    let slot2 = self.slot(forOffset: j)
    self.mutableBuffer.swapAt(slot1.position, slot2.position)
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
    let target = mutableSegments(forOffsets: range)
    target.reassign(copying: newElements)
  }
}

// MARK: Consumption

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func unsafeConsumeAll(
    with body: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    let segments = mutableSegments()
    body(segments.first)
    if let second = segments.second {
      body(second)
    }
    self.count = 0
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func unsafeConsumePrefix(
    upTo offset: Int,
    with body: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    assert(offset >= 0 && offset <= count)
    let segments = mutableSegments(forOffsets: Range(uncheckedBounds: (0, offset)))
    body(segments.first)
    if let second = segments.second {
      body(second)
    }
    self.startSlot = self.slot(forOffset: offset)
    self.count &-= offset
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
    mutablePtr(at: endSlot).initialize(to: element)
    count += 1
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
    mutablePtr(at: slot).initialize(to: element)
    startSlot = slot
    count += 1
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
    var span = OutputSpan(buffer: self, initializedCount: 0)
    defer {
      initializedCount &+= span.finalize(for: self)
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
    guard count > 0 else { return nil }
    let origCount = self.count
    self.count &+= count
    return self.mutableSegments(forOffsets: origCount ..< origCount + count)
  }

  @_alwaysEmitIntoClient
  internal mutating func _prepend(
    count: Int
  ) -> _UnsafeMutableDequeSegments<Element>? {
    assert(self.count + count <= capacity)
    guard count > 0 else { return .init() }
    let oldStart = self.startSlot
    self.startSlot = self.slot(startSlot, offsetBy: -count)
    self.count &+= count
    
    return self.mutableSegments(between: self.startSlot, and: oldStart)
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
  /// - Parameters
  ///    - capacity: The maximum number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///       is allowed to initialize fewer than `count` items. The deque is
  ///       appended however many items the callback adds to the output span
  ///       before it returns (or before it throws an error).
  ///
  /// - Complexity: O(`capacity`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedAppend<E: Error>(
    capacity: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    let origCount = self.count
    let gap = self.mutableSegments(forOffsets: origCount ..< origCount + capacity)
    try gap.first._initialize(
      initializedCount: &self.count, initializingWith: body)
    if self.count == origCount + gap.first.count, let second = gap.second {
      try second._initialize(
        initializedCount: &self.count, initializingWith: body)
    }
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
  /// - Parameters
  ///    - count: The number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///       is allowed to initialize fewer than `count` items. The deque is
  ///       prepended however many items the callback adds to output span
  ///       before it returns (or before it throws an error).
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedPrepend<E: Error>(
    count: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    guard let gap = self._prepend(count: count) else { return }
    
    var c = 0
    defer {
      if c < count {
        closeGap(offsets: c ..< count)
      }
    }
    try gap.first._initialize(initializedCount: &c, initializingWith: body)
    if c == gap.first.count, let second = gap.second {
      try second._initialize(initializedCount: &c, initializingWith: body)
    }
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
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedAppend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    guard let gap = _append(count: items.count) else { return }
    
    gap.first.moveInitializeAll(
      fromContentsOf: items._extracting(first: gap.first.count))
    
    if let second = gap.second {
      assert(gap.first.count + second.count == items.count)
      second.moveInitializeAll(
        fromContentsOf: items._extracting(last: second.count))
    }
  }
  
  /// Prepends the elements of a buffer to the front of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// This unchecked routine does not verify that the deque has sufficient
  /// capacity to store the new items.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  internal mutating func uncheckedPrepend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    guard let gap = _prepend(count: items.count) else { return }
    
    gap.first.moveInitializeAll(
      fromContentsOf: items._extracting(first: gap.first.count))
    
    if let second = gap.second {
      assert(gap.first.count + second.count == items.count)
      second.moveInitializeAll(
        fromContentsOf: items._extracting(last: second.count))
    }
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
  internal mutating func uncheckedAppend(copying source: UnsafeBufferPointer<Element>) {
    guard let gap = _append(count: source.count) else { return }
    gap.initialize(copying: source)
  }
  
  /// Prepend the contents of `source` to this buffer. The buffer must have
  /// enough free capacity to insert the new elements.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedPrepend(copying source: UnsafeBufferPointer<Element>) {
    guard let gap = _prepend(count: source.count) else { return }
    gap.initialize(copying: source)
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
    let (it, c) = self.availableSegments().initialize(fromSequencePrefix: items)
    self.count += c
    return it
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func uncheckedPrepend<C: Collection<Element>>(
    copying items: C,
    exactCount: Int
  ) {
    // Note: You're supposed to handle contiguous sequences before calling
    // this function. You do this by invoking `withContiguousStorageIfAvailable`.
    guard let gap = self._prepend(count: exactCount) else { return }
    gap.initialize(copying: items)
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
    mutablePtr(at: target)
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
  func isLeftLeaning(_ subrange: Range<Int>) -> Bool {
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
  @_transparent
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
        move(from: gapStart, to: gapEnd, count: tailCount)
      } else if targetIsContiguous {
        // The gap itself will be wrapped.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) E̲FGH.........ABC̲D̲
        //   1) .̲..EFGH......ABC̲D̲
        //   2) .̲CDEFGH......AB.̲.̲
        assert(startSlot > originalEnd.orIfZero(capacity))
        move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: originalEnd.position)
        move(from: gapStart, to: gapEnd, count: capacity - gapStart.position)
      } else if sourceIsContiguous {
        // Opening the gap pushes subsequent elements across the wrap.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) ........ABC̲D̲E̲FGH.
        //   1) GH......ABC̲D̲E̲F...
        //   2) GH......AB.̲.̲.̲CDEF
        move(from: limSlot.advanced(by: -gapSize), to: .zero, count: newEnd.position)
        move(from: gapStart, to: gapEnd, count: tailCount - newEnd.position)
      } else {
        // The rest of the items are wrapped, and will remain so.

        // Illustrated steps: (underscores mark eventual gap position)
        //
        //   0) GH.........AB̲C̲D̲EF
        //   1) ...GH......AB̲C̲D̲EF
        //   2) DEFGH......AB̲C̲.̲..
        //   3) DEFGH......A.̲.̲.̲BC
        move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: originalEnd.position)
        move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapSize)
        move(from: gapStart, to: gapEnd, count: tailCount - gapSize - originalEnd.position)
      }
      count += gapSize
      return mutableSegments(between: gapStart, and: gapEnd.orIfZero(capacity))
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
      move(from: originalStart, to: newStart, count: headCount)
    } else if targetIsContiguous {
      // The gap itself will be wrapped.

      // Illustrated steps: (underscores mark eventual gap position)
      //
      //   0) C̲D̲EFGH.........A̲B̲
      //   1) C̲D̲EFGH.....AB...̲.̲
      //   2) .̲.̲EFGH.....ABCD.̲.̲
      assert(originalStart >= newStart)
      move(from: originalStart, to: newStart, count: capacity - originalStart.position)
      move(from: .zero, to: limSlot.advanced(by: -gapSize), count: gapEnd.position)
    } else if sourceIsContiguous {
      // Opening the gap pushes preceding elements across the wrap.

      // Illustrated steps: (underscores mark eventual gap position)
      //
      //   0) .AB̲C̲D̲EFGH.........
      //   1) ...̲C̲D̲EFGH.......AB
      //   2) CD.̲.̲.̲EFGH.......AB
      move(from: originalStart, to: newStart, count: capacity - newStart.position)
      move(from: Slot.zero.advanced(by: gapSize), to: .zero, count: gapStart.position)
    } else {
      // The preceding of the items are wrapped, and will remain so.

      // Illustrated steps: (underscores mark eventual gap position)
      //   0) CD̲E̲F̲GHIJKL.........AB
      //   1) CD̲E̲F̲GHIJKL......AB...
      //   2) ..̲.̲F̲GHIJKL......ABCDE
      //   3) F.̲.̲.̲GHIJKL......ABCDE
      move(from: originalStart, to: newStart, count: capacity - originalStart.position)
      move(from: .zero, to: limSlot.advanced(by: -gapSize), count: gapSize)
      move(from: Slot.zero.advanced(by: gapSize), to: .zero, count: gapStart.position)
    }
    startSlot = newStart
    count += gapSize
    return mutableSegments(between: gapStart, and: gapEnd.orIfZero(capacity))
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
        move(from: gapEnd, to: gapStart, count: tailCount)
      } else if sourceIsContiguous {
        // The gap lies across the wrap from the subsequent elements.

        //   0) .̲.̲.̲EFGH.......ABCD.̲.̲      EFGH.......ABCD.̲.̲.̲
        //   1) .̲.̲.̲..GH.......ABCDE̲F̲      ..GH.......ABCDE̲F̲G̲
        //   2) G̲H̲.̲...........ABCDE̲F̲      GH.........ABCDE̲F̲G̲
        let c = capacity - gapStart.position
        assert(tailCount > c)
        let next = move(from: gapEnd, to: gapStart, count: c)
        move(from: next.source, to: .zero, count: tailCount - c)
      } else if targetIsContiguous {
        // We need to move elements across a wrap, but the wrap will
        // disappear when we're done.

        //   0) HI....ABCDE.̲.̲.̲FG
        //   1) HI....ABCDEF̲G̲.̲..
        //   2) ......ABCDEF̲G̲H̲I.
        let next = move(from: gapEnd, to: gapStart, count: capacity - gapEnd.position)
        move(from: .zero, to: next.target, count: originalEnd.position)
      } else {
        // We need to move elements across a wrap that won't go away.

        //   0) HIJKL....ABCDE.̲.̲.̲FG
        //   1) HIJKL....ABCDEF̲G̲.̲..
        //   2) ...KL....ABCDEF̲G̲H̲IJ
        //   3) KL.......ABCDEF̲G̲H̲IJ
        var next = move(from: gapEnd, to: gapStart, count: capacity - gapEnd.position)
        next = move(from: .zero, to: next.target, count: gapSize)
        move(from: next.source, to: .zero, count: newEnd.position)
      }
      count -= gapSize
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
        move(from: originalStart, to: newStart, count: headCount)
      } else if sourceIsContiguous {
        // The gap lies across the wrap from the preceding elements.

        //   0) .̲.̲DEFGH.......ABC.̲.̲     .̲.̲.̲EFGH.......ABCD
        //   1) B̲C̲DEFGH.......A...̲.̲     B̲C̲D̲DEFGH......A...
        //   2) B̲C̲DEFGH...........̲A̲     B̲C̲D̲DEFGH.........A
        move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapEnd.position)
        move(from: startSlot, to: newStart, count: headCount - gapEnd.position)
      } else if targetIsContiguous {
        // We need to move elements across a wrap, but the wrap will
        // disappear when we're done.

        //   0) CD.̲.̲.̲EFGHI.....AB
        //   1) ...̲C̲D̲EFGHI.....AB
        //   1) .AB̲C̲D̲EFGHI.......
        move(from: .zero, to: gapEnd.advanced(by: -gapStart.position), count: gapStart.position)
        move(from: startSlot, to: newStart, count: headCount - gapStart.position)
      } else {
        // We need to move elements across a wrap that won't go away.
        //   0) FG.̲.̲.̲HIJKLMNO....ABCDE
        //   1) ...̲F̲G̲HIJKLMNO....ABCDE
        //   2) CDE̲F̲G̲HIJKLMNO....AB...
        //   3) CDE̲F̲G̲HIJKLMNO.......AB
        move(from: .zero, to: Slot.zero.advanced(by: gapSize), count: gapStart.position)
        move(from: limSlot.advanced(by: -gapSize), to: .zero, count: gapSize)
        move(from: startSlot, to: newStart, count: headCount - gapEnd.position)
      }
      startSlot = newStart
      count -= gapSize
    }
  }
}

// MARK: Rotating elements

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @discardableResult
  internal mutating func rotate(
    toStartAt newStart: Slot
  ) -> Slot {
    let currentCount = count
    let suffixCount = distance(from: newStart, to: endSlot)
    
    // Open a gap at `newStart` that's the size of the free capacity, swapping
    // the positions of the prefix (`startSlot..<newStart`) and suffix
    // (newStart..<endSlot`). The `openGap` method decides whether to move the
    // prefix or suffix.

    // Illustrated steps: (underscores mark suffix)
    //
    //   0) ....ABCDE̲F̲G̲....      ....ABC̲D̲E̲F̲G̲....
    //   1) .E̲F̲G̲ABCD.......      ......C̲D̲E̲F̲G̲AB..

    let gapSize = capacity - count
    let gapOffset = distance(from: startSlot, to: newStart)
    if gapSize > 0 {
      _ = openGap(ofSize: gapSize, atOffset: gapOffset)
    }
    
    // With the prefix and suffix swapped, update the starting slot and
    // restore the count.
    let oldStart = startSlot
    startSlot = slot(startSlot, offsetBy: -suffixCount)
    count = currentCount
    return oldStart
  }
}

// MARK: Insertion

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedInsert(
    _ newElement: consuming Element, at offset: Int
  ) {
    assert(count < capacity)
    if offset == 0 {
      uncheckedPrepend(newElement)
      return
    }
    if offset == count {
      uncheckedAppend(newElement)
      return
    }
    let gap = openGap(ofSize: 1, atOffset: offset)
    assert(gap.first.count == 1)
    gap.first.baseAddress!.initialize(to: newElement)
  }
}

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func uncheckedInsert<E: Error>(
    capacity: Int,
    at offset: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    guard capacity > 0 else { return }
    let gap = self.openGap(ofSize: capacity, atOffset: offset)
    
    var c = 0
    defer {
      if c < capacity {
        closeGap(offsets: offset + c ..< offset + capacity)
      }
    }
    try gap.first._initialize(initializedCount: &c, initializingWith: body)
    if c == gap.first.count, let second = gap.second {
      try second._initialize(initializedCount: &c, initializingWith: body)
    }
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
  @_transparent
  internal mutating func uncheckedInsert<C: Collection>(
    contentsOf newElements: __owned C,
    count newCount: Int,
    atOffset offset: Int
  ) where C.Element == Element {
    assert(offset <= count)
    assert(newElements.count == newCount)
    guard newCount > 0 else { return }
    let gap = openGap(ofSize: newCount, atOffset: offset)
    gap.initialize(copying: newElements)
  }
}

// MARK: Removal

extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemove(at offset: Int) -> Element {
    let slot = self.slot(forOffset: offset)
    let result = mutablePtr(at: slot).move()
    closeGap(offsets: Range(uncheckedBounds: (offset, offset + 1)))
    return result
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveFirst() -> Element {
    assert(count > 0)
    let result = mutablePtr(at: startSlot).move()
    startSlot = slot(after: startSlot)
    count -= 1
    return result
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveLast() -> Element {
    assert(count > 0)
    let slot = self.slot(forOffset: count - 1)
    let result = mutablePtr(at: slot).move()
    count -= 1
    return result
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveFirst(_ n: Int) {
    assert(count >= n)
    guard n > 0 else { return }
    let target = mutableSegments(forOffsets: 0 ..< n)
    target.deinitialize()
    startSlot = slot(startSlot, offsetBy: n)
    count -= n
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveLast(_ n: Int) {
    assert(count >= n)
    guard n > 0 else { return }
    let target = mutableSegments(forOffsets: count - n ..< count)
    target.deinitialize()
    count -= n
  }
  
  /// Remove all elements stored in this instance, deinitializing their storage.
  ///
  /// This method does not ensure that the storage buffer is uniquely
  /// referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemoveAll() {
    guard count > 0 else { return }
    let target = mutableSegments()
    target.deinitialize()
    count = 0
    startSlot = .zero
  }
  
  /// Remove all elements in `bounds`, deinitializing their storage and sliding
  /// remaining elements to close the resulting gap.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedRemove(offsets bounds: Range<Int>) {
    assert(bounds.lowerBound >= 0 && bounds.upperBound <= self.count)
    
    // Deinitialize elements in `bounds`.
    mutableSegments(forOffsets: bounds).deinitialize()
    closeGap(offsets: bounds)
  }
}

// MARK: Replacement

@available(SwiftStdlib 5.0, *)
extension _UnsafeDequeHandle where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func _insertAfterReplace<E: Error>(
    _ subrange: Range<Int>,
    newCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    // Note: we're careful to open/close the gap in a direction that does not
    // lead to trying to move slots we deinitialized above.
    let delta = newCount - subrange.count
    let left = isLeftLeaning(subrange)
    if delta > 0 {
      _ = self.openGap(
        ofSize: delta,
        atOffset: (left ? subrange.lowerBound : subrange.upperBound))
    } else {
      self.closeGap(
        offsets: (left ? subrange.prefix(-delta) : subrange.suffix(-delta)))
    }
    let newRange = Range(uncheckedBounds: (subrange.lowerBound, newCount))
    let gap = self.mutableSegments(forOffsets: newRange)
    
    var c = 0
    defer {
      if c < newCount {
        closeGap(offsets: newRange.dropFirst(c))
      }
    }
    try gap.first._initialize(initializedCount: &c, initializingWith: initializer)
    if c == gap.first.count, let second = gap.second {
      try second._initialize(initializedCount: &c, initializingWith: initializer)
    }
  }

  @_alwaysEmitIntoClient
  internal mutating func uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    newCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    assert(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Subrange out of bounds")
    assert(newCount >= 0, "Negative count")
    assert(count + newCount - subrange.count <= capacity, "RigidDeque capacity overflow")
    self.mutableSegments(forOffsets: subrange).deinitialize()
    try _insertAfterReplace(subrange, newCount: newCount, initializingWith: initializer)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  internal mutating func uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    newCount: Int,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    assert(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Subrange out of bounds")
    assert(newCount >= 0, "Negative count")
    assert(count + newCount - subrange.count <= capacity, "RigidDeque capacity overflow")
    do {
      let removed = self.mutableSegments(forOffsets: subrange)
      var span = InputSpan(
        buffer: removed.first,
        initializedCount: removed.first.count)
      consumer(&span)
      if let second = removed.second {
        span = InputSpan(buffer: second, initializedCount: second.count)
        consumer(&span)
      }
    }
    try _insertAfterReplace(subrange, newCount: newCount, initializingWith: initializer)
  }
#endif
}
