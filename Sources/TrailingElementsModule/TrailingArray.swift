//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A value that manages a contiguous block of memory starting with a header
/// value and then followed by a contiguous array of elements. Values of this
/// type own the underlying memory, and are non-copyable to ensure that
/// ownership of that memory is unique.
///
/// The number of elements stored after the header must be computable based on
/// the information in the header (via the `trailingCount` property), so that
/// it is not stored separately.
@frozen
public struct TrailingArray<Header: TrailingElements>: ~Copyable
where Header: ~Copyable
{
  /// A pointer to the raw, underlying storage. This may point before the
  /// Header instance in cases where the alignment of Element exceeds that
  /// of the Header and we have overallocated to compensate.
  @usableFromInline
  var _storage: UnsafeMutableRawPointer
  
  /// Pointer to the header.
  @_alwaysEmitIntoClient
  var _pointer: UnsafeMutablePointer<Header> {
    Self.headerPointer(fromStorage: _storage)
  }
  
  /// The element type stored within the buffer.
  public typealias Element = Header.Element
  
  /// Allocate storage and initialize only the header, leaving the trailing
  /// elements uninitialized. This is private because it can compromise
  /// memory safety.
  @_alwaysEmitIntoClient
  private init(_headerOnly header: consuming Header) {
    let (bytes, alignment) = Self.allocationSize(header: header)
    _storage = UnsafeMutableRawPointer.allocate(
      byteCount: bytes,
      alignment: alignment
    )
    
    _pointer.initialize(to: header)
  }
  
  @available(SwiftStdlib 5.1, *)
  @_alwaysEmitIntoClient
  mutating func _initializeTrailingElements<E>(
    initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    var output = unsafe OutputSpan(buffer: rawElements, initializedCount: 0)
    try initializer(&output)
    let initialized = unsafe output.finalize(for: rawElements)
    precondition(count == initialized, "TrailingArray initialization underflow")
  }
  
  /// Allocate an intrusive managed buffer with the given header and calling
  /// the initializer to fill in the trailing elements.
  @available(SwiftStdlib 5.1, *)
  @_alwaysEmitIntoClient
  public init<E>(
    header: consuming Header,
    initializingTrailingElementsWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(_headerOnly: header)
    try _initializeTrailingElements(initializer: initializer)
  }
  
  /// Allocate an intrusive managed buffer with the given header and
  /// initializing each trailing element with the given `element`.
  @_alwaysEmitIntoClient
  public init(header: consuming Header, repeating element: Element) {
    self.init(_headerOnly: header)
    rawElements.initialize(repeating: element)
  }
  
  /// Deinitialize each of the trailing elements, then the header, then
  /// deallocate the underlying storage.
  @_alwaysEmitIntoClient
  deinit {
    rawElements.deinitialize()
    _pointer.deinitialize(count: 1)
    _storage.deallocate()
  }
  
  /// Take ownership over a pointer to memory containing the header followed
  /// by the trailing elements.
  ///
  /// Once this managed buffer instance is no longer used, this memory will
  /// be freed.
  /// - Parameters:
  ///   - pointer: A pointer to the header, which should already have been
  ///     initialized by the caller.
  ///   - storage: A pointer to the storage containing the header and
  ///     pointers. This will usually be `UnsafeMutableRawPointer(pointer)`,
  ///     but may precede `pointer` if the elements have greater alignment
  ///     than the header.
  @_alwaysEmitIntoClient
  public init(
    consuming pointer: UnsafeMutablePointer<Header>,
    storage: UnsafeMutableRawPointer
  ) {
    self._storage = storage
    precondition(
      self._pointer == pointer,
      "header pointer does not account for the alignment of the elements"
    )
  }
  
  /// Return the pointer to the underlying memory, including ownership over
  /// that memory. The underlying storage will not be freed by this buffer;
  /// it is the responsibility of the caller. The header pointer and
  /// underlying storage are returned separately, to handle cases where
  /// the alignment of the elements is greater than than of the header.
  @_alwaysEmitIntoClient
  public consuming func leakStorage() -> (
    pointer: UnsafeMutablePointer<Header>,
    storage: UnsafeMutableRawPointer
  ) {
    let pointer = self._pointer
    let storage = _storage
    discard self
    return (pointer, storage)
  }
  
  /// Access the header portion of the buffer.
  @_alwaysEmitIntoClient
  public var header: Header {
    unsafeAddress {
      UnsafePointer(_pointer)
    }
    
    unsafeMutableAddress {
      _pointer
    }
  }
  
  /// The number of trailing elements in the value.
  @_alwaysEmitIntoClient
  public var count: Int { header.trailingCount }
  
  /// Starting index for accessing the trailing elements. Always 0
  @_alwaysEmitIntoClient
  public var startIndex: Int { 0 }
  
  /// Ending index for accessing the trailing elements. Always `count`.
  @_alwaysEmitIntoClient
  public var endIndex: Int { count }
  
  /// Indices covering all of the trailing elements. Always `0..<count`.
  @_alwaysEmitIntoClient
  public var indices: Range<Int> { 0..<count }
  
  /// Access the trailing element at the given index.
  @_alwaysEmitIntoClient
  public subscript(index: Int) -> Element {
    get {
      precondition(index >= 0 && index < count)
      return rawElements[index]
    }
    
    set {
      precondition(index >= 0 && index < count)
      rawElements[index] = newValue
    }
  }
  
  /// Access the flexible array elements.
  @_alwaysEmitIntoClient
  var rawElements: UnsafeMutableBufferPointer<Element> {
    UnsafeMutableBufferPointer(
      start: UnsafeMutableRawPointer(_pointer.advanced(by: 1))
        .assumingMemoryBound(to: Element.self),
      count: header.trailingCount
    )
  }
  
  /// Accesses the trailing elements following the header.
  @available(SwiftStdlib 5.1, *)
  @_alwaysEmitIntoClient
  public var elements: Span<Element> {
    @_lifetime(self)
    get {
      _overrideLifetime(rawElements.span, borrowing: self)
    }
  }
  
  /// Accesses the trailing elements following the header, allowing mutation
  /// of those elements.
  @available(SwiftStdlib 5.1, *)
  @_alwaysEmitIntoClient
  public var mutableElements: MutableSpan<Element> {
    @_lifetime(self)
    mutating get {
      let elements = self.rawElements.mutableSpan
      return _overrideLifetime(elements, mutating: &self)
    }
  }
  
  /// Execute the given closure, providing it with an unsafe buffer pointer
  /// referencing the header.
  @_alwaysEmitIntoClient
  public mutating func withUnsafeMutablePointerToHeader<E, R: ~Copyable>(
    _ body: (UnsafeMutablePointer<Header>) throws(E) -> R
  ) throws(E) -> R {
    return try body(_pointer)
  }
  
  /// Execute the given closure, providing it with an unsafe buffer pointer
  /// referencing the trailing elements.
  @_alwaysEmitIntoClient
  public mutating func withUnsafeMutablePointerToElements<E, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws(E) -> R
  ) throws(E) -> R {
    return try body(rawElements)
  }
  
  /// Execute the given closure, providing it with unsafe pointers to the
  /// header and trailing elements, respectively.
  @_alwaysEmitIntoClient
  public mutating func withUnsafeMutablePointers<E, R: ~Copyable>(
    _ body: (UnsafeMutablePointer<Header>, UnsafeMutableBufferPointer<Element>) throws(E) -> R
  ) throws(E) -> R {
    return try body(_pointer, rawElements)
  }
  
  /// Determine the allocation size and alignment needed for the given header
  /// value along with its trailing elements.
  ///
  /// In cases where the element's alignment exceeds that of the header,
  /// this operation will suggest overallocation so that the elements can be
  /// properly aligned following the header.
  @_alwaysEmitIntoClient
  static func allocationSize(header: borrowing Header) -> (size: Int, alignment: Int) {
    // The number of bytes needed to contain the header and elements,
    // assuming that there are no alignment issues.
    let numBytes = MemoryLayout<Header>.stride + MemoryLayout<Element>.stride * header.trailingCount
    
    let headerAlignment = MemoryLayout<Header>.alignment
    let elementAlignment = MemoryLayout<Element>.alignment
    
    // If the header provides sufficient alignment for the elements,
    // we're done.
    if elementAlignment <= headerAlignment {
      return (numBytes, MemoryLayout<Header>.alignment)
    }
    
    // We may have to slide an allocation by up to the difference between
    // the element and header alignments to ensure that the elements are
    // appropriately aligned.
    return (
      numBytes + elementAlignment - headerAlignment,
      MemoryLayout<Element>.alignment)
  }
  
  /// Given storage that is large enough to accommodate padding + the header
  /// + the elements, return the header pointer from the storage pointer.
  @_alwaysEmitIntoClient
  static func headerPointer(fromStorage storage: UnsafeMutableRawPointer) -> UnsafeMutablePointer<Header> {
    let headerAlignment = MemoryLayout<Header>.alignment
    let elementAlignment = MemoryLayout<Element>.alignment
    
    // Normal case: the header has sufficient alignment to include the
    // elements, so the storage refers directly to the header.
    if elementAlignment <= headerAlignment {
      return storage.assumingMemoryBound(to: Header.self)
    }
    
    // The header is stored right before the elements, with padding bytes
    // between the start of the allocation and up to the header.
    return storage.advanced(by: MemoryLayout<Header>.stride)
      .alignedUp(for: Element.self)
      .advanced(by: -MemoryLayout<Header>.stride)
      .assumingMemoryBound(to: Header.self)
  }
}

