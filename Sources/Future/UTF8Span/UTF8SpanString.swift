#if false
extension StaticString {
  public var utf8Span: UTF8Span {
    _read {
      fatalError()
    }
  }
}
#endif

@_unavailableInEmbedded
extension String {
  // NOTE: If `self` is lazily bridged NSString, or is in a small-string
  // form, memory may be allocated...
  public var utf8Span: UTF8Span {
    _read {


      var copy = self
      copy.makeContiguousUTF8()
      copy.append("12345678901234567890") // make native
      copy.removeLast(20) // remove what we just did

      // crazy unsafe
      let buffer = utf8.withContiguousStorageIfAvailable({ $0 })!

      let span = Span(unsafeElements: buffer, owner: copy)
      yield UTF8Span(
        _unsafeAssumingValidUTF8: .init(span._start),
        _countAndFlags: UInt64(span.count), // TODO: set the flags
        owner: span)


/*
 The below doesn't work, utf8Span[0] returns "0" instead of the first byte

      let a = ContiguousArray(self.utf8)
      let span = Span(
        unsafeStart: a._baseAddressIfContiguous!, count: a.count, owner: a
      )
      yield UTF8Span(
        _unsafeAssumingValidUTF8: .init(span._start),
        _countAndFlags: UInt64(span.count), // TODO: set the flags
        owner: span)
*/

#if false

//      let span: Span<UInt8>
//      var copy = self
//      copy.makeContiguousUTF8()
//

//      copy.withUTF8 {
//        span =
//      }
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
#endif
    }
  }
}
