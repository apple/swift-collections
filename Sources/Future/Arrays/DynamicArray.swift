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
  @available(SwiftCompatibilitySpan 5.0, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    get {
      _storage.span
    }
  }
  
  @available(SwiftCompatibilitySpan 5.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
}

//MARK: RandomAccessContainer conformance

@available(SwiftCompatibilitySpan 5.0, *)
extension DynamicArray: RandomAccessContainer where Element: ~Copyable {
  @lifetime(borrow self)
  public func nextSpan(after index: inout Int, maximumCount: Int) -> Span<Element> {
    _storage.nextSpan(after: &index, maximumCount: maximumCount)
  }
}

extension DynamicArray where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { _storage.isEmpty }

  @inlinable
  public var count: Int { _storage.count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _storage.count }

  @inlinable
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.borrowElement(at: index)
  }
}

// MARK: - MutableContainer conformance

extension DynamicArray: MutableContainer where Element: ~Copyable {
  @inlinable
  @lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    _storage.mutateElement(at: index)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maximumCount: Int
  ) -> MutableSpan<Element> {
    _storage.nextMutableSpan(after: &index, maximumCount: maximumCount)
  }
}

// MARK: - Range replacement operations

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

  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    _ensureFreeCapacity(1)
    _storage.insert(item, at: index)
  }

  @inlinable
  public mutating func append(contentsOf items: some Sequence<Element>) {
    for item in items {
      append(item)
    }
  }
}
