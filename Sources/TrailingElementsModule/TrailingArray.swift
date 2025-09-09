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
    /// The underlying storage.
    @usableFromInline
    var _pointer: UnsafeMutablePointer<Header>

    /// The element type stored within the buffer.
    public typealias Element = Header.Element

    /// Allocate storage and initialize only the header, leaving the trailing
    /// elements uninitialized. This is private because it can compromise
    /// memory safety.
    @_alwaysEmitIntoClient
    private init(_headerOnly header: consuming Header) {
        _pointer = UnsafeMutableRawPointer.allocate(
            byteCount: Self.allocationSize(
                header: header
            ),
            alignment: MemoryLayout<Header>.alignment
        ).assumingMemoryBound(to: Header.self)

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
        _pointer.deallocate()
    }

    /// Take ownership over a pointer to memory containing the header followed
    /// by the trailing elements.
    ///
    /// Once this managed buffer instance is no longer used, this memory will
    /// be freed.
    @_alwaysEmitIntoClient
    public init(consuming pointer: UnsafeMutablePointer<Header>) {
        self._pointer = pointer
    }

    /// Return the pointer to the underlying memory, including ownership over
    /// that memory. The underlying storage will not be freed by this buffer;
    /// it is the responsibility of the caller.
    @_alwaysEmitIntoClient
    public consuming func leakStorage() -> UnsafeMutablePointer<Header> {
        let pointer = self._pointer
        discard self
        return pointer
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
    public mutating func withUnsafeMutablePointerToHeader<E, R: ~Copyable>(_ body: (UnsafeMutablePointer<Header>) throws(E) -> R) throws(E) -> R {
        return try body(_pointer)
    }

    /// Execute the given closure, providing it with an unsafe buffer pointer
    /// referencing the trailing elements.
    @_alwaysEmitIntoClient
    public mutating func withUnsafeMutablePointerToElements<E, R: ~Copyable>(_ body: (UnsafeMutableBufferPointer<Element>) throws(E) -> R) throws(E) -> R {
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

    /// Determine the allocation size needed for the given header value.
    @_alwaysEmitIntoClient
    public static func allocationSize(header: borrowing Header) -> Int {
        MemoryLayout<Header>.size + MemoryLayout<Element>.stride * header.trailingCount
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
        return try TrailingPadding<Header>.withTemporaryValue(
            header: header,
            totalSize: allocationSize(header: header)
        ) { (storage) throws(E) in
            /// Create a managed buffer over that temporary storage.
            var managedBuffer = TrailingArray(consuming: storage._pointer)
            managedBuffer.rawElements.initialize(repeating: element)

            do throws(E) {
                let result = try body(&managedBuffer)

                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                return result
            } catch {
                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                throw error
            }
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
        return try TrailingPadding<Header>.withTemporaryValue(
            header: header,
            totalSize: allocationSize(header: header)
        ) { (storage) throws(E) in
            /// Create a managed buffer over that temporary storage.
            var managedBuffer = TrailingArray(consuming: storage._pointer)
            try managedBuffer._initializeTrailingElements(initializer: initializer)

            do throws(E) {
                let result = try body(&managedBuffer)

                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                return result
            } catch {
                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                throw error
            }
        }
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
        return try TrailingPadding<Header>.withTemporaryValue(
            header: header,
            totalSize: allocationSize(header: header)
        ) { (storage) throws(E) in
            /// Create a managed buffer over that temporary storage.
            var managedBuffer = TrailingArray(consuming: storage._pointer)

            do throws(E) {
                let result = try body(&managedBuffer)

                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                return result
            } catch {
                // Tell the managed buffer not to free the storage.
                let finalPointer = managedBuffer.leakStorage()
                precondition(finalPointer == storage._pointer)

                throw error
            }
        }
    }
}
