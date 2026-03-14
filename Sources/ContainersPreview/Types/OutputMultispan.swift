#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

// `OutputMultispan` is a reference to any number of contiguous regions of
// memory that start with some number of initialized `Element` instances
// followed by uninitialized memory. It provides operations to access the items
// it stores, as well as to add new elements, remove existing ones, and access
// the underlying regions individually
@available(SwiftStdlib 5.0, *)
@safe
@frozen
public struct OutputMultispan<Element: ~Copyable>: ~Copyable, ~Escapable {
  
  @usableFromInline
  internal var _pointers = SmallBufferPointerArray<Element>()

  @inlinable
  deinit {
    _pointers.destroyAll()
  }

  /// Create an OutputSpan with zero capacity
  @inlinable @inline(always)
  @lifetime(immortal)
  public init() {}
}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan where Element: ~Copyable {
  
  @inlinable
  internal func _firstNonFullSpanIndex() -> Int? {
    for idx in 0 ..< _pointers.count {
      if freeCapacity(at: idx) > 0 {
        return idx
      }
    }
    return nil
  }
  
  @inlinable
  internal func _lastNonEmptySpanIndex() -> Int? {
    for idx in (0 ..< _pointers.count).reversed() {
      if count(at: idx) > 0 {
        return idx
      }
    }
    return nil
  }
  
}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan where Element: ~Copyable {
  
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
  
  /// The number of additional elements that can be added to this span.
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
extension OutputMultispan where Element: ~Copyable  {
  
  /// Unsafely add partly-initialized memory to the spans covered by an OutputMultispan
  ///
  /// The memory in `span` must remain valid throughout the lifetime of the
  /// newly-created `OutputMultispan`.
  ///
  /// - Parameters:
  ///   - span: an `OutputSpan` to be initialized
  @unsafe
  @inlinable @inline(always)
  public mutating func _appendSpan(_ span: inout OutputSpan<Element>) {
    span.withUnsafeMutableBufferPointer {
      _pointers.append(
        MultispanBuffer(
          ptr: UnsafeMutableRawBufferPointer($0),
          byteCount: $1 * MemoryLayout<Element>.stride
        )
      )
    }
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
  @inlinable @inline(always)
  public mutating func _append(
    buffer: UnsafeMutableBufferPointer<Element>,
    initializedCount: Int = 0
  ) {
    _pointers.append(
      MultispanBuffer(
        ptr: UnsafeMutableRawBufferPointer(buffer),
        byteCount: initializedCount * MemoryLayout<Element>.stride
      )
    )
  }
  
}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan where Element: ~Copyable {
  
  @frozen
  public struct Index: Comparable {
    @usableFromInline let bufferIndex: Int
    @usableFromInline let elementIndex: Int
    
    @inlinable @inline(always)
    public static func <(lhs: OutputMultispan.Index, rhs: OutputMultispan.Index) -> Bool {
      if lhs.bufferIndex < rhs.bufferIndex {
        return true
      }
      if lhs.bufferIndex == rhs.bufferIndex {
        return lhs.elementIndex < rhs.elementIndex
      }
      return false
    }
    
    @inlinable @inline(always)
    init(bufferIndex: Int, elementIndex: Int) {
      self.bufferIndex = bufferIndex
      self.elementIndex = elementIndex
    }
  }
  
  @inlinable @inline(always)
  public func index(after index: OutputMultispan.Index) -> OutputMultispan.Index {
    let bufIdx = index.bufferIndex
    precondition(bufIdx < _pointers.count)
    precondition(index.elementIndex < _pointers[bufIdx].elementCount)
    let nextElementIndex = index.elementIndex &+ 1
    if nextElementIndex < _pointers[bufIdx].elementCount {
      return Index(bufferIndex: bufIdx, elementIndex: nextElementIndex)
    }
    let nextBufIdx = bufIdx &+ 1
    if nextBufIdx >= _pointers.count {
      return endIndex
    }
    return Index(bufferIndex: nextBufIdx, elementIndex: 0)
  }

  /// The range of `OutputSpan`s for this `OutputMultispan`.
  @inlinable @inline(always)
  public var indices: Range<Index> {
    startIndex ..< endIndex
  }
  
  @inlinable @inline(always)
  public var startIndex: Index {
    OutputMultispan.Index(bufferIndex: 0, elementIndex: 0)
  }
  
  @inlinable @inline(always)
  public var endIndex: Index {
    OutputMultispan.Index(bufferIndex: spanCount, elementIndex: 0)
  }
  
  @inlinable @inline(always)
  internal func _checkIndex(_ index: Index) {
    let bufferIndex = index.bufferIndex
    precondition(_pointers.indices.contains(bufferIndex), "index out of bounds")
    let buffer = _pointers[bufferIndex]
    precondition(buffer.ptr.indices.contains(bufferIndex), "index out of bounds")
  }

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: A valid index into this span.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(always)
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
  @inlinable @inline(always)
  public subscript(unchecked index: Index) -> Element {
    unsafeAddress {
      unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }
    @lifetime(self: copy self)
    unsafeMutableAddress {
      unsafe _unsafeAddressOfElement(unchecked: index)
    }
  }

  @unsafe
  @inlinable @inline(always)
  internal func _unsafeAddressOfElement(
    unchecked index: Index
  ) -> UnsafeMutablePointer<Element> {
    let chunk = _pointers[index.bufferIndex]
    return chunk.ptr.withMemoryRebound(to: Element.self, { buffer in
      buffer.baseAddress.unsafelyUnwrapped.advanced(by: index.elementIndex)
    })
  }

  /// Exchange the elements at the two given offsets
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @inlinable
  @lifetime(self: copy self)
  public mutating func swapAt(_ i: Index, _ j: Index) {
    precondition(indices.contains(i))
    precondition(indices.contains(j))
    unsafe swapAt(unchecked: i, unchecked: j)
  }

  /// Exchange the elements at the two given offsets
  ///
  /// This function does not validate `i` or `j`; this is an unsafe operation.
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @unsafe
  @inlinable
  @lifetime(self: copy self)
  public mutating func swapAt(unchecked i: Index, unchecked j: Index) {
    let pi = unsafe _unsafeAddressOfElement(unchecked: i)
    let pj = unsafe _unsafeAddressOfElement(unchecked: j)
    let temporary = unsafe pi.move()
    unsafe pi.initialize(to: pj.move())
    unsafe pj.initialize(to: consume temporary)
  }
  
  @inlinable @inline(always)
  public mutating func withOutputSpan<R: ~Copyable, E: Error>(
    at index: Int,
    work: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    let buffer = _pointers[index]
    return try buffer.ptr.withMemoryRebound(to: Element.self) { (typedBuffer) throws(E) in
      var span = OutputSpan(buffer: typedBuffer, initializedCount: buffer.elementCount)
      return try work(&span)
      // Intentionally skipping finalize here. See TODO in our finalize method
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan where Element: ~Copyable {
  /// Append a single element to this span.
  ///
  ///
  @inlinable
  @lifetime(self: copy self)
  public mutating func append(_ value: consuming Element) {
    precondition(totalFreeCapacity > 0, "OutputMultispan has no capacity")
    var v:Element? = consume value
    let idx = _firstNonFullSpanIndex().unsafelyUnwrapped
    withOutputSpan(at: idx) { outputSpan in
      precondition(!outputSpan.isFull)
      outputSpan.append(v.take()!)
    }
    _pointers[idx].elementCount &+= 1
  }

  /// Remove the last initialized element from this span.
  ///
  /// Returns the last element. The `OutputSpan` must not be empty.
  @inlinable
  @lifetime(self: copy self)
  public mutating func removeLast() -> Element {
    precondition(spanCount > 0, "OutputMultispan has no capacity")
    if let idx = _lastNonEmptySpanIndex() {
      defer { _pointers[idx].elementCount &-= 1 }
      return withOutputSpan(at: idx) { outputSpan in
        outputSpan.removeLast()
      }
    } else {
      preconditionFailure("OutputMultispan has no elements to remove")
    }
  }

  /// Remove the last N elements of this span, returning the memory they occupy
  /// to the uninitialized state.
  ///
  /// `n` must not be greater than `count`
  @inlinable
  @lifetime(self: copy self)
  public mutating func removeLast(_ k: Int) {
    precondition(k >= 0, "Cannot remove a negative number of elements")
    precondition(k <= totalCount, "OutputMultispan underflow")
    var remaining = k
    for idx in (0 ..< _pointers.count).reversed() {
      guard remaining > 0 else { break }
      let spanElementCount = _pointers[idx].elementCount
      let toRemove = Swift.min(remaining, spanElementCount)
      if toRemove > 0 {
        withOutputSpan(at: idx) { outputSpan in
          outputSpan.removeLast(toRemove)
        }
        _pointers[idx].elementCount &-= toRemove
        remaining &-= toRemove
      }
    }
  }

  /// Remove all this span's elements and return its memory
  /// to the uninitialized state.
  @inlinable
  @lifetime(self: copy self)
  public mutating func removeAll() {
    for spanIdx in 0 ..< spanCount {
      defer {
        _pointers[spanIdx].elementCount = 0
      }
      withOutputSpan(at: spanIdx) { outputSpan in
        outputSpan.removeAll()
      }
    }
  }
}

//MARK: bulk-append functions
@available(SwiftStdlib 5.0, *)
extension OutputMultispan {

  /// Repeatedly append an element to this span.
  @inlinable
  @lifetime(self: copy self)
  public mutating func append(repeating repeatedValue: Element, count: Int) {
    precondition(count <= totalFreeCapacity, "OutputMultispan capacity overflow")
    var remaining = count
    for idx in 0 ..< _pointers.count {
      guard remaining > 0 else { break }
      let freeCapacity = _pointers[idx].freeElementCapacity
      guard freeCapacity > 0 else { continue }
      let toFill = Swift.min(freeCapacity, remaining)
      withOutputSpan(at: idx) { outputSpan in
        outputSpan.append(repeating: repeatedValue, count: toFill)
      }
      _pointers[idx].elementCount &+= toFill
      remaining &-= toFill
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputMultispan where Element: ~Copyable {
  /// Consume the output span and return the number of initialized elements.
  ///
  /// This method should be invoked in the scope where the `OutputSpan` was
  /// created, when it is time to commit the contents of the updated buffer
  /// back into the construct being initialized.
  ///
  /// The context that created the output span is expected to remember what
  /// memory region the span is addressing. This consuming method expects to
  /// receive a copy of the same buffer pointer as a (loose) proof of ownership.
  ///
  /// - Parameter buffer: The buffer we expect the `OutputSpan` to reference.
  ///      This must be the same region of memory passed to
  ///      the `OutputSpan` initializer.
  /// - Returns: The number of initialized elements in the same buffer, as
  ///      tracked by the consumed `OutputSpan` instance.
  @unsafe
  @inlinable
  public consuming func finalize() -> Int {
    return totalCount
  }
}

#endif
