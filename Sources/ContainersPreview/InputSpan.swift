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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif
import Builtin

@available(SwiftStdlib 5.0, *)
@safe
@frozen
public struct InputSpan<Element: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  internal let _pointer: UnsafeMutableRawPointer?

  public let capacity: Int

  @usableFromInline
  internal var _count: Int

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    if _count > 0 {
      let c = _count
      unsafe _first().withMemoryRebound(to: Element.self, capacity: _count) {
        _ = unsafe $0.deinitialize(count: c)
      }
    }
  }

  @_lifetime(immortal)
  public init() {
    _pointer = nil
    capacity = 0
    _count = 0
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal func _start() -> UnsafeMutableRawPointer {
    unsafe _pointer.unsafelyUnwrapped
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal func _first() -> UnsafeMutableRawPointer {
    // NOTE: `_pointer` must be known to be not-nil.
    unsafe _start().advanced(by: _count &* MemoryLayout<Element>.stride)
  }
  
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  internal func _unsafeRawAddressOfSlot(
    uncheckedOffset offset: Int
  ) -> UnsafeMutableRawPointer {
    let offset = (capacity &- _count &+ offset) &* MemoryLayout<Element>.stride
    return unsafe _start().advanced(by: offset)
  }

  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  internal func _unsafeAddressOfElement(
    unchecked index: Index
  ) -> UnsafeMutablePointer<Element> {
    _unsafeRawAddressOfSlot(
      uncheckedOffset: index
    ).assumingMemoryBound(to: Element.self)
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// Consume the input span and return the number of initialized elements
  /// remaining at the end of the underlying memory region.
  ///
  /// This method should be invoked in the scope where the `InputSpan` was
  /// created, when it is time to commit the contents of the updated buffer
  /// back into the construct that was accessed.
  ///
  /// The context that created the input span is expected to remember what
  /// memory region the span is addressing. This consuming method expects to
  /// receive a copy of the same buffer pointer as a (loose) proof of ownership.
  ///
  /// - Parameter buffer: The buffer we expect the `InputSpan` to reference.
  ///      This must be the same region of memory passed to
  ///      the `InputSpan` initializer.
  /// - Returns: The number of initialized elements remaining at the end of the
  ///      underlying buffer.
  @unsafe
  @_alwaysEmitIntoClient
  public consuming func finalize(
    for buffer: UnsafeMutableBufferPointer<Element>
  ) -> Int {
    precondition(
      unsafe UnsafeMutableRawPointer(buffer.baseAddress) == self._pointer
      && buffer.count == self.capacity,
      "InputSpan identity mismatch")
    let count = self._count
    discard self
    return count
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan {
  /// Consume the input span and return the number of initialized elements
  /// remaining at the end of the underlying memory region.
  ///
  /// This method should be invoked in the scope where the `InputSpan` was
  /// created, when it is time to commit the contents of the updated buffer
  /// back into the construct that was accessed.
  ///
  /// The context that created the input span is expected to remember what
  /// memory region the span is addressing. This consuming method expects to
  /// receive a copy of the same buffer pointer as a (loose) proof of ownership.
  ///
  /// - Parameter buffer: The buffer we expect the `InputSpan` to reference.
  ///      This must be the same region of memory passed to
  ///      the `InputSpan` initializer.
  /// - Returns: The number of initialized elements remaining at the end of the
  ///      underlying buffer.
  @unsafe
  @_alwaysEmitIntoClient
  public consuming func finalize(
    for buffer: Slice<UnsafeMutableBufferPointer<Element>>
  ) -> Int {
    unsafe finalize(for: UnsafeMutableBufferPointer(rebasing: buffer))
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// The number of initialized elements in this span.
  @_alwaysEmitIntoClient
  public var count: Int { _count }

  /// The number of additional elements that can be added to this span.
  @_alwaysEmitIntoClient
  public var freeCapacity: Int { capacity &- _count }

  /// A Boolean value indicating whether the span is empty.
  @_alwaysEmitIntoClient
  public var isEmpty: Bool { _count == 0 }

  /// A Boolean value indicating whether the span is full.
  @_alwaysEmitIntoClient
  public var isFull: Bool { _count == capacity }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  public init(
    _uncheckedBuffer buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int
  ) {
    unsafe _pointer = .init(buffer.baseAddress)
    capacity = buffer.count
    _count = initializedCount
  }
  
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  public init(
    buffer: UnsafeMutableBufferPointer<Element>, initializedCount: Int
  ) {
    precondition(buffer._isWellAligned(), "Misaligned OutputSpan")
    if let baseAddress = buffer.baseAddress {
      precondition(
        unsafe baseAddress.advanced(by: buffer.count) >= baseAddress,
        "Buffer must not wrap around the address space")
    }
    precondition(
      0 <= initializedCount && initializedCount <= buffer.count,
      "OutputSpan count is not within capacity")
    unsafe self.init(
      _uncheckedBuffer: buffer, initializedCount: initializedCount)
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan {
  /// Unsafely create an input span over partially initialized memory.
  ///
  /// The memory in `buffer` must remain valid throughout the lifetime
  /// of the newly-created `InputSpan`. There must be exactly
  /// `initializedCount` initialized instances at the end of the buffer,
  /// preceded by uninitialized memory.
  ///
  /// - Parameters:
  ///   - buffer: an `UnsafeMutableBufferPointer` with some number of
  ///      initialized elements, all compacted into the end of the buffer
  ///   - initializedCount: the number of initialized elements
  ///      at the end of `buffer`.
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  public init(
    buffer: borrowing Slice<UnsafeMutableBufferPointer<Element>>,
    initializedCount: Int
  ) {
    let rebased = unsafe UnsafeMutableBufferPointer(rebasing: buffer)
    let os = unsafe InputSpan(
      buffer: rebased, initializedCount: initializedCount)
    self = unsafe _overrideLifetime(os, borrowing: buffer)
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// The type that represents an initialized position in an `InputSpan`.
  public typealias Index = Int

  /// The range of initialized positions for this `InputSpan`.
  @_alwaysEmitIntoClient
  public var indices: Range<Index> {
    unsafe Range(uncheckedBounds: (0, _count))
  }

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: A valid index into this span.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public subscript(_ index: Index) -> Element {
    unsafeAddress {
      precondition(indices.contains(index), "Index out of bounds")
      return unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }

    @_lifetime(self: copy self)
    unsafeMutableAddress {
      precondition(indices.contains(index), "Index out of bounds")
      return unsafe _unsafeAddressOfElement(unchecked: index)
    }
  }

  /// Accesses the element at the specified position.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter index: A valid index into this span.
  ///
  /// - Complexity: O(1)
  @unsafe
  @_alwaysEmitIntoClient
  public subscript(unchecked index: Index) -> Element {
    unsafeAddress {
      unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }
    @_lifetime(self: copy self)
    unsafeMutableAddress {
      unsafe _unsafeAddressOfElement(unchecked: index)
    }
  }

  /// Exchange the elements at the two given offsets
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func swapAt(_ i: Index, _ j: Index) {
    precondition(indices.contains(Index(i)))
    precondition(indices.contains(Index(j)))
    unsafe swapAt(unchecked: i, unchecked: j)
  }

  /// Exchange the elements at the two given offsets
  ///
  /// This subscript does not validate `i` or `j`; this is an unsafe operation.
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func swapAt(unchecked i: Index, unchecked j: Index) {
    guard i != j else { return }
    let pi = unsafe _unsafeAddressOfElement(unchecked: i)
    let pj = unsafe _unsafeAddressOfElement(unchecked: j)
    let temporary = unsafe pi.move()
    unsafe pi.initialize(to: pj.move())
    unsafe pj.initialize(to: consume temporary)
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// Prepend a single element to this span.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func prepend(_ value: consuming Element) {
    precondition(_count < capacity, "InputSpan capacity overflow")
    unsafe _unsafeRawAddressOfSlot(
      uncheckedOffset: -1
    ).initializeMemory(as: Element.self, to: value)
    _count &+= 1
  }

  /// Remove the last initialized element from this span.
  ///
  /// Returns the last element. The `InputSpan` must not be empty.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "InputSpan underflow")
    defer { _count &-= 1 }
    return _unsafeAddressOfElement(unchecked: 0).move()
  }

  /// Remove the last N elements of this span, returning the memory they occupy
  /// to the uninitialized state.
  ///
  /// `n` must not be greater than `count`
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeFirst(_ k: Int) {
    precondition(k >= 0, "Can't remove a negative number of elements")
    precondition(k <= _count, "InputSpan underflow")
    unsafe _unsafeRawAddressOfSlot(
      uncheckedOffset: 0
    ).withMemoryRebound(to: Element.self, capacity: k) {
      _ = unsafe $0.deinitialize(count: k)
    }
    _count &-= k
  }

  /// Remove all this span's elements and return its memory
  /// to the uninitialized state.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeAll() {
    _ = unsafe _start().withMemoryRebound(to: Element.self, capacity: _count) {
      unsafe $0.deinitialize(count: _count)
    }
    _count = 0
  }
}

//MARK: Bulk append functions

@available(SwiftStdlib 5.0, *)
extension InputSpan {
  /// Repeatedly append an element to this span.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func prepend(repeating repeatedValue: Element, count: Int) {
    precondition(count <= freeCapacity, "InputSpan capacity overflow")
    unsafe _unsafeRawAddressOfSlot(
      uncheckedOffset: -count
    ).initializeMemory(as: Element.self, repeating: repeatedValue, count: count)
    _count &+= count
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// Borrow the underlying initialized memory for read-only access.
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public var span: Span<Element> {
    @_lifetime(borrow self)
    borrowing get {
      let pointer = unsafe _pointer?
        .assumingMemoryBound(to: Element.self)
        .advanced(by: capacity &- _count)
      let buffer = unsafe UnsafeBufferPointer(start: pointer, count: _count)
      let span = unsafe Span(_unsafeElements: buffer)
      return unsafe _overrideLifetime(span, borrowing: self)
    }
  }

  /// Exclusively borrow the underlying initialized memory for mutation.
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    mutating get {
      let pointer = unsafe _pointer?
        .assumingMemoryBound(to: Element.self)
        .advanced(by: capacity &- _count)
      let buffer = unsafe UnsafeMutableBufferPointer(
        start: pointer, count: _count)
      let span = unsafe MutableSpan(_unsafeElements: buffer)
      return unsafe _overrideLifetime(span, borrowing: self)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan where Element: ~Copyable {
  /// Call the given closure with the unsafe buffer pointer addressed by this
  /// InputSpan and a mutable reference to its count of initialized elements.
  ///
  /// This method provides a way to process or consume the contents of an
  /// `InputSpan` using unsafe operations, such as by dispatching to code
  /// written in legacy (memory-unsafe) languages.
  ///
  /// The supplied closure may process the buffer in any way it wants; however,
  /// when it finishes (whether by returning or throwing), it must leave the
  /// buffer in a state that satisfies the invariants of the input span:
  ///
  /// 1. The inout integer passed in as the second argument must be the exact
  ///     number of initialized items in the buffer passed in as the first
  ///     argument.
  /// 2. These initialized elements must be located in a single contiguous
  ///     region located at the end of the buffer. The initialized region must
  ///     be preceded by uninitialized memory.
  ///
  /// This function cannot verify these two invariants, and therefore
  /// this is an unsafe operation. Violating the invariants of `InputSpan`
  /// may result in undefined behavior.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (
      UnsafeMutableBufferPointer<Element>,
      _ initializedCount: inout Int
    ) throws(E) -> R
  ) throws(E) -> R {
    guard let start = unsafe _pointer, capacity > 0 else {
      let buffer = UnsafeMutableBufferPointer<Element>(_empty: ())
      var initializedCount = 0
      defer {
        precondition(initializedCount == 0, "InputSpan capacity overflow")
      }
      return unsafe try body(buffer, &initializedCount)
    }
    // bind memory by hand to sidestep alignment concerns
    let binding = Builtin.bindMemory(
      start._rawValue, capacity._builtinWordValue, Element.self
    )
    defer { Builtin.rebindMemory(start._rawValue, binding) }
    let buffer = unsafe UnsafeMutableBufferPointer<Element>(
      /*_uncheckedStart*/start: .init(start._rawValue), count: capacity
    )
    var initializedCount = self._count
    defer {
      precondition(
        0 <= initializedCount && initializedCount <= capacity,
        "InputSpan capacity overflow"
      )
      self._count = initializedCount
    }
    return unsafe try body(buffer, &initializedCount)
  }
}

#endif
