/// A manually resizable, heap allocated, noncopyable array of
/// potentially noncopyable elements.
@frozen
public struct HypoArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal var _count: Int

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0)
    if capacity > 0 {
      _storage = .allocate(capacity: capacity)
    } else {
      _storage = .init(start: nil, count: 0)
    }
    _count = 0
  }

  @inlinable
  public init(count: Int, initializedBy generator: (Int) -> Element) {
    _storage = .allocate(capacity: count)
    for i in 0 ..< count {
      _storage.initializeElement(at: i, to: generator(i))
    }
    _count = count
  }

  deinit {
    _storage.extracting(0 ..< count).deinitialize()
    _storage.deallocate()
  }
}

extension HypoArray: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension HypoArray where Element: ~Copyable {
  @inlinable
  public var capacity: Int { _storage.count }

  @inlinable
  public var freeCapacity: Int { capacity - count }

  @inlinable
  public var isFull: Bool { freeCapacity == 0 }
}

extension HypoArray: RandomAccessContainer where Element: ~Copyable {
  public struct BorrowingIterator:
    BorrowingIteratorProtocol, ~Copyable, ~Escapable
  {
    @usableFromInline
    internal let _items: UnsafeBufferPointer<Element>

    @usableFromInline
    internal var _offset: Int

    @inlinable
    internal init(for array: borrowing HypoArray, startOffset: Int) {
      self._items = UnsafeBufferPointer(array._items)
      self._offset = startOffset
    }

    public mutating func nextChunk(
      maximumCount: Int
    ) -> dependsOn(self) Span<Element> {
      let end = _offset + Swift.min(maximumCount, _items.count - _offset)
      defer { _offset = end }
      let chunk = _items.extracting(Range(uncheckedBounds: (_offset, end)))
      return Span(unsafeElements: chunk, owner: self)
    }
  }

  public func startBorrowingIteration() -> BorrowingIterator {
    BorrowingIterator(for: self, startOffset: 0)
  }

  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    BorrowingIterator(for: self, startOffset: start)
  }

  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { count == 0 }

  @inlinable
  public var count: Int { _count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { count }

  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    _read {
      precondition(position >= 0 && position < _count)
      yield _storage[position]
    }
    @inline(__always)
    _modify {
      precondition(position >= 0 && position < _count)
      yield &_storage[position]
    }
  }

  @inlinable
  public func index(at position: borrowing BorrowingIterator) -> Int {
    precondition(position._items === UnsafeBufferPointer(self._items))
    return position._offset
  }
}

extension HypoArray where Element: ~Copyable {
  @inlinable
  internal var _items: UnsafeMutableBufferPointer<Element> {
    _storage.extracting(Range(uncheckedBounds: (0, _count)))
  }

  @inlinable
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    _storage.extracting(Range(uncheckedBounds: (_count, capacity)))
  }
}

extension HypoArray where Element: ~Copyable {
  @inlinable
  public mutating func resize(to newCapacity: Int) {
    precondition(newCapacity >= count)
    guard newCapacity != capacity else { return }
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(capacity: newCapacity)
    let i = newStorage.moveInitialize(fromContentsOf: self._items)
    assert(i == count)
    _storage.deallocate()
    _storage = newStorage
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    resize(to: n)
  }
}


extension HypoArray where Element: ~Copyable {
  @inlinable
  public func borrowElement<E: Error, R: ~Copyable> (
    at index: Int,
    by body: (borrowing Element) throws(E) -> R
  ) throws(E) -> R {
    precondition(index >= 0 && index < _count)
    return try body(_storage[index])
  }

  @inlinable
  public mutating func updateElement<E: Error, R: ~Copyable> (
    at index: Int,
    by body: (inout Element) throws(E) -> R
  ) throws(E) -> R {
    precondition(index >= 0 && index < _count)
    return try body(&_storage[index])
  }
}

extension HypoArray where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < count)
    let old = _storage.moveElement(from: index)
    let source = _storage.extracting(index + 1 ..< count)
    let target = _storage.extracting(index ..< count - 1)
    let i = target.moveInitialize(fromContentsOf: source)
    assert(i == target.endIndex)
    _count -= 1
    return old
  }
}

extension HypoArray where Element: ~Copyable {
  @inlinable
  public mutating func append(_ item: consuming Element) {
    precondition(!isFull)
    _storage.initializeElement(at: _count, to: item)
    _count += 1
  }
}

extension HypoArray where Element: ~Copyable {
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    precondition(!isFull)
    if index < count {
      let source = _storage.extracting(index ..< count)
      let target = _storage.extracting(index + 1 ..< count + 1)
      let last = target.moveInitialize(fromContentsOf: source)
      assert(last == target.endIndex)
    }
    _storage.initializeElement(at: index, to: item)
    _count += 1
  }
}

extension HypoArray {
  @inlinable
  public mutating func append(contentsOf items: some Sequence<Element>) {
    for item in items {
      append(item)
    }
  }
}
