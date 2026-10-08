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

extension Deque {
  @frozen
  @usableFromInline
  @unsafe
  internal struct _UnsafeHandle {
    @usableFromInline
    @unsafe
    let _header: UnsafeMutablePointer<_DequeBufferHeader>
    @usableFromInline
    @unsafe
    let _elements: UnsafeMutablePointer<Element>
    #if DEBUG
    @usableFromInline
    @safe
    let _isMutable: Bool
    #endif

    @inlinable
    @inline(__always)
    @unsafe
    init(
      header: UnsafeMutablePointer<_DequeBufferHeader>,
      elements: UnsafeMutablePointer<Element>,
      isMutable: Bool
    ) {
      unsafe self._header = header
      unsafe self._elements = elements
      #if DEBUG
      self._isMutable = isMutable
      #endif
    }
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @inline(__always)
  @safe
  func assertMutable() {
    #if DEBUG
    assert(_isMutable)
    #endif
  }
}

extension Deque._UnsafeHandle {
  @usableFromInline
  internal typealias Slot = _DequeSlot

  @inlinable
  @inline(__always)
  var header: _DequeBufferHeader {
    unsafe _header.pointee
  }

  @inlinable
  @inline(__always)
  var capacity: Int {
    unsafe _header.pointee.capacity
  }

  @inlinable
  @inline(__always)
  var count: Int {
    get { unsafe _header.pointee.count }
    nonmutating set { unsafe _header.pointee.count = newValue }
  }

  @inlinable
  @inline(__always)
  var startSlot: Slot {
    get { unsafe _header.pointee.startSlot }
    nonmutating set { unsafe _header.pointee.startSlot = newValue }
  }

  @inlinable
  @inline(__always)
  @unsafe
  func ptr(at slot: Slot) -> UnsafeMutablePointer<Element> {
    assert(unsafe slot.position >= 0 && slot.position <= capacity)
    return unsafe _elements + slot.position
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @inline(__always)
  var mutableBuffer: UnsafeMutableBufferPointer<Element> {
    assertMutable()
    return unsafe .init(start: _elements, count: _header.pointee.capacity)
  }

  @inlinable
  internal func buffer(for range: Range<Slot>) -> UnsafeBufferPointer<Element> {
    assert(unsafe range.upperBound.position <= capacity)
    return unsafe .init(start: _elements + range.lowerBound.position, count: range._count)
  }

  @inlinable
  @inline(__always)
  internal func mutableBuffer(for range: Range<Slot>) -> UnsafeMutableBufferPointer<Element> {
    assertMutable()
    return unsafe .init(mutating: buffer(for: range))
  }
}

extension Deque._UnsafeHandle {
  /// The slot immediately following the last valid one. (`endSlot` refers to
  /// the valid slot corresponding to `endIndex`, which is a different thing
  /// entirely.)
  @inlinable
  @inline(__always)
  internal var limSlot: Slot {
    unsafe Slot(at: capacity)
  }

  @inlinable
  internal func slot(after slot: Slot) -> Slot {
    assert(unsafe slot.position < capacity)
    let position = slot.position + 1
    if unsafe position >= capacity {
      return Slot(at: 0)
    }
    return Slot(at: position)
  }

  @inlinable
  internal func slot(before slot: Slot) -> Slot {
    let capacity = unsafe self.capacity
    assert(slot.position < capacity)
    if slot.position == 0 { return Slot(at: capacity - 1) }
    return Slot(at: slot.position - 1)
  }

  @inlinable
  internal func slot(_ slot: Slot, offsetBy delta: Int) -> Slot {
    let capacity = unsafe self.capacity
    assert(slot.position <= capacity)
    let position = slot.position + delta
    if delta >= 0 {
      if position >= capacity { return Slot(at: position - capacity) }
    } else {
      if position < 0 { return Slot(at: position + capacity) }
    }
    return Slot(at: position)
  }

  @inlinable
  @inline(__always)
  internal var endSlot: Slot {
    unsafe slot(startSlot, offsetBy: count)
  }

