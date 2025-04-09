//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

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
  @available(SwiftStdlib 6.2, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    get {
      _storage.span
    }
  }
  
#if compiler(>=6.3) // FIXME: Turn this on once we have a new enough toolchain
  @available(SwiftStdlib 6.2, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
#endif
}

extension DynamicArray where Element: ~Copyable {
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
    unsafeAddress {
      unsafe _storage._unsafeAddressOfElement(at: position)
    }
    @inline(__always)
    unsafeMutableAddress {
      unsafe _storage._unsafeMutableAddressOfElement(at: position)
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
  public func distance(from start: Int, to end: Int) -> Int {
    // Note: Range checks are deferred until element access.
    end - start
  }

  @inlinable
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    // Note: Range checks are deferred until element access.
    index + n
  }
}

#if false
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
  public func index(at position: borrowing BorrowingIterator) -> Int {
    // Note: Range checks are deferred until element access.
    position._offset
  }
  
  @inlinable
  public func formIndex(
    _ index: inout Int, offsetBy distance: inout Int, limitedBy limit: Int
  ) {
    _storage.formIndex(&index, offsetBy: &distance, limitedBy: limit)
  }
}
#endif

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
