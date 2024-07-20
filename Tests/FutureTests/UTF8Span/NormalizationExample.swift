public struct NFCNormalizer: Sendable {

  public init() {
    fatalError()
  }

  /// Returns the next normalized scalar,
  /// consuming data from the given source if necessary.
  ///
  public mutating func resume(
    consuming source: inout some IteratorProtocol<Unicode.Scalar>
  ) -> Unicode.Scalar? {
    fatalError()
  }


  /// Returns the next normalized scalar,
  /// iteratively invoking the scalar producer if necessary
  ///
  public mutating func resume(
    scalarProducer: () -> Unicode.Scalar?
  ) -> Unicode.Scalar? {
    fatalError()
  }

  /// Marks the end of the logical text stream
  /// and returns remaining data from the normalizer's buffers.
  ///
  public mutating func flush() -> Unicode.Scalar? {
    fatalError()
  }

  /// Resets the normalizer to its initial state.
  ///
  /// Any allocated buffer capacity will be kept and reused
  /// unless it exceeds the given maximum capacity,
  /// in which case it will be discarded.
  ///
  public mutating func reset(maximumCapacity: Int = Int.max) {
    fatalError()
  }
}

import Future

extension UTF8Span {
  func nthNormalizedScalar(
    _ n: Int
  ) -> Unicode.Scalar? {
    var normalizer = NFCNormalizer()
    var pos = 0
    var count = 0

    while true {
      guard let s = normalizer.resume(scalarProducer: {
        guard pos < count else {
          return nil
        }
        let (scalar, next) = self.decodeNextScalar(
          uncheckedAssumingAligned: pos)
        pos = next
        return scalar
      }) else {
        return nil
      }

      if count == n { return s }
      count += 1
    }
  }
}
