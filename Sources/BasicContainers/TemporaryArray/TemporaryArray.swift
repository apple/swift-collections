//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.3)

/// A dynamically self-resizing, noncopyable array of potentially noncopyable
/// elements whose initial storage is *borrowed* from the caller, but that
/// transparently spills over into freshly allocated heap storage once it grows
/// beyond the capacity of that initial buffer.
///
/// `TemporaryArray` is designed to be seeded with a small buffer, most usefully
/// a *stack* allocation vended by
/// ``withTemporaryArray(of:capacity:_:)``. As long as the number
/// of elements stays within the reserved capacity, the array operates entirely
/// out of that borrowed buffer, incurring no heap traffic at all. The moment an
/// insertion would exceed the borrowed capacity, the array allocates a heap
/// buffer (using the same geometric growth curve as ``UniqueArray``), moves its
/// existing elements over, and from then on behaves like an ordinary
/// dynamically-resizing array that owns its storage.
///
/// This makes `TemporaryArray` a good fit for algorithms that need scratch
/// storage of an unknown final size where small cases dominate, such as
/// collecting the results of mapping/filtering an arbitrary sequence: a good
/// lower-bound guess (e.g. `underestimatedCount`) can be reserved on the stack,
/// and only the unexpectedly large cases pay for a heap allocation.
///
/// Because it can hold a dependency on borrowed (stack) memory, `TemporaryArray`
/// is a non-escapable type: instances cannot outlive the scope that provides
/// their initial buffer. This is enforced by the compiler. To extract the
/// contents past that scope, move them into an owning container such as
/// ``UniqueArray`` (see ``take()``).
@available(SwiftStdlib 5.0, *)
@safe
@frozen
public struct TemporaryArray<Element: ~Copyable>: ~Copyable, ~Escapable {
  /// The currently active storage buffer. This is either the borrowed buffer
  /// the array was seeded with (when `_ownsStorage` is false), or a heap buffer
  /// this array allocated and is responsible for freeing (when `_ownsStorage`
  /// is true).
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  /// The number of initialized elements at the start of `_storage`.
  @usableFromInline
  internal var _count: Int

  /// Whether this array owns (and must therefore deallocate) `_storage`.
  ///
  /// This starts out false when the array is seeded with a borrowed buffer, and
  /// flips to true the first time the array spills its contents into a heap
  /// allocation. Once true, it stays true.
  @usableFromInline
  internal var _ownsStorage: Bool

  @_alwaysEmitIntoClient
  deinit {
    unsafe _storage.extracting(0 ..< _count).deinitialize()
    if _ownsStorage {
      unsafe _storage.deallocate()
    }
  }

  /// Creates an array that borrows the given buffer as its initial storage.
  ///
  /// The buffer's memory must remain valid throughout the lifetime of the
  /// resulting array; this is what makes `TemporaryArray` non-escapable. The
  /// buffer is assumed to be entirely uninitialized; the new array starts
  /// empty.
  ///
  /// This is currently internal: `TemporaryArray` is only vended through
  /// ``withTemporaryArray(of:capacity:_:)``. It can be exposed as public API
  /// later if a use case for a caller-provided seed buffer arises.
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  internal init(borrow buffer: UnsafeMutableBufferPointer<Element>) {
    unsafe _storage = buffer
    _count = 0
    _ownsStorage = false
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray: @unchecked Sendable
where Element: Sendable & ~Copyable {}

//MARK: - Heap-only construction

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Creates an empty array that owns a freshly allocated heap buffer with the
  /// given capacity.
  ///
  /// Unlike instances seeded through
  /// ``withTemporaryArray(of:capacity:_:)``, an array created this
  /// way never borrows any external memory, so it carries an immortal lifetime
  /// and may escape freely. This initializer exists primarily so that
  /// `TemporaryArray` can satisfy the requirements of dynamic container
  /// protocols; for purely heap-backed storage, prefer ``UniqueArray``.
  @_alwaysEmitIntoClient
  @_lifetime(immortal)
  public init(capacity: Int) {
    precondition(capacity >= 0, "Array capacity must be nonnegative")
    if capacity > 0 {
      unsafe _storage = .allocate(capacity: capacity)
    } else {
      unsafe _storage = .init(start: nil, count: 0)
    }
    _count = 0
    _ownsStorage = true
  }

  /// Creates an empty array that owns no storage.
  @_alwaysEmitIntoClient
  @_lifetime(immortal)
  public init() {
    self.init(capacity: 0)
  }
}

//MARK: - Heap-only construction with an initializer

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Creates a new heap-backed array with the specified capacity, directly
  /// initializing its storage using an output span.
  ///
  /// Like ``init(capacity:)``, an array created this way never borrows any
  /// external memory, so it carries an immortal lifetime and may escape freely.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new array.
  ///   - initializer: A callback that gets called at most once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is allowed to add fewer than `capacity` items. The array is
  ///       initialized with however many items the callback adds to the
  ///       output span before it returns (or before it throws an error).
  @_alwaysEmitIntoClient
  @_lifetime(immortal)
  public init<E: Error>(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(capacity: capacity)
    try edit(initializer)
  }
}