extension TrailingArray where Header: ~Copyable, Header.Element: BitwiseCopyable {
  /// Allocate an intrusive managed buffer with the given header, but leaving the
  /// trailing elements uninitialized.
  @_alwaysEmitIntoClient
  @unsafe
  public init(header: consuming Header, uninitializedTrailingElements: ()) {
    self.init(_headerOnly: header)
  }
}

extension TrailingArray where Header: Copyable {
  /// Create a temporary intrusive managed buffer for the given header, whose
  /// trailing elements are initialized to copies of `element`. That instance
  /// is provided to the given `body` to operate on for the duration of the
  /// call. The temporary is allocated on the stack, unless it is very
  /// large according to `withUnsafeTemporaryAllocation`.
  @_alwaysEmitIntoClient
  public static func withTemporaryValue<R: ~Copyable, E>(
    header: consuming Header,
    repeating element: Element,
    body: (inout TrailingArray<Header>) throws(E) -> R
  ) throws(E) -> R {
    return try _withTemporaryValue(
      header: header, uninitializedTrailingElements: ()
    ) { (value) throws(E) in
      value.rawElements.initialize(repeating: element)
      return try body(&value)
    }
  }
  
  /// Create a temporary intrusive managed buffer for the given header, whose
  /// trailing elements are initialized with the given `initializer` function.
  /// That instance is provided to the given `body` to operate on for the
  /// duration of the call. The temporary is allocated on the stack, unless
  /// it is very large according to `withUnsafeTemporaryAllocation`.
  @available(SwiftStdlib 5.1, *)
  @_alwaysEmitIntoClient
  public static func withTemporaryValue<R: ~Copyable, E>(
    header: consuming Header,
    initializingTrailingElementsWith initializer: (inout OutputSpan<Element>) throws(E) -> Void,
    body: (inout TrailingArray<Header>) throws(E) -> R
  ) throws(E) -> R {
    return try _withTemporaryValue(
      header: header, uninitializedTrailingElements: ()
    ) { (value) throws(E) in
      try value._initializeTrailingElements(initializer: initializer)
      return try body(&value)
    }
  }
}

