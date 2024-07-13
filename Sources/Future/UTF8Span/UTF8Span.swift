
@frozen
public struct UTF8Span: Copyable, ~Escapable {
  public var unsafeBaseAddress: UnsafeRawPointer

  /*
   A bit-packed count and flags (such as isASCII)

   ╔═══════╦═════╦═════╦═════╦══════════╦═══════╗
   ║  b63  ║ b62 ║ b61 ║ b60 ║ b59:56   ║ b56:0 ║
   ╠═══════╬═════╬═════╬═════╬══════════╬═══════╣
   ║ ASCII ║ NFC ║ SSC ║ NUL ║ reserved ║ count ║
   ╚═══════╩═════╩═════╩═════╩══════════╩═══════╝

   ASCII means the contents are all-ASCII (<0x7F). 
   NFC means contents are in normal form C for fast comparisons.
   SSC means single-scalar Characters (i.e. grapheme clusters): every
     `Character` holds only a single `Unicode.Scalar`.
   NUL means the contents are a null-terminated C string (that is,
     there is a guranteed, borrowed NULL byte after the end of `count`).

   TODO: NUL means both no-interior and null-terminator, so does this
   mean that String doesn't ever set it because we don't want to scan
   for interior nulls? I think this is the only viable option...

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

  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafe codeUnits: UnsafeBufferPointer<UInt8>,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    try self.init(
      validating: Span(unsafeElements: codeUnits, owner: owner))
  }

  // Question: do we want raw versions?
  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafeRaw codeUnits: UnsafeRawBufferPointer,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    try self.init(
      validating: Span(unsafeBytes: codeUnits, owner: owner))
  }

  // Question: do we want separate count versions?
  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafeStart start: UnsafePointer<UInt8>,
    count: Int,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    try self.init(
      validating: Span(unsafeStart: start, count: count, owner: owner))
  }

  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafeStart start: UnsafeRawPointer,
    count: Int,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    try self.init(
      validating: Span(unsafeStart: start, byteCount: count, owner: owner))
  }

  // Question: Do we do a raw version? String doesn't have one
  // Also, should we do a UnsafePointer<UInt8> version, it's
  // annoying to not have one sometimes...?
  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafeRawCString nullTerminatedUTF8: UnsafeRawPointer,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    // TODO: is there a better way?
    try self.init(
      validatingUnsafeCString: nullTerminatedUTF8.assumingMemoryBound(
        to: CChar.self
      ),
      owner: owner)
    self._setIsNullTerminatedCString(true)
  }

  @_alwaysEmitIntoClient
  public init<Owner: ~Copyable & ~Escapable>(
    validatingUnsafeCString nullTerminatedUTF8: UnsafePointer<CChar>,
    owner: borrowing Owner
  ) throws(UTF8.EncodingError) -> dependsOn(owner) Self {
    let len = UTF8._nullCodeUnitOffset(in: nullTerminatedUTF8)
    try self.init(
      validatingUnsafeStart: UnsafeRawPointer(nullTerminatedUTF8),
      count: len,
      owner: owner)
    self._setIsNullTerminatedCString(true)
  }
}


// MARK: Canonical comparison

@_unavailableInEmbedded
extension UTF8Span {
  // HACK: working around lack of internals
  internal var _str: String { unsafeBaseAddress._str(0..<count) }

  /// Whether `self` is equivalent to `other` under Unicode Canonical
  /// Equivalence.
  public func isCanonicallyEquivalent(
    to other: UTF8Span
  ) -> Bool {
    self._str == other._str
  }

  /// Whether `self` orders less than `other` under Unicode Canonical 
  /// Equivalence using normalized code-unit order (in NFC).
  public func isCanonicallyLessThan(
    _ other: UTF8Span
  ) -> Bool {
    self._str < other._str
  }
}



// MARK: String

@_unavailableInEmbedded
extension String {
  // NOTE: If `self` is lazily bridged NSString, or is in a small-string
  // form, memory may be allocated...
  public var utf8Span: UTF8Span {
    _read {
      let span: Span<UInt8>
      if count < 16 { // Wrong way to know whether the String is smol
//      if _guts.isSmall {
//        let /*@addressable*/ rawStorage = _guts.asSmall._storage
//        let span = RawSpan(
//          unsafeRawPointer: UnsafeRawPointer(Builtin.adressable(rawStorage)),
//          count: MemoryLayout<_SmallString.RawBitPattern>.size,
//          owner: self
//        )
//        yield span.view(as: UTF8.CodeUnit.self)

        let a = ContiguousArray(self.utf8)
//        yield a.storage
        span = Span(
          unsafeStart: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }
      else if let buffer = utf8.withContiguousStorageIfAvailable({ $0 }) {
        // this is totally wrong, but there is a way with stdlib-internal API
        span = Span(unsafeElements: buffer, owner: self)
      }
      else { // copy non-fast code units if we don't have eager bridging
        let a = ContiguousArray(self.utf8)
//        yield a.storage
        span = Span(
          unsafeStart: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }

      // TODO: set null-terminated bit

//      let span = self.utf8.storage
      yield UTF8Span(
        _unsafeAssumingValidUTF8: .init(span._start),
        _countAndFlags: UInt64(span.count), // TODO: set the flags
        owner: span)
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
    if isNullTerminatedCString {
      _internalInvariant(
        unsafeBaseAddress.load(fromByteOffset: count, as: UInt8.self) == 0)
      // TODO: byte scan for no interior nulls...
    }
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
  public func parseNullTerminatedUTF8() throws -> UTF8Span {
    fatalError()
  }
}

// TODO: Below is contingent on a Cursor or Iterator type
extension RawSpan.Cursor {
  public mutating func parseUTF8(length: Int) throws -> UTF8Span {
    fatalError()
  }
  public mutating func parseNullTerminatedUTF8() throws -> UTF8Span {
    fatalError()
  }
}
#endif

// TODO: cString var, or something like that
