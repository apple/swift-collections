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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

@frozen @usableFromInline
internal struct MultispanBuffer<Element: ~Copyable> {
  @usableFromInline var ptr: UnsafeMutableRawBufferPointer
  @usableFromInline var count: Int
  
  @inlinable @inline(__always)
  var byteCapacity: Int {
    _assumeNonNegative(ptr.count)
  }
  
  @inlinable @inline(__always)
  var elementCapacity: Int {
    byteCapacity / MemoryLayout<Element>.stride
  }
  
  @inlinable @inline(__always)
  var elementCount: Int {
    get {
      count / MemoryLayout<Element>.stride
    }
    set(newValue) {
      precondition(newValue >= 0)
      count = newValue * MemoryLayout<Element>.stride
    }
  }

  @inlinable @inline(__always)
  var freeByteCapacity: Int {
    _assumeNonNegative(ptr.count &- count)
  }
  
  @inlinable @inline(__always)
  var freeElementCapacity: Int {
    freeByteCapacity / MemoryLayout<Element>.stride
  }
  
  @inlinable @inline(__always)
  init(ptr: UnsafeMutableRawBufferPointer, count: Int) {
    self.ptr = ptr
    self.count = count
  }
}

@frozen @usableFromInline
internal struct SmallBufferPointerArray<Element: ~Copyable>: RandomAccessCollection, RangeReplaceableCollection {
  @usableFromInline typealias Index = Int
  @usableFromInline typealias Element = MultispanBuffer<Element>
  @usableFromInline typealias StorageType = (UInt64, UInt64, UInt64)
  @usableFromInline var storage: StorageType = (0, 0, 0)
  @usableFromInline var count = 0
  @inlinable static var inlineThreshold: Int {
    1
  }
  
  @inlinable @inline(__always)
  init() {
    precondition(
      Self.inlineThreshold &* MemoryLayout<MultispanBuffer<Element>>.stride <= MemoryLayout<StorageType>.size
    )
  }
  
  @inlinable @inline(__always)
  var inline: Bool {
    count <= Self.inlineThreshold
  }
  
  @inlinable
  subscript(position: Int) -> MultispanBuffer<Element> {
    _read {
      precondition(position < count)
      if inline {
        yield withUnsafeBytes(of: storage) {
          $0.assumingMemoryBound(to: MultispanBuffer<Element>.self)[position]
        }
      } else {
        yield withUnsafeBytes(of: storage) {
          return $0.assumingMemoryBound(
            to: UniqueArray<MultispanBuffer<Element>>.self
          )[0][position]
        }
      }
    }
    _modify {
      precondition(position < count)
      if inline {
        var result = withUnsafeBytes(of: &storage) {
          $0.assumingMemoryBound(to: MultispanBuffer<Element>.self)[position]
        }
        defer {
          withUnsafeMutableBytes(of: &storage) {
            $0.assumingMemoryBound(to: MultispanBuffer<Element>.self)[position] = result
          }
        }
        yield &result
       
      } else {
        var result = withUnsafeBytes(of: storage) {
          $0.assumingMemoryBound(
            to: UniqueArray<MultispanBuffer<Element>>.self
          )[0][position]
        }
        defer {
          withUnsafeMutableBytes(of: &storage) {
            $0.assumingMemoryBound(
              to: UniqueArray<MultispanBuffer<Element>>.self
            )[0][position] = result
          }
        }
        yield &result
      }
    }
  }
  
