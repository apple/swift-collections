#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

import Swift

// `OutputMultispan` is a reference to any number of contiguous regions of
// memory that start with some number of initialized `Element` instances
// followed by uninitialized memory. It provides operations to access the items
// it stores, as well as to add new elements, remove existing ones, and access
// the underlying regions individually
@safe
@frozen
public struct OutputMultispan<Element: ~Copyable>: ~Copyable, ~Escapable {
  
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

extension OutputMultispan: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension OutputMultispan where Element: ~Copyable {
  
  internal func _firstNonFullSpanIndex() -> Int? {
    for idx in 0 ..< _pointers.count {
      if _pointers[idx].count < _pointers[idx].ptr.count {
        return idx
      }
    }
    return nil
  }
  
}

extension OutputMultispan where Element: ~Copyable {
  
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
      total += freeCapacity(at: idx)
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

extension OutputMultispan where Element: ~Copyable  {
  
  /// Unsafely add partly-initialized memory to the spans covered by an OutputMultispan
  ///
  /// The memory in `span` must remain valid throughout the lifetime of the
  /// newly-created `OutputMultispan`.
  ///
  /// - Parameters:
  ///   - span: an `OutputSpan` to be initialized
  @unsafe
  @_alwaysEmitIntoClient
  public mutating func _appendSpan(_ span: inout OutputSpan<Element>) {
    let base = unsafe span._unsafeAddressOfElement(unchecked: 0)
    let capacity = span.capacity
    let count = span.count
    _pointers.append(
      OutputMultispan._Buffer(
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
      OutputMultispan._Buffer(
        ptr: UnsafeMutableRawBufferPointer(buffer),
        count: initializedCount
      )
    )
  }
  
}

extension OutputMultispan where Element: ~Copyable {
  
  @frozen
  public struct Index: Comparable {
    let bufferIndex: Int
    let elementIndex: Int
    
    static func <(lhs: OutputMultispan.Index, rhs: OutputMultispan.Index) -> Bool {
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
  public func index(after index: OutputMultispan.Index) -> OutputMultispan.Index {
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

  /// The range of `OutputSpan`s for this `OutputMultispan`.
  @_alwaysEmitIntoClient
  public var indices: Range<Index> {
    startIndex ..< endIndex
  }
  
  @_alwaysEmitIntoClient
  public var startIndex: Index {
    OutputMultispan.Index(bufferIndex: 0, elementIndex: 0)
  }
  
  @_alwaysEmitIntoClient
  public var endIndex: Index {
    OutputMultispan.Index(bufferIndex: spanCount, elementIndex: 0)
  }
  
  @inline(__always)
  @_alwaysEmitIntoClient
  internal func _checkIndex(_ index: Index) {
    let bufferIndex = index.bufferIndex
    _precondition(_pointers.indices.contains(bufferIndex), "index out of bounds")
    let buffer = _pointers[bufferIndex]
    _precondition(buffer.ptr.indices.contains(bufferIndex), "index out of bounds")
  }

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
      unsafe UnsafePointer(_unsafeAddressOfElement(unchecked: index))
    }
    @lifetime(self: copy self)
    unsafeMutableAddress {
      unsafe _unsafeAddressOfElement(unchecked: index)
    }
  }

  @unsafe
  @_alwaysEmitIntoClient
  internal func _unsafeAddressOfElement(
    unchecked index: Index
  ) -> UnsafeMutablePointer<Element> {
    let address = unsafe _pointers[ index.bufferIndex].ptr.baseAddress.unsafelyUnwrapped.advanced(by: index.elementIndex)
    return unsafe address.assumingMemoryBound(to: Element.self)
  }

  /// Exchange the elements at the two given offsets
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func swapAt(_ i: Index, _ j: Index) {
    _precondition(indices.contains(i))
    _precondition(indices.contains(j))
    unsafe swapAt(unchecked: i, unchecked: j)
  }

  /// Exchange the elements at the two given offsets
  ///
  /// This function does not validate `i` or `j`; this is an unsafe operation.
  ///
  /// - Parameter i: A valid index into this span.
  /// - Parameter j: A valid index into this span.
  @unsafe
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func swapAt(unchecked i: Index, unchecked j: Index) {
    let pi = unsafe _unsafeAddressOfElement(unchecked: i)
    let pj = unsafe _unsafeAddressOfElement(unchecked: j)
    let temporary = unsafe pi.move()
    unsafe pi.initialize(to: pj.move())
    unsafe pj.initialize(to: consume temporary)
  }
  
  public func withOutputSpan<R: ~Copyable, E: Error>(
    at index: Int,
    work: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    let buffer = _pointers[index]
    return try buffer.ptr.withMemoryRebound(to: Element.self) { (typedBuffer) throws(E) in
      var span = OutputSpan(
        _uncheckedBuffer: typedBuffer,
        initializedCount: buffer.count
      )
      return try work(&span)
      // Intentionally skipping finalize here. See TODO in our finalize method
    }
  }
}

extension OutputMultispan where Element: ~Copyable {
  /// Append a single element to this span.
  ///
  ///
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func append(_ value: consuming Element) {
    _precondition(totalFreeCapacity > 0, "OutputMultispan has no capacity")
    var v:Element? = consume value
    let idx = _firstNonFullSpanIndex().unsafelyUnwrapped
    withOutputSpan(at: idx) { outputSpan in
      outputSpan.append(v.take()!)
    }
    _pointers[idx].count &+= 1
  }

  /// Remove the last initialized element from this span.
  ///
  /// Returns the last element. The `OutputSpan` must not be empty.
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func removeLast() -> Element {
    _precondition(spanCount > 0, "OutputMultispan has no capacity")
    if let idx = _firstNonFullSpanIndex() {
      defer { _pointers[idx].count &-= 1 }
      return withOutputSpan(at: idx) { outputSpan in
        outputSpan.removeLast()
      }
    }
    defer { _pointers[spanCount - 1].count &-= 1 }
    return withOutputSpan(at: spanCount - 1) { outputSpan in
      outputSpan.removeLast()
    }
  }

  /// Remove the last N elements of this span, returning the memory they occupy
  /// to the uninitialized state.
  ///
  /// `n` must not be greater than `count`
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func removeLast(_ k: Int) {
    _precondition(spanCount > 0, "OutputMultispan has no capacity")
    if let idx = _firstNonFullSpanIndex() {
      if _pointers[idx].count >= k {
        defer { _pointers[idx].count &-= k }
        withOutputSpan(at: idx) { outputSpan in
          outputSpan.removeLast(k)
        }
        return
      }
    }
    //TODO: optimize
    for _ in 0 ..< k {
      _ = removeLast()
    }
  }

  /// Remove all this span's elements and return its memory
  /// to the uninitialized state.
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func removeAll() {
    for spanIdx in 0 ..< spanCount {
      withOutputSpan(at: spanIdx) { outputSpan in
        outputSpan.removeAll()
      }
    }
  }
}

//MARK: bulk-append functions
extension OutputMultispan {

  /// Repeatedly append an element to this span.
  @_alwaysEmitIntoClient
  @lifetime(self: copy self)
  public mutating func append(repeating repeatedValue: Element, count: Int) {
    //TODO: optimize
    for _ in 0 ..< count {
      append(repeatedValue)
    }
  }
}
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
  @_alwaysEmitIntoClient
  public consuming func finalize() -> Int {
    //TODO: clearly something needs to happen here but it's not obvious how to structure it
    return totalCount
  }
}

#endif