  /// Return the storage slot corresponding to the specified offset, which may
  /// or may not address an existing element.
  @inlinable
  internal func slot(forOffset offset: Int) -> Slot {
    let capacity = unsafe self.capacity
    assert(offset >= 0)
    assert(offset <= capacity) // Not `count`!

    // Note: The use of wrapping addition/subscription is justified here by the
    // fact that `offset` is guaranteed to fall in the range `0 ..< capacity`.
    // Eliminating the overflow checks leads to a measurable speedup for
    // random-access subscript operations. (Up to 2x on some microbenchmarks.)
    let position = unsafe startSlot.position &+ offset
    guard position < capacity else { return Slot(at: position &- capacity) }
    return Slot(at: position)
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @unsafe
  internal func segments() -> _UnsafeDequeSegments<Element> {
    let wrap = unsafe capacity - startSlot.position
    if unsafe count <= wrap {
      return unsafe .init(start: ptr(at: startSlot), count: count)
    }
    return unsafe .init(first: ptr(at: startSlot), count: wrap,
                 second: ptr(at: .zero), count: count - wrap)
  }

  @inlinable
  @unsafe
  internal func segments(
    forOffsets offsets: Range<Int>
  ) -> _UnsafeDequeSegments<Element> {
    assert(unsafe offsets.lowerBound >= 0 && offsets.upperBound <= count)
    let lower = unsafe slot(forOffset: offsets.lowerBound)
    let upper = unsafe slot(forOffset: offsets.upperBound)
    if offsets.count == 0 || lower < upper {
      return unsafe .init(start: ptr(at: lower), count: offsets.count)
    }
    return unsafe .init(
      first: ptr(at: lower), count: capacity - lower.position,
      second: ptr(at: .zero), count: upper.position)
  }

  @inlinable
  @inline(__always)
  @unsafe
  internal func mutableSegments() -> _UnsafeMutableDequeSegments<Element> {
    assertMutable()
    return unsafe .init(mutating: segments())
  }

  @inlinable
  @inline(__always)
  @unsafe
  internal func mutableSegments(
    forOffsets range: Range<Int>
  ) -> _UnsafeMutableDequeSegments<Element> {
    assertMutable()
    return unsafe .init(mutating: segments(forOffsets: range))
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @unsafe
  internal func availableSegments() -> _UnsafeMutableDequeSegments<Element> {
    assertMutable()
    let endSlot = unsafe self.endSlot
    guard unsafe count < capacity else {
      return unsafe .init(start: ptr(at: endSlot), count: 0)
    }
    if unsafe endSlot < startSlot {
      return unsafe .init(mutableBuffer(for: endSlot ..< startSlot))
    }
    return unsafe .init(
      mutableBuffer(for: endSlot ..< limSlot),
      mutableBuffer(for: .zero ..< startSlot))
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @discardableResult
  @unsafe
  func initialize(
    at start: Slot,
    from source: UnsafeBufferPointer<Element>
  ) -> Slot {
    assert(unsafe start.position + source.count <= capacity)
    guard source.count > 0 else { return start }
    unsafe ptr(at: start).initialize(from: source.baseAddress!, count: source.count)
    return Slot(at: start.position + source.count)
  }

  @inlinable
  @inline(__always)
  @discardableResult
  @unsafe
  func moveInitialize(
    at start: Slot,
    from source: UnsafeMutableBufferPointer<Element>
  ) -> Slot {
    assert(unsafe start.position + source.count <= capacity)
    guard source.count > 0 else { return start }
    unsafe ptr(at: start).moveInitialize(from: source.baseAddress!, count: source.count)
    return Slot(at: start.position + source.count)
  }

  @inlinable
  @inline(__always)
  @discardableResult
  @unsafe
  public func move(
    from source: Slot,
    to target: Slot,
    count: Int
  ) -> (source: Slot, target: Slot) {
    assert(count >= 0)
    assert(unsafe source.position + count <= self.capacity)
    assert(unsafe target.position + count <= self.capacity)
    guard count > 0 else { return (source, target) }
    unsafe ptr(at: target).moveInitialize(from: ptr(at: source), count: count)
    return unsafe (slot(source, offsetBy: count), slot(target, offsetBy: count))
  }
}

extension Deque._UnsafeHandle {
  /// Copy elements into a new storage instance without changing capacity or
  /// layout.
  @inlinable
  @unsafe
  internal func copyElements() -> Deque._Storage {
    let object = unsafe _DequeBuffer<Element>.create(
      minimumCapacity: capacity,
      makingHeaderWith: { _ in unsafe header })
    let result = unsafe Deque._Storage(_buffer: ManagedBufferPointer(unsafeBufferObject: object))
    guard unsafe self.count > 0 else { return result }
    unsafe result.update { target in
      let source = unsafe self.segments()
      unsafe target.initialize(at: startSlot, from: source.first)
      if let second = unsafe source.second {
        unsafe target.initialize(at: .zero, from: second)
      }
    }
    return result
  }

  /// Copy elements into a new storage instance with the specified minimum
  /// capacity.
  @inlinable
  @unsafe
  internal func copyElements(minimumCapacity: Int) -> Deque._Storage {
    assert(unsafe minimumCapacity >= count)
    let object = _DequeBuffer<Element>.create(
      minimumCapacity: minimumCapacity,
      makingHeaderWith: { _ in
        return unsafe _DequeBufferHeader(
          capacity: minimumCapacity,
          count: count,
          startSlot: .zero)
      })
    let result = unsafe Deque._Storage(_buffer: ManagedBufferPointer(unsafeBufferObject: object))
    guard unsafe count > 0 else { return result }
    unsafe result.update { target in
      assert(unsafe target.count == count && target.startSlot.position == 0)
      let source = unsafe self.segments()
      let next = unsafe target.initialize(at: .zero, from: source.first)
      if let second = unsafe source.second {
        unsafe target.initialize(at: next, from: second)
      }
    }
    return result
  }

  /// Move elements into a new storage instance with the specified minimum
  /// capacity. Existing indices in `self` won't necessarily be valid in the
  /// result. `self` is left empty.
  @inlinable
  @unsafe
  internal func moveElements(minimumCapacity: Int) -> Deque._Storage {
    assertMutable()
    let count = unsafe self.count
    assert(minimumCapacity >= count)
    let object = _DequeBuffer<Element>.create(
      minimumCapacity: minimumCapacity,
      makingHeaderWith: { _ in
        return _DequeBufferHeader(
          capacity: minimumCapacity,
          count: count,
          startSlot: .zero)
      })
    let result = unsafe Deque._Storage(_buffer: ManagedBufferPointer(unsafeBufferObject: object))
    guard count > 0 else { return result }
    unsafe result.update { target in
      let source = unsafe self.mutableSegments()
      let next = unsafe target.moveInitialize(at: .zero, from: source.first)
      if let second = unsafe source.second {
        unsafe target.moveInitialize(at: next, from: second)
      }
    }
    unsafe self.count = 0
    return result
  }
}

extension Deque._UnsafeHandle {
  @inlinable
  @unsafe
  internal func withUnsafeSegment<R>(
    startingAt start: Int,
    maxCount: Int?,
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> (end: Int, result: R) {
    assert(unsafe start <= count)
    guard unsafe start < count else {
      return unsafe try (count, body(UnsafeBufferPointer(start: nil, count: 0)))
    }
    let endSlot = unsafe self.endSlot

    let segmentStart = unsafe self.slot(forOffset: start)
    let segmentEnd = unsafe segmentStart < endSlot ? endSlot : limSlot
    let count = Swift.min(maxCount ?? Int.max, segmentEnd.position - segmentStart.position)
    let result = unsafe try body(UnsafeBufferPointer(start: ptr(at: segmentStart), count: count))
    return (start + count, result)
  }
}

// MARK: Replacement

extension Deque._UnsafeHandle {
  /// Replace the elements in `range` with `newElements`. The deque's count must
  /// not change as a result of calling this function.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func uncheckedReplaceInPlace<C: Collection>(
    inOffsets range: Range<Int>,
    with newElements: C
  ) where C.Element == Element {
    assertMutable()
    assert(unsafe range.upperBound <= count)
    assert(newElements.count == range.count)
    guard !range.isEmpty else { return }
    let target = unsafe mutableSegments(forOffsets: range)
    unsafe target.reassign(copying: newElements)
  }
}

// MARK: Appending

extension Deque._UnsafeHandle {
  /// Append `element` to this buffer. The buffer must have enough free capacity
  /// to insert one new element.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func uncheckedAppend(_ element: Element) {
    assertMutable()
    assert(unsafe count < capacity)
    unsafe ptr(at: endSlot).initialize(to: element)
    unsafe count += 1
  }

  /// Append the contents of `source` to this buffer. The buffer must have
  /// enough free capacity to insert the new elements.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func uncheckedAppend(contentsOf source: UnsafeBufferPointer<Element>) {
    assertMutable()
    assert(unsafe count + source.count <= capacity)
    guard source.count > 0 else { return }
    let c = unsafe self.count
    unsafe count += source.count
    let gap = unsafe mutableSegments(forOffsets: c ..< count)
    unsafe gap.initialize(copying: source)
  }
}

// MARK: Prepending

extension Deque._UnsafeHandle {
  @inlinable
  @unsafe
  internal func uncheckedPrepend(_ element: Element) {
    assertMutable()
    assert(unsafe count < capacity)
    let slot = unsafe self.slot(before: startSlot)
    unsafe ptr(at: slot).initialize(to: element)
    unsafe startSlot = slot
    unsafe count += 1
  }