  @inlinable
  mutating func replaceSubrange(
    _ subrange: Range<Int>,
    with newElements: some Collection<MultispanBuffer<Element>>
  ) {
    precondition(subrange.lowerBound >= 0 && subrange.upperBound <= count, "Subrange out of bounds")
    
    let addedCount = newElements.count &- subrange.count
    let newCount = count + addedCount
    
    // Check if we need to transition from inline to heap storage
    if inline && newCount > Self.inlineThreshold {
      // Save the current inline element
      let firstElement = count > 0 ? self[0] : nil
      storage = (0, 0, 0)
      withUnsafeMutableBytes(of: &storage) {
        $0.withMemoryRebound(
          to: UniqueArray<MultispanBuffer<Element>>.self
        ) { buffer in
          buffer.initializeElement(
            at: 0,
            to: UniqueArray(capacity: Swift.max(4, newCount))
          )
          if let firstElement {
            buffer[0].append(firstElement)
          }
        }
      }
      // Now handle the replacement in heap storage
      withUnsafeMutableBytes(of: &storage) {
        $0.withMemoryRebound(
          to: UniqueArray<MultispanBuffer<Element>>.self
        ) { buffer in
          buffer[0].replace(removing: subrange, copying: newElements)
        }
      }
    } else if inline {
      // Replace in inline storage
      precondition(newCount <= Self.inlineThreshold, "Inline storage overflow")
      withUnsafeMutableBytes(of: &storage) { bytes in
        let buffers = bytes.assumingMemoryBound(to: MultispanBuffer<Element>.self)
        
        // Shift elements after the subrange if necessary
        let shiftDistance = addedCount
        if shiftDistance != 0 && subrange.upperBound < count {
          let moveStart = subrange.upperBound
          let moveEnd = count
          let moveCount = moveEnd - moveStart
          
          if shiftDistance > 0 {
            // Shift right: work backwards to avoid overwriting
            for i in (0..<moveCount).reversed() {
              buffers[moveStart + i + shiftDistance] = buffers[moveStart + i]
            }
          } else {
            // Shift left: work forwards
            for i in 0..<moveCount {
              buffers[moveStart + i + shiftDistance] = buffers[moveStart + i]
            }
          }
        }
        
        // Insert new elements
        var insertIndex = subrange.lowerBound
        for element in newElements {
          buffers[insertIndex] = element
          insertIndex &+= 1
        }
      }
    } else {
      // Replace in heap storage
      withUnsafeMutableBytes(of: &storage) {
        $0.withMemoryRebound(
          to: UniqueArray<MultispanBuffer<Element>>.self
        ) { buffer in
          buffer[0].replace(removing: subrange, copying: newElements)
        }
      }
    }
    
    count = newCount
  }
  
  @inlinable @inline(always)
  var startIndex: Int {
    0
  }
  
  @inlinable @inline(always)
  var endIndex: Int {
    count
  }
}

@available(SwiftStdlib 5.0, *)
@safe
@frozen
public struct InputMultispan<Element: ~Copyable>: ~Copyable, ~Escapable {
  
  @usableFromInline
  internal var _pointers = SmallBufferPointerArray<Element>()

  @inlinable
  deinit {
    for idx in 0 ..< _pointers.count {
      let byteCount = _pointers[idx].count
      let elementCount = byteCount / MemoryLayout<Element>.stride
      unsafe _pointers[idx].ptr.withMemoryRebound(to: Element.self) {
        _ = unsafe UnsafeMutableBufferPointer<Element>(
          start: $0.baseAddress.unsafelyUnwrapped,
          count: elementCount
        ).deinitialize()
      }
    }
  }

  /// Create an OutputSpan with zero capacity
  @inlinable @inline(always)
  @lifetime(immortal)
  public init() {}
}

@available(SwiftStdlib 5.0, *)
extension InputMultispan: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {
  
  @inlinable
  internal func _firstNonEmptySpanIndex() -> Int? {
    for idx in 0 ..< _pointers.count {
      if _pointers[idx].elementCount > 0 {
        return idx
      }
    }
    return nil
  }
  
  @inlinable
  internal func _lastNonFullSpanIndex() -> Int? {
    for idx in (0 ..< _pointers.count).reversed() {
      if _pointers[idx].freeElementCapacity > 0 {
        return idx
      }
    }
    return nil
  }
  
  @unsafe
  @inlinable @inline(always)
  internal func _unsafeAddressOfElement(
    unchecked index: Index
  ) -> UnsafeMutablePointer<Element> {
    let buffer = _pointers[index.bufferIndex]
    // Elements are stored at the end of the buffer, like InputSpan
    // The first element is at position (capacity - count)
    let elementOffset = (buffer.elementCapacity &- buffer.elementCount &+ index.elementIndex) &* MemoryLayout<Element>.stride
    let address = unsafe buffer.ptr.baseAddress.unsafelyUnwrapped.advanced(by: elementOffset)
    return unsafe address.assumingMemoryBound(to: Element.self)
  }
}

