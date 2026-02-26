//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

import Swift
import BasicContainers

@safe
@frozen
public struct InputMultispan<Element: ~Copyable>: ~Copyable, ~Escapable {
  internal struct _Buffer {
    var ptr: UnsafeMutableRawBufferPointer
    var count: Int
  }
  
  @usableFromInline
  internal var _pointers: UniqueArray<_Buffer> //TODO: optimize

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    for idx in 0 ..< _pointers.count {
      let count = _pointers[idx].count
      unsafe _pointers[idx].ptr.withMemoryRebound(to: Element.self) {
        _ = unsafe UnsafeMutableBufferPointer(start: $0.baseAddress!, count: count).deinitialize()
      }
    }
  }

  /// Create an OutputSpan with zero capacity
  @_alwaysEmitIntoClient
  @lifetime(immortal)
  public init() {
    _pointers = UniqueArray()
  }
}

extension InputMultispan: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension InputMultispan where Element: ~Copyable {
  
  internal func _firstNonEmptySpanIndex() -> Int? {
    for idx in 0 ..< _pointers.count {
      if _pointers[idx].count > 0 {
        return idx
      }
    }
    return nil
  }
  
  @unsafe
  @_alwaysEmitIntoClient
  internal func _unsafeAddressOfElement(
    unchecked index: Index
  ) -> UnsafeMutablePointer<Element> {
    let address = unsafe _pointers[ index.bufferIndex].ptr.baseAddress.unsafelyUnwrapped.advanced(by: index.elementIndex)
    return unsafe address.assumingMemoryBound(to: Element.self)
  }
}

extension InputMultispan where Element: ~Copyable {
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
    //TODO: clearly something needs to happen here but it's not obvious how to structure it
    return totalCount
  }
}

extension InputMultispan where Element: ~Copyable {
  
  @_alwaysEmitIntoClient
  public var spanCount: Int {
    _assumeNonNegative(_pointers.count)
  }
  
  /// The number of initialized elements in this span.
  @_alwaysEmitIntoClient
  public func count(at index: Int) -> Int {
    _assumeNonNegative(_pointers[index].count)
  }
  
  public var totalCount: Int {
    var total = 0
    for idx in 0 ..< spanCount {
      total += count(at: idx)
    }
    return total
  }

  @_alwaysEmitIntoClient
  public func freeCapacity(at index: Int) -> Int {
    _assumeNonNegative(_pointers[index].ptr.count &- _pointers[index].count)
  }
  
  /// The number of additional elements that can be added to this span.
  @_alwaysEmitIntoClient
  public var totalFreeCapacity: Int {
    var total = 0
    for idx in 0 ..< spanCount {
      total += count(at: idx)
    }
    return total
  }

  /// A Boolean value indicating whether the span is empty.
  @_alwaysEmitIntoClient
  @_transparent
  public var isEmpty: Bool {
    guard spanCount > 0 else { return true }
    return totalCount == 0
  }

  /// A Boolean value indicating whether the span is full.
  @_alwaysEmitIntoClient
  public var isFull: Bool { totalFreeCapacity == 0 }
}

extension InputMultispan where Element: ~Copyable {
  
  /// Unsafely add partly-initialized memory to the spans covered by an OutputMultispan
  ///
  /// The memory in `span` must remain valid throughout the lifetime of the
  /// newly-created `OutputMultispan`.
  ///
  /// - Parameters:
  ///   - span: an `OutputSpan` to be initialized
  @unsafe
  @_alwaysEmitIntoClient
  public mutating func _appendSpan(_ span: inout InputSpan<Element>) {
    let base = unsafe span._unsafeAddressOfElement(unchecked: 0)
    let capacity = span.capacity
    let count = span.count
    _pointers.append(
      InputMultispan._Buffer(
        ptr: UnsafeMutableRawBufferPointer(start: base, count: capacity),
        count: count
      )
    )
  }
  
  /// Unsafely add partly-initialized memory to the spans covered by an OutputMultispan
  ///
  /// The memory in `buffer` must remain valid throughout the lifetime
  /// of the newly-created `OutputMultispan`. Its prefix must contain
  /// `initializedCount` initialized instances, followed by uninitialized
  /// memory. The default value of `initializedCount` is 0, representing
  /// the common case of a completely uninitialized `buffer`.
  ///
  /// - Parameters:
  ///   - buffer: a slice of an `UnsafeMutableBufferPointer` to be initialized
  ///   - initializedCount: the number of initialized elements
  ///                       at the beginning of `buffer`.
  @unsafe
  @_alwaysEmitIntoClient
  public mutating func _append(
    buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int = 0
  ) {
    _pointers.append(
      InputMultispan._Buffer(
        ptr: UnsafeMutableRawBufferPointer(buffer),
        count: initializedCount
      )
    )
  }
  
}

extension InputMultispan where Element: ~Copyable {
  
  @frozen
  public struct Index: Comparable {
    let bufferIndex: Int
    let elementIndex: Int
    
    static func <(lhs: InputMultispan.Index, rhs: InputMultispan.Index) -> Bool {
      if lhs.bufferIndex < rhs.bufferIndex {
        return true
      }
      if lhs.bufferIndex == rhs.bufferIndex {
        return lhs.elementIndex < rhs.elementIndex
      }
      return false
    }
  }
  
  @_alwaysEmitIntoClient @inline(__always)
  public func index(after index: InputMultispan.Index) -> InputMultispan.Index {
    let bufIdx = index.bufferIndex
    precondition(bufIdx < _pointers.count)
    let elementOffset = index.elementIndex &* MemoryLayout<Element>.stride
    precondition(elementOffset <= _pointers[bufIdx].ptr.count)
    if elementOffset == _pointers[bufIdx].ptr.count {
      if bufIdx == _pointers.count {
        return endIndex
      }
      return Index(bufferIndex: bufIdx &+ 1, elementIndex: 0)
    }
    return Index(bufferIndex: bufIdx, elementIndex: index.elementIndex &+ 1)
  }
  