  /// Prepend the contents of `source` to this buffer. The buffer must have
  /// enough free capacity to insert the new elements.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func uncheckedPrepend(contentsOf source: UnsafeBufferPointer<Element>) {
    assertMutable()
    assert(unsafe count + source.count <= capacity)
    guard source.count > 0 else { return }
    let oldStart = unsafe startSlot
    let newStart = unsafe self.slot(startSlot, offsetBy: -source.count)
    unsafe startSlot = newStart
    unsafe count += source.count

    let gap = unsafe mutableWrappedBuffer(between: newStart, and: oldStart)
    unsafe gap.initialize(copying: source)
  }
}

// MARK: Insertion

extension Deque._UnsafeHandle {
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
  @inlinable
  @unsafe
  internal func uncheckedInsert<C: Collection>(
    contentsOf newElements: __owned C,
    count newCount: Int,
    atOffset offset: Int
  ) where C.Element == Element {
    assertMutable()
    assert(unsafe offset <= count)
    assert(newElements.count == newCount)
    guard newCount > 0 else { return }
    let gap = unsafe openGap(ofSize: newCount, atOffset: offset)
    unsafe gap.initialize(copying: newElements)
  }

  @inlinable
  @unsafe
  internal func mutableWrappedBuffer(
    between start: Slot,
    and end: Slot
  ) -> _UnsafeMutableDequeSegments<Element> {
    assert(unsafe start.position <= capacity)
    assert(unsafe end.position <= capacity)
    if start < end {
      return unsafe .init(
        start: ptr(at: start),
        count: end.position - start.position)
    }
    return unsafe .init(
      first: ptr(at: start), count: capacity - start.position,
      second: ptr(at: .zero), count: end.position)
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
  @inlinable
  @unsafe
  internal func openGap(
    ofSize gapSize: Int,
    atOffset offset: Int
  ) -> _UnsafeMutableDequeSegments<Element> {
    assertMutable()
    assert(unsafe offset >= 0 && offset <= self.count)
    assert(unsafe self.count + gapSize <= capacity)
    assert(gapSize > 0)

    let headCount = offset
    let tailCount = unsafe count - offset
    if tailCount <= headCount {
      // Open the gap by sliding elements to the right.

      let originalEnd = unsafe self.slot(startSlot, offsetBy: count)
      let newEnd = unsafe self.slot(startSlot, offsetBy: count + gapSize)
      let gapStart = unsafe self.slot(forOffset: offset)
      let gapEnd = unsafe self.slot(gapStart, offsetBy: gapSize)

      let sourceIsContiguous = unsafe gapStart <= originalEnd.orIfZero(capacity)
      let targetIsContiguous = unsafe gapEnd <= newEnd.orIfZero(capacity)

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
        assert(unsafe startSlot > originalEnd.orIfZero(capacity))
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
      unsafe count += gapSize
      return unsafe mutableWrappedBuffer(between: gapStart, and: gapEnd.orIfZero(capacity))
    }

    // Open the gap by sliding elements to the left.

    let originalStart = unsafe self.startSlot
    let newStart = unsafe self.slot(originalStart, offsetBy: -gapSize)
    let gapEnd = unsafe self.slot(forOffset: offset)
    let gapStart = unsafe self.slot(gapEnd, offsetBy: -gapSize)

    let sourceIsContiguous = unsafe originalStart <= gapEnd.orIfZero(capacity)
    let targetIsContiguous = unsafe newStart <= gapStart.orIfZero(capacity)

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
    unsafe startSlot = newStart
    unsafe count += gapSize
    return unsafe mutableWrappedBuffer(between: gapStart, and: gapEnd.orIfZero(capacity))
  }
}

// MARK: Removal

extension Deque._UnsafeHandle {
  @inlinable
  @unsafe
  internal func uncheckedRemoveFirst() -> Element {
    assertMutable()
    assert(unsafe count > 0)
    let result = unsafe ptr(at: startSlot).move()
    unsafe startSlot = slot(after: startSlot)
    unsafe count -= 1
    return result
  }

