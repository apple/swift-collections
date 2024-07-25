
#if false
extension UTF8Span {
  @_alwaysEmitIntoClient
  public init(
    _ ss: StaticString
  ) -> dependsOn(immortal) Self {
    if ss.hasPointerRepresentation {
      self.init(
        _unsafeAssumingValidUTF8:  UnsafeRawPointer(ss.utf8Start),
        _countAndFlags: UInt64(ss.utf8CodeUnitCount), // TODO: isASCII
        owner: ss
      )
    } else {
      fatalError("TODO: spill to stack, would this beed a coroutine? also, no longer immortal")
    }
  }
}

extension UTF8Span: ExpressibleByStringLiteral {
  public init(stringLiteral: StaticString) {
    fatalError()
  }
}
#endif

///
///
///