  /// The range of `InputSpan`s for this `InputMultispan`.
  @_alwaysEmitIntoClient
  public var indices: Range<Index> {
    startIndex ..< endIndex
  }
  
  @_alwaysEmitIntoClient
  public var startIndex: Index {
    InputMultispan.Index(bufferIndex: 0, elementIndex: 0)
  }
  
  @_alwaysEmitIntoClient
  public var endIndex: Index {
    InputMultispan.Index(bufferIndex: spanCount, elementIndex: 0)
  }
  
  @inline(__always)
  @_alwaysEmitIntoClient
  internal func _checkIndex(_ index: Index) {
    let bufferIndex = index.bufferIndex
    _precondition(_pointers.indices.contains(bufferIndex), "index out of bounds")
    let buffer = _pointers[bufferIndex]
    _precondition(buffer.ptr.indices.contains(bufferIndex), "index out of bounds")
  }
  
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  public init(
    _uncheckedBuffer buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int
  ) {
    self = InputMultispan<Element>()
    self._append(buffer: buffer, initializedCount: initializedCount)
  }
  
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow buffer)
  public init(
    buffer: UnsafeMutableBufferPointer<Element>, initializedCount: Int
  ) {
    precondition(buffer._isWellAligned(), "Misaligned InputMulispan")
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

extension InputMultispan where Element: ~Copyable {

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: A valid index into this span.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public subscript(_ index: Index) -> Element {
    unsafeAddress {
      _checkIndex(index)
      return unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }
    @lifetime(self: copy self)
    unsafeMutableAddress {
      _checkIndex(index)
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
      return unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }
    @lifetime(self: copy self)
    unsafeMutableAddress {
      return unsafe _unsafeAddressOfElement(unchecked: index)
    }
  }

  /// Exchange the elements at the two given offsets
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func swapAt(_ i: Index, _ j: Index) {
    precondition(indices.contains(i))
    precondition(indices.contains(j))
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

extension InputMultispan where Element: ~Copyable {
  
  public func withInputSpan<R: ~Copyable, E: Error>(
    at index: Int,
    work: (inout InputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    let buffer = _pointers[index]
    return try buffer.ptr.withMemoryRebound(to: Element.self) { (typedBuffer) throws(E) in
      var span = InputSpan(
        _uncheckedBuffer: typedBuffer,
        initializedCount: buffer.count
      )
      return try work(&span)
      // Intentionally skipping finalize here. See TODO in our finalize method
    }
  }
    
  /// Prepend a single element to this span.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func prepend(_ value: consuming Element) {
    _precondition(spanCount > 0, "InputMultispan has no capacity")
    var v:Element? = consume value
    if let firstNonEmptySpanIdx = _firstNonEmptySpanIndex() {
      withInputSpan(at: firstNonEmptySpanIdx) { inputSpan in
        inputSpan.prepend(v.take()!)
      }
      _pointers[firstNonEmptySpanIdx].count &+= 1
      return
    }
    
    withInputSpan(at: spanCount - 1) { inputSpan in
      inputSpan.prepend(v.take()!)
    }
    _pointers[spanCount - 1].count &+= 1
    return
  }

  /// Remove the first initialized element from this span.
  ///
  /// Returns the first element. The `InputSpan` must not be empty.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "InputMultispan underflow")
    //TODO: optimize this to not iterate twice
    let idx = _firstNonEmptySpanIndex().unsafelyUnwrapped
    return withInputSpan(at: idx) {
      $0.removeFirst()
    }
  }

  /// Remove the last N elements of this span, returning the memory they occupy
  /// to the uninitialized state.
  ///
  /// `n` must not be greater than `count`
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeFirst(_ k: Int) {
    precondition(k >= 0, "Cannot remove a negative number of elements")
    precondition(k <= totalCount, "InputSpan underflow")
    //TODO: optimize
    for _ in 0 ..< k {
      _ = removeFirst()
    }
  }
  
  /// Removes and returns the first element of this input span, if it exists.
  ///
  /// - Returns: The first element of the original span if it wasn't empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public mutating func popFirst() -> Element? {
    guard totalCount > 0 else { return nil }
    return removeFirst()
  }

  /// Remove all this span's elements and return its memory
  /// to the uninitialized state.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func removeAll() {
    for spanIdx in 0 ..< spanCount {
      withInputSpan(at: spanCount - 1) { inputSpan in
        inputSpan.removeAll()
      }
    }
  }
}

//MARK: Bulk prepend functions

extension InputMultispan where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func prepend(moving source: UnsafeMutableBufferPointer<Element>) {
    precondition(source.count <= totalFreeCapacity, "InputSpan capacity overflow")

    if let idx = _firstNonEmptySpanIndex() {
      let capacity = _pointers[idx].ptr.count - _pointers[idx].count
      if capacity >= source.count {
        withInputSpan(at: idx) {
          $0.prepend(moving: source)
        }
        _pointers[idx].count &+= source.count
        return
      }
    }
    //TODO: optimize the case where we need to use multiple buffers
    for idx in source.indices.reversed() {
      prepend(source[idx])
    }
  }
}

extension InputMultispan /* where Element: Copyable */ {
  /// Repeatedly prepend an element to this multispan.
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func prepend(repeating repeatedValue: Element, count: Int) {
    precondition(count <= totalFreeCapacity, "InputSpan capacity overflow")
    //TODO: optimize
    for _ in 0 ..< count {
      prepend(repeatedValue)
    }
  }
}

#endif