  @inlinable
  @unsafe
  internal func uncheckedRemoveLast() -> Element {
    assertMutable()
    assert(unsafe count > 0)
    let slot = unsafe self.slot(forOffset: count - 1)
    let result = unsafe ptr(at: slot).move()
    unsafe count -= 1
    return result
  }

  @inlinable
  @unsafe
  internal func uncheckedRemoveFirst(_ n: Int) {
    assertMutable()
    assert(unsafe count >= n)
    guard n > 0 else { return }
    let target = unsafe mutableSegments(forOffsets: 0 ..< n)
    unsafe target.deinitialize()
    unsafe startSlot = slot(startSlot, offsetBy: n)
    unsafe count -= n
  }

  @inlinable
  @unsafe
  internal func uncheckedRemoveLast(_ n: Int) {
    assertMutable()
    assert(unsafe count >= n)
    guard n > 0 else { return }
    let target = unsafe mutableSegments(forOffsets: count - n ..< count)
    unsafe target.deinitialize()
    unsafe count -= n
  }

  /// Remove all elements stored in this instance, deinitializing their storage.
  ///
  /// This method does not ensure that the storage buffer is uniquely
  /// referenced.
  @inlinable
  @unsafe
  internal func uncheckedRemoveAll() {
    assertMutable()
    guard unsafe count > 0 else { return }
    let target = unsafe mutableSegments()
    unsafe target.deinitialize()
    unsafe count = 0
    unsafe startSlot = .zero
  }