extension TrailingArray {
  /// Create a temporary intrusive managed buffer for the given header, whose
  /// trailing elements are left uninitialized. That instance is provided to
  /// the given `body` to operate on for the duration of the
  /// call. The temporary is allocated on the stack, unless it is very
  /// large according to `withUnsafeTemporaryAllocation`.
  @_alwaysEmitIntoClient
  @unsafe
  static func _withTemporaryValue<R: ~Copyable, E>(
    header: Header,
    uninitializedTrailingElements: (),
    body: (inout TrailingArray<Header>) throws(E) -> R
  ) throws(E) -> R {
    let (numBytes, alignment) = allocationSize(header: header)
    
    // Allocate temporary storage large enough for the value we need.
    let result: Result<R, E> = withUnsafeTemporaryAllocation(
      byteCount: numBytes,
      alignment: alignment
    ) { buffer in
      // Initialize the header within the temporary allocation.
      let storagePointer = buffer.baseAddress!
      let headerPointer = TrailingArray.headerPointer(fromStorage: storagePointer)
      headerPointer.initialize(to: header)
      
      /// Create a trailing array over that temporary storage.
      var managedBuffer = TrailingArray(consuming: headerPointer,
                                        storage: storagePointer)
      let resultOrError: Result<R, E>
      do throws(E) {
        resultOrError = .success(try body(&managedBuffer))
      } catch {
        resultOrError = .failure(error)
      }
      
      // Deinitialize the elements and header.
      managedBuffer.rawElements.deinitialize()
      managedBuffer._pointer.deinitialize(count: 1)
      
      // Tell the trailing buffer not to free the storage.
      let (finalPointer, finalStorage) = managedBuffer.leakStorage()
      precondition(finalPointer == headerPointer)
      precondition(finalStorage == storagePointer)
      
      return resultOrError
    }
    
    return try result.get()
  }
}

extension TrailingArray where Header.Element: BitwiseCopyable {
  /// Create a temporary intrusive managed buffer for the given header, whose
  /// trailing elements are left uninitialized. That instance is provided to
  /// the given `body` to operate on for the duration of the
  /// call. The temporary is allocated on the stack, unless it is very
  /// large according to `withUnsafeTemporaryAllocation`.
  @_alwaysEmitIntoClient
  @unsafe
  public static func withTemporaryValue<R: ~Copyable, E>(
    header: consuming Header,
    uninitializedTrailingElements: (),
    body: (inout TrailingArray<Header>) throws(E) -> R
  ) throws(E) -> R {
    return try _withTemporaryValue(
      header: header, uninitializedTrailingElements: ()
    ) { (value) throws(E) in
      try body(&value)
    }
  }
}
