
@frozen
public struct UTF8Span: Copyable, ~Escapable {
  public var unsafeBaseAddress: UnsafeRawPointer

  /*
   A bit-packed count and flags (such as isASCII)

   ╔═══════╦═════╦═════╦══════════╦═══════╗
   ║  b63  ║ b62 ║ b61 ║  b60:56  ║ b56:0 ║
   ╠═══════╬═════╬═════╬══════════╬═══════╣
   ║ ASCII ║ NFC ║ SSC ║ reserved ║ count ║
   ╚═══════╩═════╩═════╩══════════╩═══════╝

   ASCII means the contents are all-ASCII (<0x7F). 
   NFC means contents are in normal form C for fast comparisons.
   SSC means single-scalar Characters (i.e. grapheme clusters): every
     `Character` holds only a single `Unicode.Scalar`.

   TODO: Contains-newline would be useful for Regex `.`

   Question: Should we have null-termination support?
             A null-terminated UTF8Span has a NUL byte after its contents
             and contains no interior NULs. How would we ensure the
             NUL byte is exclusively borrowed by us?

   */
  @usableFromInline
  internal var _countAndFlags: UInt64

  @inlinable @inline(__always)
  init<Owner: ~Copyable & ~Escapable>(
    _unsafeAssumingValidUTF8 start: UnsafeRawPointer,
    _countAndFlags: UInt64,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self.unsafeBaseAddress = start
    self._countAndFlags = _countAndFlags

    _invariantCheck()
  }
}

extension UTF8Span {
  /// ...
  public init(
    validating codeUnits: Span<UInt8>
  ) throws(UTF8.EncodingError) -> dependsOn(codeUnits) Self {
    self.unsafeBaseAddress = .init(codeUnits._start)

    let count = codeUnits._count
    let isASCII = try unsafeBaseAddress._validateUTF8(limitedBy: count)

    let uintCount = UInt64(truncatingIfNeeded: count)
    if isASCII {
      self._countAndFlags = uintCount | Self._asciiBit
    } else {
      self._countAndFlags = uintCount
    }
    _internalInvariant(self.count == codeUnits.count)
  }

  // TODO: Below are contingent on how we want to handle NUL-termination
  #if false
  public init<Owner: ~Copyable & ~Escapable>(
    nullTerminatedCString: UnsafeRawPointer,
    owner: borrowing Owner
  ) throws(DecodingError) -> dependsOn(owner) Self {
  }

  public init<Owner: ~Copyable & ~Escapable>(
    nullTerminatedCString: UnsafePointer<CChar>,
    owner: borrowing Owner
  ) throws(DecodingError) -> dependsOn(owner) Self {
  }
  #endif
}




// MARK: Canonical comparison

extension UTF8Span {
  // HACK: working around lack of internals
  internal var _str: String { unsafeBaseAddress._str(0..<count) }

  /// Whether `self` is equivalent to `other` under Unicode Canonical
  /// Equivalance.
  public func isCanonicallyEquivalent(
    to other: UTF8Span
  ) -> Bool {
    self._str == other._str
  }

  /// Whether `self` orders less than `other` under Unicode Canonical 
  /// Equivalance using normalized code-unit order (in NFC).
  public func isCanonicallyLessThan(
    _ other: UTF8Span
  ) -> Bool {
    self._str < other._str
  }
}



// MARK: String

extension String {
  // NOTE: If `self` is lazily bridged NSString, or is in a small-string
  // form, memory may be allocated...
  public var utf8Span: UTF8Span {
    _read {
      // TODO: avoid the allocation
      let arr = Array(self.utf8)
      let span = arr.storage
      yield UTF8Span(
        _unsafeAssumingValidUTF8: .init(span._start),
        _countAndFlags: UInt64(span.count), // TODO: set the flags
        owner: arr)
    }
  }
}

extension UTF8Span {
  /// Calls a closure with a pointer to the viewed contiguous storage.
  ///
  /// The buffer pointer passed as an argument to `body` is valid only
  /// during the execution of `withUnsafeBufferPointer(_:)`.
  /// Do not store or return the pointer for later use.
  ///
  /// - Parameter body: A closure with an `UnsafeBufferPointer` parameter
  ///   that points to the viewed contiguous storage. If `body` has
  ///   a return value, that value is also used as the return value
  ///   for the `withUnsafeBufferPointer(_:)` method. The closure's
  ///   parameter is valid only for the duration of its execution.
  /// - Returns: The return value of the `body` closure parameter.
  @_alwaysEmitIntoClient
  borrowing public func withUnsafeBufferPointer<
    E: Error, Result: ~Copyable & ~Escapable
  >(
    _ body: (_ buffer: borrowing UnsafeBufferPointer<UInt8>) throws(E) -> Result
  ) throws(E) -> dependsOn(self) Result {
    try body(unsafeBaseAddress._ubp(0..<count))
  }
}

// MARK: Internals

extension UTF8Span {
  @_alwaysEmitIntoClient @inline(__always)
  func _invariantCheck() {
#if DEBUG

#endif
  }
}

#if false
extension RawSpan {
  public func parseUTF8(from start: Int, length: Int) throws -> UTF8Span {
    let span = self[
      uncheckedOffsets: start ..< start &+ length
    ].view(as: UInt8.self)
    return try UTF8Span(validating: span)
  }

  // TODO: Below are contingent on how we want to handle NUL-termination
  public func parseNullTermiantedUTF8() throws -> UTF8Span {
    fatalError()
  }
}

// TODO: Below is contingent on a Cursor or Iterator type
extension RawSpan.Cursor {
  public mutating func parseUTF8(length: Int) throws -> UTF8Span {
    fatalError()
  }
  public mutating func parseNullTermiantedUTF8() throws -> UTF8Span {
    fatalError()
  }
}
#endif

// TODO: cString var, or something like that
