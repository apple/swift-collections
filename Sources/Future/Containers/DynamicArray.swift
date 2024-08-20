/// A dynamically self-resizing, heap allocated, noncopyable array
/// of potentially noncopyable elements.
@frozen
public struct DynamicArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidArray<Element>

  @inlinable
  public init() {
    _storage = .init(capacity: 0)
  }

  @inlinable
  public init(minimumCapacity: Int) {
    _storage = .init(capacity: minimumCapacity)
  }

  @inlinable
  public init(count: Int, initializedBy generator: (Int) -> Element) {
    _storage = .init(count: count, initializedBy: generator)
  }
}

extension DynamicArray: Sendable where Element: Sendable & ~Copyable {}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public var capacity: Int { _storage.capacity }
}

extension DynamicArray where Element: ~Copyable {
  public var span: Span<Element> {
    _storage.span
  }
}

extension DynamicArray: RandomAccessContainer where Element: ~Copyable {
  public typealias BorrowingIterator = RigidArray<Element>.BorrowingIterator
  public typealias Index = Int

  public func startBorrowingIteration() -> BorrowingIterator {
    BorrowingIterator(for: _storage, startOffset: 0)
  }

  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    BorrowingIterator(for: _storage, startOffset: start)
  }

  @inlinable
  public var isEmpty: Bool { _storage.isEmpty }

  @inlinable
  public var count: Int { _storage.count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _storage.count }

  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    _read {
      yield _storage[position]
    }
    @inline(__always)
    _modify {
      yield &_storage[position]
    }
  }

  @inlinable
  public func index(after i: Int) -> Int { i + 1 }

  @inlinable
  public func index(before i: Int) -> Int { i - 1 }

  @inlinable
  public func formIndex(after index: inout Int) {
    // Note: Range checks are deferred until element access.
    index += 1
  }

  @inlinable
  public func formIndex(before index: inout Int) {
    // Note: Range checks are deferred until element access.
    index -= 1
  }

  @inlinable
  public func index(at position: borrowing BorrowingIterator) -> Int {
    // Note: Range checks are deferred until element access.
    position._offset
  }

  @inlinable
  public func distance(from start: Int, to end: Int) -> Int {
    // Note: Range checks are deferred until element access.
    end - start
  }

  @inlinable
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    // Note: Range checks are deferred until element access.
    index + n
  }

  @inlinable
  public func formIndex(
    _ index: inout Int, offsetBy distance: inout Int, limitedBy limit: Int
  ) {
    _storage.formIndex(&index, offsetBy: &distance, limitedBy: limit)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public func borrowElement<E: Error, R: ~Copyable> (
    at index: Int,
    by body: (borrowing Element) throws(E) -> R
  ) throws(E) -> R {
    try _storage.borrowElement(at: index, by: body)
  }

  @inlinable
  public mutating func updateElement<E: Error, R: ~Copyable> (
    at index: Int,
    by body: (inout Element) throws(E) -> R
  ) throws(E) -> R {
    try _storage.updateElement(at: index, by: body)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    _storage.reserveCapacity(n)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  internal static func _grow(_ capacity: Int) -> Int {
    2 * capacity
  }

  @inlinable
  public mutating func _ensureFreeCapacity(_ minimumCapacity: Int) {
    guard _storage.freeCapacity < minimumCapacity else { return }
    reserveCapacity(max(count + minimumCapacity, Self._grow(capacity)))
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public mutating func append(_ item: consuming Element) {
    _ensureFreeCapacity(1)
    _storage.append(item)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    _ensureFreeCapacity(1)
    _storage.insert(item, at: index)
  }
}

extension DynamicArray {
  @inlinable
  public mutating func append(contentsOf items: some Sequence<Element>) {
    for item in items {
      append(item)
    }
  }
}
