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
public struct DynoDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: HypoDeque<Element>

  @inlinable
  public init() {
    _storage = .init(capacity: 0)
  }

  @inlinable
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }
}

extension DynoDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension DynoDeque: RandomAccessContainer where Element: ~Copyable {
  public typealias BorrowingIterator = HypoDeque<Element>.BorrowingIterator
  public typealias Index = Int

  public func startBorrowingIteration() -> BorrowingIterator {
    _storage.startBorrowingIteration()
  }

  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    _storage.startBorrowingIteration(from: start)
  }

  @inlinable
  public var isEmpty: Bool { _storage.isEmpty }

  @inlinable
  public var count: Int { _storage.count }

  @inlinable
  public var startIndex: Int { _storage.startIndex }

  @inlinable
  public var endIndex: Int { _storage.endIndex }

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

  public func index(at position: borrowing BorrowingIterator) -> Int {
    _storage.index(at: position)
  }
}

extension DynoDeque where Element: ~Copyable {
  @inlinable
  internal var _capacity: Int { _storage.capacity }

  @inlinable
  internal var _freeCapacity: Int { _storage.freeCapacity }

  @inlinable
  internal var _isFull: Bool { _storage.isFull }

  @inlinable
  internal mutating func _grow(to minimumCapacity: Int) {
    guard minimumCapacity > _capacity else { return }
    let c = Swift.max(minimumCapacity, 2 * _capacity)
    _storage.resize(to: c)
  }

  @inlinable
  internal mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    _grow(to: count + freeCapacity)
  }
}

extension DynoDeque where Element: ~Copyable {
  @inlinable
  public mutating func append(_ newElement: consuming Element) {
    _ensureFreeCapacity(1)
    _storage.append(newElement)
  }

  @inlinable
  public mutating func prepend(_ newElement: consuming Element) {
    _ensureFreeCapacity(1)
    _storage.prepend(newElement)
  }

  @inlinable
  public mutating func insert(_ newElement: consuming Element, at index: Int) {
    _ensureFreeCapacity(1)
    _storage.insert(newElement, at: index)
  }
}

extension DynoDeque where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }

  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }

  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    _storage.removeFirst()
  }

  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    _storage.removeLast()
  }

  @inlinable
  public mutating func removeFirst(_ n: Int) {
    _storage.removeFirst(n)
  }

  @inlinable
  public mutating func removeLast(_ n: Int) {
    _storage.removeLast(n)
  }

  @inlinable
  public mutating func removeAll() {
    _storage.removeAll()
  }

  @inlinable
  public mutating func popFirst() -> Element? {
    _storage.popFirst()
  }

  @inlinable
  public mutating func popLast() -> Element? {
    _storage.popLast()
  }
}