//MARK: - Basics

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// The number of elements the array can currently hold without reallocating
  /// (or spilling to the heap).
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var capacity: Int { _assumeNonNegative(unsafe _storage.count) }

  /// The number of additional elements that can be added without reallocating.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var freeCapacity: Int { _assumeNonNegative(capacity &- _count) }

  /// Returns a Boolean value indicating whether two arrays are backed by the
  /// same storage, at the same count.
  ///
  /// This is a lightweight identity check; it does not compare elements. Two
  /// arrays with equal contents in distinct storage are *not* trivially
  /// identical.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    unsafe _storage.baseAddress == other._storage.baseAddress
    && _count == other._count
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal var _items: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (0, _count)))
  }

  @_alwaysEmitIntoClient
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (_count, capacity)))
  }
}

//MARK: - Span creation

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// A span over the elements of this array, providing direct read-only access.
  ///
  /// - Complexity: O(1)
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @_alwaysEmitIntoClient
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }

  /// A mutable span over the elements of this array, providing direct mutating
  /// access.
  ///
  /// - Complexity: O(1)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @_alwaysEmitIntoClient
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span.extracting(range)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

//MARK: - Editing

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Arbitrarily edit the array's current storage by invoking a user-supplied
  /// closure with a mutable `OutputSpan` view over it.
  ///
  /// The closure may add, remove or reorder items; it must not change the
  /// span's capacity. (This operation does not resize the array's storage; to
  /// guarantee free capacity beforehand, call ``reserveCapacity(_:)``.)
  ///
  /// - Complexity: Adds O(1) overhead to the complexity of the closure.
  @_alwaysEmitIntoClient
  public mutating func edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    var span = unsafe OutputSpan(buffer: _storage, initializedCount: _count)
    defer {
      _count = span.finalize(for: _storage)
      span = OutputSpan()
    }
    return try body(&span)
  }
}

//MARK: - Resizing & spilling

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Replace the array's storage buffer with a freshly allocated heap buffer of
  /// the given capacity, moving all existing elements over.
  ///
  /// If the array was still using its borrowed (stack) seed buffer, this is the
  /// point at which it "spills" to the heap: the borrowed buffer is left
  /// untouched (the caller still owns it) and the array takes ownership of the
  /// new heap buffer. Otherwise, the old heap buffer is deallocated as usual.
  ///
  /// - Parameter newCapacity: The desired new capacity. Must be `>= count`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func reallocate(capacity newCapacity: Int) {
    precondition(newCapacity >= _count, "TemporaryArray capacity overflow")
    guard newCapacity != capacity || !_ownsStorage else { return }
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(
      capacity: newCapacity)
    let i = unsafe newStorage.moveInitialize(fromContentsOf: _items)
    assert(i == _count)
    // Only free the old buffer if we owned it. A borrowed seed buffer is left
    // for its owner (e.g. `withTemporaryArray`) to clean up.
    if _ownsStorage {
      unsafe _storage.deallocate()
    }
    unsafe _storage = newStorage
    _ownsStorage = true
  }

  /// Ensure that the array can hold at least `n` elements without reallocating,
  /// growing (and, if necessary, spilling to the heap) if it cannot.
  ///
  /// - Complexity: O(`count`) if a reallocation is triggered, O(1) otherwise.
  @_alwaysEmitIntoClient
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    reallocate(capacity: n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _grow(freeCapacity: Int) -> Int {
    Swift.max(_count &+ freeCapacity, _growUniqueArrayCapacity(capacity))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    guard self.freeCapacity < freeCapacity else { return }
    reallocate(capacity: _grow(freeCapacity: freeCapacity))
  }
}

