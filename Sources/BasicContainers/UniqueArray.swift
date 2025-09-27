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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(<6.2)

/// A dynamically self-resizing, heap allocated, noncopyable array
/// of potentially noncopyable elements.
@frozen
@available(*, unavailable, message: "UniqueArray requires a Swift 6.2 toolchain")
public struct UniqueArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidArray<Element>

  @inlinable
  public init() {
    fatalError()
  }
}

#else

/// A dynamically self-resizing, heap allocated, noncopyable array of
/// potentially noncopyable elements.
///
/// `UniqueArray` instances automatically resize their underlying storage as
/// needed to accommodate newly inserted items, using a geometric growth curve.
/// This frees code using `UniqueArray` from having to allocate enough
/// capacity in advance; on the other hand, it makes it difficult to tell
/// when and where such reallocations may happen.
///
/// For example, appending an element to a dynamic array has highly variable
/// complexity; often, it runs at a constant cost, but if the operation has to
/// resize storage, then the cost of an individual append suddenly becomes
/// proportional to the size of the whole array.
///
/// The geometric growth curve allows the cost of such latency spikes to
/// get amortized across repeated invocations, bringing the average cost back
/// to O(1); but they make this construct less suitable for use cases that
/// expect predictable, consistent performance on every operation.
///
/// Implicit growth also makes it more difficult to predict/analyze the amount
/// of memory an algorithm would need. Developers targeting environments with
/// stringent limits on heap allocations may prefer to avoid using dynamically
/// resizing array types as a matter of policy. The type `RigidArray` provides
/// a fixed-capacity array variant that caters specifically for these use cases,
/// trading ease-of-use for more consistent/predictable execution.
@available(SpanAvailability 1.0, *)
@frozen
public struct UniqueArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidArray<Element>

  @inlinable
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }

  @inlinable
  public init() {
    _storage = .init(capacity: 0)
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray: Sendable where Element: Sendable & ~Copyable {}

//MARK: - Basics

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var capacity: Int { _assumeNonNegative(_storage.capacity) }

  @inlinable
  @inline(__always)
  public var freeCapacity: Int {
    _assumeNonNegative(_storage.capacity &- _storage.count)
  }
}

//MARK: - Span creation

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @inlinable
    get {
      _storage.span
    }
  }

  @available(SpanAvailability 1.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Arbitrarily edit the storage underlying this array by invoking a
  /// user-supplied closure with a mutable `OutputSpan` view over it.
  /// This method calls its function argument precisely once, allowing it to
  /// arbitrarily modify the contents of the output span it is given.
  /// The argument is free to add, remove or reorder any items; however,
  /// it is not allowed to replace the span or change its capacity.
  ///
  /// When the function argument finishes (whether by returning or throwing an
  /// error) the rigid array instance is updated to match the final contents of
  /// the output span.
  ///
  /// - Parameter body: A function that edits the contents of this array through
  ///    an `OutputSpan` argument. This method invokes this function
  ///    precisely once.
  /// - Returns: This method returns the result of its function argument.
  /// - Complexity: Adds O(1) overhead to the complexity of the function
  ///    argument.
  @inlinable @inline(__always)
  public mutating func edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    try _storage.edit(body)
  }
}

//MARK: - Container primitives

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _storage.isEmpty }

  @inlinable
  @inline(__always)
  public var count: Int { _storage.count }
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SpanAvailability 1.0, *)
extension UniqueArray: Container where Element: ~Copyable {
  public typealias BorrowIterator = RigidArray<Element>.BorrowIterator
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public func startBorrowIteration() -> Span<Element> {
    self._storage.startBorrowIteration()
  }
}
#endif

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  @inline(__always)
  public var startIndex: Int { _storage.startIndex }

  @inlinable
  @inline(__always)
  public var endIndex: Int { _storage.count }

  @inlinable
  @inline(__always)
  public var indices: Range<Int> { _storage.indices }

  @inlinable
  public subscript(position: Int) -> Element {
    unsafeAddress {
      _storage._ptr(to: position)
    }
    unsafeMutableAddress {
      _storage._mutablePtr(to: position)
    }
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _storage.swapAt(i, j)
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  @_lifetime(borrow self)
  public func span(after index: inout Int) -> Span<Element> {
    _storage.span(after: &index)
  }

  @inlinable
  @_lifetime(borrow self)
  public func span(before index: inout Int) -> Span<Element> {
    _storage.span(before: &index)
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @_lifetime(&self)
  public mutating func mutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _storage.mutableSpan(after: &index)
  }

  @_lifetime(&self)
  public mutating func mutableSpan(
    before index: inout Int
  ) -> MutableSpan<Element> {
    _storage.mutableSpan(before: &index)
  }
}

//MARK: - Resizing

@_alwaysEmitIntoClient
@_transparent
internal func _growDynamicArrayCapacity(_ capacity: Int) -> Int {
  // A growth factor of 1.5 seems like a reasonable compromise between
  // over-allocating memory and wasting cycles on repeatedly resizing storage.
  let c = (3 &* UInt(bitPattern: capacity) &+ 1) / 2
  return Int(bitPattern: c)
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable @inline(never)
  public mutating func reallocate(capacity: Int) {
    _storage.reallocate(capacity: capacity)
  }

  @inlinable @inline(never)
  public mutating func reserveCapacity(_ n: Int) {
    _storage.reserveCapacity(n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    guard _storage.freeCapacity < freeCapacity else { return }
    _ensureFreeCapacitySlow(freeCapacity)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _grow(freeCapacity: Int) -> Int {
    Swift.max(
      count + freeCapacity,
      _growDynamicArrayCapacity(capacity))
  }

  @inlinable
  internal mutating func _ensureFreeCapacitySlow(_ freeCapacity: Int) {
    let newCapacity = _grow(freeCapacity: freeCapacity)
    reallocate(capacity: newCapacity)
  }
}

#endif
