//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import _CollectionsUtilities
import Future
#endif

@frozen
public struct HypoDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  internal typealias _Handle = _UnsafeDequeHandle<Element>

  @usableFromInline
  var _handle: _Handle

  @inlinable
  public init(capacity: Int) {
    _handle = .allocate(capacity: capacity)
  }

  deinit {
    _handle.dispose()
  }
}

extension HypoDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension HypoDeque: RandomAccessContainer where Element: ~Copyable {
  @frozen
  public struct BorrowingIterator:
    BorrowingIteratorProtocol, ~Copyable, ~Escapable
  {
    @usableFromInline
    internal let _segments: _UnsafeWrappedBuffer<Element>

    @usableFromInline
    internal var _offset: Int

    @inlinable
    internal init(_for handle: borrowing _Handle, startOffset: Int) {
      self._segments = handle.segments()
      self._offset = startOffset
    }

    @inlinable
    public mutating func nextChunk(
      maximumCount: Int
    ) -> dependsOn(self) Span<Element> {
      precondition(maximumCount > 0)
      if _offset < _segments.first.count {
        let d = Swift.min(maximumCount, _segments.first.count - _offset)
        let slice = _segments.first.extracting(_offset ..< _offset + d)
        _offset += d
        return Span(unsafeElements: slice, owner: self)
      }
      guard let second = _segments.second else {
        return Span(unsafeElements: UnsafeBufferPointer._empty, owner: self)
      }
      let o = _offset - _segments.first.count
      let d = Swift.min(maximumCount, second.count - o)
      let slice = second.extracting(o ..< o + d)
      _offset += d
      return Span(unsafeElements: slice, owner: self)
    }
  }

  public func startBorrowingIteration() -> BorrowingIterator {
    BorrowingIterator(_for: _handle, startOffset: 0)
  }

  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    BorrowingIterator(_for: _handle, startOffset: start)
  }

  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { _handle.count == 0 }

  @inlinable
  public var count: Int { _handle.count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { count }

  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    _read {
      precondition(position >= 0 && position < count)
      let slot = _handle.slot(forOffset: position)
      yield _handle.ptr(at: slot).pointee
    }
    @inline(__always)
    _modify {
      precondition(position >= 0 && position < count)
      let slot = _handle.slot(forOffset: position)
      yield &_handle.mutablePtr(at: slot).pointee
    }
  }

  public func index(at position: borrowing BorrowingIterator) -> Int {
    precondition(_handle.segments().isIdentical(to: position._segments))
    return position._offset
  }
}

extension HypoDeque where Element: ~Copyable {
  @inlinable
  public var capacity: Int { _handle.capacity }

  @inlinable
  public var freeCapacity: Int { capacity - count }

  @inlinable
  public var isFull: Bool { count == capacity }

  @inlinable
  public mutating func resize(to newCapacity: Int) {
    precondition(newCapacity >= count)
    guard newCapacity != capacity else { return }
    var newHandle = _Handle.allocate(capacity: newCapacity)
    newHandle.startSlot = .zero
    newHandle.count = _handle.count
    let source = _handle.mutableSegments()
    let next = newHandle.moveInitialize(at: .zero, from: source.first)
    if let second = source.second {
      newHandle.moveInitialize(at: next, from: second)
    }
    self._handle._storage.deallocate()
    self._handle = newHandle
  }
}

extension HypoDeque where Element: ~Copyable {
  @inlinable
  public mutating func append(_ newElement: consuming Element) {
    precondition(!isFull, "HypoDeque is full")
    _handle.uncheckedAppend(newElement)
  }

  @inlinable
  public mutating func prepend(_ newElement: consuming Element) {
    precondition(!isFull, "HypoDeque is full")
    _handle.uncheckedPrepend(newElement)
  }

  @inlinable
  public mutating func insert(_ newElement: consuming Element, at index: Int) {
    precondition(!isFull, "HypoDeque is full")
    precondition(index >= 0 && index <= count,
                 "Can't insert element at invalid index")
    _handle.uncheckedInsert(newElement, at: index)
  }
}

extension HypoDeque where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < count,
                 "Can't remove element at invalid index")
    return _handle.uncheckedRemove(at: index)
  }

  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                 "Index range out of bounds")
    _handle.uncheckedRemove(offsets: bounds)
  }

  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty HypoDeque")
    return _handle.uncheckedRemoveFirst()
  }

  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty HypoDeque")
    return _handle.uncheckedRemoveLast()
  }

  @inlinable
  public mutating func removeFirst(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a HypoDeque")
    _handle.uncheckedRemoveFirst(n)
  }

  @inlinable
  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a HypoDeque")
    _handle.uncheckedRemoveLast(n)
  }

  @inlinable
  public mutating func removeAll() {
    _handle.uncheckedRemoveAll()
  }

  @inlinable
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveFirst()
  }

  @inlinable
  public mutating func popLast() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveLast()
  }
}