//MARK: - Moving out

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Move the contents of this array into a newly created ``UniqueArray``,
  /// leaving this array empty.
  ///
  /// Use this to hand the accumulated elements back out of the scope that owns
  /// the array's seed buffer: the result is an ordinary heap-backed,
  /// escapable container. If the array had already spilled to the heap, its
  /// existing storage is transferred without copying; otherwise the elements
  /// are moved out of the borrowed buffer into a fresh allocation.
  ///
  /// - Complexity: O(1) if the array has already spilled to the heap;
  ///    O(`count`) otherwise.
  @_alwaysEmitIntoClient
  public mutating func take() -> UniqueArray<Element> {
    if _ownsStorage {
      // Transfer ownership of the heap buffer directly.
      let storage = unsafe RigidArray<Element>(
        _storage: _storage, count: _count)
      unsafe _storage = .init(start: nil, count: 0)
      _count = 0
      _ownsStorage = true
      return UniqueArray(_storage: storage)
    }
    // Still borrowing: move elements into a fresh heap allocation.
    var result = UniqueArray<Element>(minimumCapacity: _count)
    result._storage.append(moving: _items)
    _count = 0
    return result
  }
}

//MARK: - Copying

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*where Element: Copyable*/ {
  /// Copies the contents of this array into a newly allocated, heap-backed array
  /// with just enough capacity to hold all its elements.
  ///
  /// The result owns its storage and carries an immortal lifetime (it does not
  /// borrow this array's storage), so it can escape freely. Combine with
  /// ``take()`` to lift the contents into an owning ``UniqueArray``.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @_lifetime(immortal)
  public func clone() -> Self {
    clone(capacity: count)
  }

  /// Copies the contents of this array into a newly allocated, heap-backed array
  /// with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the result. Must be `>=
  ///    count`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @_lifetime(immortal)
  public func clone(capacity: Int) -> Self {
    precondition(capacity >= count, "TemporaryArray capacity overflow")
    var result = TemporaryArray(capacity: capacity)
    result.append(copying: span)
    return result
  }
}

//MARK: - Scoped construction over a stack allocation

/// The maximum size, in bytes, of the initial buffer that
/// ``withTemporaryArray(of:capacity:_:)`` will place on the stack.
///
/// This mirrors the threshold `withUnsafeTemporaryAllocation` uses internally:
/// requests at or below this size are served from the stack, larger requests
/// are heap allocated. We hardcode it so that an oversized initial capacity
/// skips the stack path entirely rather than relying on the standard library
/// to silently fall back to the heap. That allows `take()` to take ownership
/// off the heap allocation instead of allocating and moving the elements over.
@_alwaysEmitIntoClient
@_transparent
internal var _temporaryArrayStackByteLimit: Int { 1024 }

/// Provides a dynamically-resizing array that is initially backed by a stack
/// allocation of the requested capacity, spilling over to the heap only if it
/// grows beyond it.
///
/// This is the primary way to create a ``TemporaryArray``. The array passed to
/// `body` starts empty with room for `capacity` elements. As long as the
/// array's element count stays at or below that capacity, no heap allocation
/// occurs, provided the requested storage fits within the stack budget.
///
/// To keep latency predictable, the initial buffer is placed on the stack only
/// if it occupies at most `_temporaryArrayStackByteLimit` (1024) bytes; a larger
/// initial `capacity` is heap allocated up front instead. Either way the array
/// grows on the heap once it exceeds its initial capacity.
///
/// The array cannot escape `body` (it is non-escapable). To keep its contents,
/// move them into an owning container with ``TemporaryArray/take()``:
///
///     let evens: UniqueArray<Int> = withTemporaryArray(
///       of: Int.self, capacity: source.underestimatedCount
///     ) { scratch in
///       for x in source where x.isMultiple(of: 2) { scratch.append(x) }
///       return scratch.take()
///     }
///
/// - Parameters:
///   - type: The element type of the array.
///   - capacity: The number of elements to reserve up front.
///   - body: A closure that receives the freshly created, empty array.
/// - Returns: The result of `body`.
@available(SwiftStdlib 5.0, *)
@_alwaysEmitIntoClient @_transparent
public func withTemporaryArray<Element: ~Copyable, E: Error, R: ~Copyable>(
  of type: Element.Type,
  capacity: Int,
  _ body: (inout TemporaryArray<Element>) throws(E) -> R
) throws(E) -> R {
  precondition(capacity >= 0, "Array capacity must be nonnegative")
  let byteCount = capacity * MemoryLayout<Element>.stride
  if byteCount <= _temporaryArrayStackByteLimit {
    // Small enough: carve the initial buffer out of the stack.
    return try _withUnsafeTemporaryAllocation(
      of: Element.self, capacity: capacity
    ) { buffer throws(E) in
      var array = unsafe TemporaryArray(borrow: buffer)
      // `array` is destroyed (running its deinit) when this closure returns,
      // before `_withUnsafeTemporaryAllocation` reclaims `buffer`.
      return try body(&array)
    }
  }
  // Too large for the stack budget: allocate the initial buffer on the heap.
  var array = TemporaryArray<Element>(capacity: capacity)
  return try body(&array)
}

#endif