  /// Remove all elements in `bounds`, deinitializing their storage and sliding
  /// remaining elements to close the resulting gap.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func uncheckedRemove(offsets bounds: Range<Int>) {
    assertMutable()
    assert(unsafe bounds.lowerBound >= 0 && bounds.upperBound <= self.count)

    // Deinitialize elements in `bounds`.
    unsafe mutableSegments(forOffsets: bounds).deinitialize()
    unsafe closeGap(offsets: bounds)
  }

  /// Close the gap of already uninitialized elements in `bounds`, sliding
  /// elements outside of the gap to eliminate it.
  ///
  /// This function does not validate its input arguments in release builds. Nor
  /// does it ensure that the storage buffer is uniquely referenced.
  @inlinable
  @unsafe
  internal func closeGap(offsets bounds: Range<Int>) {
    assertMutable()
    assert(unsafe bounds.lowerBound >= 0 && bounds.upperBound <= self.count)
    let gapSize = bounds.count
    guard gapSize > 0 else { return }

    let gapStart = unsafe self.slot(forOffset: bounds.lowerBound)
    let gapEnd = unsafe self.slot(forOffset: bounds.upperBound)

    let headCount = bounds.lowerBound
    let tailCount = unsafe count - bounds.upperBound

    if headCount >= tailCount {
      // Close the gap by sliding elements to the left.
      let originalEnd = unsafe endSlot
      let newEnd = unsafe self.slot(forOffset: count - gapSize)

      let sourceIsContiguous = unsafe gapEnd < originalEnd.orIfZero(capacity)
      let targetIsContiguous = unsafe gapStart <= newEnd.orIfZero(capacity)
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
        let c = unsafe capacity - gapStart.position
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
      unsafe count -= gapSize
    } else {
      // Close the gap by sliding elements to the right.
      let originalStart = unsafe startSlot
      let newStart = unsafe slot(startSlot, offsetBy: gapSize)

      let sourceIsContiguous = unsafe originalStart < gapStart.orIfZero(capacity)
      let targetIsContiguous = unsafe newStart <= gapEnd.orIfZero(capacity)

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
      unsafe startSlot = newStart
      unsafe count -= gapSize
    }
  }
}