@available(SwiftStdlib 5.0, *)
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
  @inlinable
  public consuming func finalize(
    for buffer: UnsafeMutableBufferPointer<Element>
  ) -> Int {
    return totalCount
  }
}

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {
  
  @inlinable @inline(always)
  public var spanCount: Int {
    _assumeNonNegative(_pointers.count)
  }
  
  /// The number of initialized elements in this span.
  @inlinable @inline(always)
  public func count(at index: Int) -> Int {
    _assumeNonNegative(_pointers[index].elementCount)
  }
  
  @inlinable
  public var totalCount: Int {
    var total = 0
    for idx in 0 ..< spanCount {
      total += count(at: idx)
    }
    return total
  }

  @inlinable @inline(always)
  public func freeCapacity(at index: Int) -> Int {
    _pointers[index].freeElementCapacity
  }
  
  /// The number of additional elements that can be consumed from this span.
  @inlinable
  public var totalFreeCapacity: Int {
    var total = 0
    for idx in 0 ..< spanCount {
      total += freeCapacity(at: idx)
    }
    return total
  }

  /// A Boolean value indicating whether the span is empty.
  @inlinable
  public var isEmpty: Bool {
    guard spanCount > 0 else { return true }
    return totalCount == 0
  }

  /// A Boolean value indicating whether the span is full.
  @inlinable
  public var isFull: Bool { totalFreeCapacity == 0 }
}

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {
  
  /// Unsafely add partly-initialized memory to the spans covered by an InputMultispan
  ///
  /// The memory in `span` must remain valid throughout the lifetime of the
  /// newly-created `InputMultispan`.
  ///
  /// - Parameters:
  ///   - span: an `InputSpan` to be initialized
  @unsafe
  @inlinable
  public mutating func _appendSpan(_ span: inout InputSpan<Element>) {
    // Unfortunately there's no way to express the required lifetimes to store
    // the InputSpan itself here, so we have to unsafely cheat and get the
    // underlying pointer out
    span.withUnsafeMutableBufferPointer { buffer, count in
      _pointers.append(
        MultispanBuffer(
          ptr: UnsafeMutableRawBufferPointer(buffer),
          count: count * MemoryLayout<Element>.stride
        )
      )
    }
  }
  
  /// Unsafely add partly-initialized memory to the spans covered by an InputMultispan
  ///
  /// The memory in `buffer` must remain valid throughout the lifetime
  /// of the newly-created `InputMultispan`. Its prefix must contain
  /// `initializedCount` initialized instances, followed by uninitialized
  /// memory. The default value of `initializedCount` is 0, representing
  /// the common case of a completely uninitialized `buffer`.
  ///
  /// - Parameters:
  ///   - buffer: a slice of an `UnsafeMutableBufferPointer` to be initialized
  ///   - initializedCount: the number of initialized elements
  ///                       at the beginning of `buffer`.
  @unsafe
  @inlinable
  public mutating func _append(
    buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int = 0
  ) {
    _pointers.append(
      MultispanBuffer(
        ptr: UnsafeMutableRawBufferPointer(buffer),
        count: initializedCount * MemoryLayout<Element>.stride
      )
    )
  }
  
}

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {
  
  @frozen
  public struct Index: Comparable {
    @usableFromInline let bufferIndex: Int
    @usableFromInline let elementIndex: Int
    
    @inlinable @inline(__always)
    public static func <(lhs: InputMultispan.Index, rhs: InputMultispan.Index) -> Bool {
      if lhs.bufferIndex < rhs.bufferIndex {
        return true
      }
      if lhs.bufferIndex == rhs.bufferIndex {
        return lhs.elementIndex < rhs.elementIndex
      }
      return false
    }
    
    @inlinable @inline(__always)
    init(bufferIndex: Int, elementIndex: Int) {
      self.bufferIndex = bufferIndex
      self.elementIndex = elementIndex
    }
  }
  
  @inlinable @inline(__always)
  public func index(after index: InputMultispan.Index) -> InputMultispan.Index {
    let bufIdx = index.bufferIndex
    precondition(bufIdx < _pointers.count)
    let elementOffset = index.elementIndex
    precondition(elementOffset <= _pointers[bufIdx].elementCapacity)
    if elementOffset == _pointers[bufIdx].elementCapacity {
      if bufIdx == _pointers.count {
        return endIndex
      }
      return Index(bufferIndex: bufIdx &+ 1, elementIndex: 0)
    }
    return Index(bufferIndex: bufIdx, elementIndex: index.elementIndex &+ 1)
  }
  
  /// The range of `InputSpan`s for this `InputMultispan`.
  @inlinable @inline(__always)
  public var indices: Range<Index> {
    startIndex ..< endIndex
  }
  
  @inlinable @inline(__always)
  public var startIndex: Index {
    InputMultispan.Index(bufferIndex: 0, elementIndex: 0)
  }
  
  @inlinable @inline(__always)
  public var endIndex: Index {
    InputMultispan.Index(bufferIndex: spanCount, elementIndex: 0)
  }
  
  @inlinable @inline(__always)
  internal func _checkIndex(_ index: Index) {
    let bufferIndex = index.bufferIndex
    precondition(_pointers.indices.contains(bufferIndex), "index out of bounds")
    let buffer = _pointers[bufferIndex]
    precondition(buffer.ptr.indices.contains(bufferIndex), "index out of bounds")
  }
  
  @unsafe
  @inlinable @inline(__always)
  @_lifetime(borrow buffer)
  public init(
    _uncheckedBuffer buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int
  ) {
    self = InputMultispan<Element>()
    self._append(buffer: buffer, initializedCount: initializedCount)
  }
  
  @unsafe
  @inlinable @inline(__always)
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

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: A valid index into this span.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
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
  @inlinable @inline(__always)
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
  @inlinable
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
  @inlinable
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
extension InputMultispan where Element: ~Copyable {
  
  @inlinable @inline(always)
  public func withInputSpan<R: ~Copyable, E: Error>(
    at index: Int,
    work: (inout InputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    let buffer = _pointers[index]
    return try buffer.ptr.withMemoryRebound(to: Element.self) { (typedBuffer) throws(E) in
      var span = InputSpan<Element>(
        _uncheckedBuffer: typedBuffer,
        initializedCount: buffer.elementCount
      )
      return try work(&span)
      // Intentionally skipping finalize here. See TODO in our finalize method
    }
  }
    
  /// Prepend a single element to this span.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func prepend(_ value: consuming Element) {
    precondition(spanCount > 0, "InputMultispan has no capacity")
    var v:Element? = consume value
    
    // Find the last buffer with available capacity
    // Since InputSpan grows backwards, we fill buffers from right to left
    let targetIdx = _lastNonFullSpanIndex().unsafelyUnwrapped
    
    withInputSpan(at: targetIdx) { inputSpan in
      inputSpan.prepend(v.take()!)
    }
    _pointers[targetIdx].elementCount &+= 1
  }

  /// Remove the first initialized element from this span.
  ///
  /// Returns the first element. The `InputSpan` must not be empty.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "InputMultispan underflow")
    let idx = _firstNonEmptySpanIndex().unsafelyUnwrapped
    defer { _pointers[idx].elementCount &-= 1 }
    return withInputSpan(at: idx) {
      $0.removeFirst()
    }
  }

  /// Remove the last N elements of this span, returning the memory they occupy
  /// to the uninitialized state.
  ///
  /// `n` must not be greater than `count`
  @inlinable
  @_lifetime(self: copy self)
  public mutating func removeFirst(_ k: Int) {
    precondition(k >= 0, "Cannot remove a negative number of elements")
    precondition(k <= totalCount, "InputSpan underflow")
    var remaining = k
    for spanIdx in 0 ..< spanCount {
      guard remaining > 0 else { break }
      let spanElementCount = _pointers[spanIdx].elementCount
      let toRemove = Swift.min(remaining, spanElementCount)
      if toRemove > 0 {
        withInputSpan(at: spanIdx) { inputSpan in
          inputSpan.removeFirst(toRemove)
        }
        _pointers[spanIdx].elementCount &-= toRemove
        remaining &-= toRemove
      }
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
  @inlinable
  @_lifetime(self: copy self)
  public mutating func removeAll() {
    for spanIdx in 0 ..< spanCount {
      defer {
        _pointers[spanIdx].elementCount = 0
      }
      withInputSpan(at: spanIdx) { inputSpan in
        inputSpan.removeAll()
      }
    }
  }
}

//MARK: Bulk prepend functions

@available(SwiftStdlib 5.0, *)
extension InputMultispan where Element: ~Copyable {
  @inlinable
  @_lifetime(self: copy self)
  public mutating func prepend(moving source: UnsafeMutableBufferPointer<Element>) {
    precondition(source.count <= totalFreeCapacity, "InputSpan capacity overflow")
    var sourceOffset = source.count
    for idx in (0 ..< _pointers.count).reversed() {
      guard sourceOffset > 0 else { break }
      let freeCapacity = _pointers[idx].freeElementCapacity
      guard freeCapacity > 0 else { continue }
      let toMove = Swift.min(freeCapacity, sourceOffset)
      let sliceStart = sourceOffset &- toMove
      let slice = UnsafeMutableBufferPointer(
        start: source.baseAddress.unsafelyUnwrapped.advanced(by: sliceStart),
        count: toMove
      )
      withInputSpan(at: idx) {
        $0.prepend(moving: slice)
      }
      _pointers[idx].elementCount &+= toMove
      sourceOffset &-= toMove
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension InputMultispan /* where Element: Copyable */ {
  /// Repeatedly prepend an element to this multispan.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func prepend(repeating repeatedValue: Element, count: Int) {
    precondition(count <= totalFreeCapacity, "InputSpan capacity overflow")
    var remaining = count
    for idx in (0 ..< _pointers.count).reversed() {
      guard remaining > 0 else { break }
      let freeCapacity = _pointers[idx].freeElementCapacity
      guard freeCapacity > 0 else { continue }
      let toFill = Swift.min(freeCapacity, remaining)
      withInputSpan(at: idx) {
        $0.prepend(repeating: repeatedValue, count: toFill)
      }
      _pointers[idx].elementCount &+= toFill
      remaining &-= toFill
    }
  }
}

#endif
