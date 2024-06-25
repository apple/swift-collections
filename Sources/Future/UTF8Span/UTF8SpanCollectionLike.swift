extension UTF8Span {
  /// Accesses the byte at the specified `position`.
  ///
  /// - Parameter position: The offset of the byte to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  @_alwaysEmitIntoClient
  public subscript(_ position: Int) -> UInt8 {
    precondition(boundsCheck(position))
    return self[unchecked: position]
  }

  /// Accesses the byte at the specified `position`.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  @_alwaysEmitIntoClient
  public subscript(unchecked position: Int) -> UInt8 {
    _internalInvariant(boundsCheck(position))
    return unsafeBaseAddress._loadByte(position)
  }

  /// Constructs a new `UTF8Span` span over the bytes within the supplied
  /// range of positions within this span.
  ///
  /// `bounds` must be scalar aligned.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `UTF8Span` over the bytes within `bounds`.
  @_alwaysEmitIntoClient
  public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
    let bounds = bounds.relative(to: Int.min..<Int.max)
    precondition(boundsCheck(bounds))
    return extracting(unchecked: bounds)
  }

  /// Constructs a new `UTF8Span` span over the bytes within the supplied
  /// range of positions within this span.
  ///
  /// `bounds` must be scalar aligned.
  ///
  /// This function does not validate that `bounds` is within the span's
  /// bounds; this is an unsafe operation.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `UTF8Span` over the bytes within `bounds`.
  @_alwaysEmitIntoClient
  public func extracting(
    unchecked bounds: some RangeExpression<Int>
  ) -> Self {
    let bounds = bounds.relative(to: Int.min..<Int.max)
    _internalInvariant(boundsCheck(bounds))
    precondition(isScalarAligned(bounds))
    return extracting(uncheckedAssumingAligned: bounds)
  }

  /// Constructs a new `UTF8Span` span over the bytes within the supplied
  /// range of positions within this span.
  ///
  /// `bounds` must be scalar aligned.
  ///
  /// This function does not validate that `bounds` is within the span's
  /// bounds; this is an unsafe operation.
  ///
  /// This function does not validate that `bounds` is scalar aligned;
  /// this is an unsafe operation.
  ///
  /// The returned span's first item is always at offset 0; unlike buffer
  /// slices, extracted spans do not generally share their indices with the
  /// span from which they are extracted.
  ///
  /// - Parameter bounds: A valid range of positions. Every position in
  ///     this range must be within the bounds of this `Span`.
  ///
  /// - Returns: A `UTF8Span` over the bytes within `bounds`.
  @_alwaysEmitIntoClient
  public func extracting(
    uncheckedAssumingAligned bounds: some RangeExpression<Int>
  ) -> Self {
    let bounds = bounds.relative(to: Int.min..<Int.max)
    _internalInvariant(boundsCheck(bounds))
    _internalInvariant(isScalarAligned(bounds))
    let ptr = unsafeBaseAddress + bounds.lowerBound
    let countAndFlags = UInt64(truncatingIfNeeded: bounds.count)
    | (_countAndFlags & Self._flagsMask)
    return UTF8Span(
      _unsafeAssumingValidUTF8: ptr,
      _countAndFlags: countAndFlags,
      owner: self)
  }

  /// Whether this span has the same bytes as `other`.
  @_alwaysEmitIntoClient
  public func bytesEqual(to other: UTF8Span) -> Bool {
    guard count == other.count else {
      return false
    }
    for i in 0..<count {
      guard self[unchecked: i] == other[unchecked: i] else {
        return false
      }
    }
    return true
  }

  /// Whether this span has the same bytes as `other`.
  @_alwaysEmitIntoClient
  public func bytesEqual(to other: some Sequence<UInt8>) -> Bool {
    var idx = 0
    for elt in other {
      guard idx < count, self[unchecked: idx] == elt else {
        return false
      }
      idx += 1
    }
    return idx == count
  }

  /// Whether this span has the same `Unicode.Scalar`s as `other`.
  @_alwaysEmitIntoClient
  public func scalarsEqual(
    to other: some Sequence<Unicode.Scalar>
  ) -> Bool {
    var idx = 0
    for elt in other {
      guard idx < count else { return false }
      let (scalar, next) = decodeNextScalar(uncheckedAssumingAligned: idx)
      guard scalar == elt else { return false }
      idx = next
    }
    return idx == count
  }

  /// Whether this span has the same `Character`s as `other`.
  @_unavailableInEmbedded
  @_alwaysEmitIntoClient
  public func charactersEqual(
    to other: some Sequence<Character>
  ) -> Bool {
    var idx = 0
    for elt in other {
      guard idx < count else { return false }
      let (scalar, next) = decodeNextCharacter(
        uncheckedAssumingAligned: idx)
      guard scalar == elt else { return false }
      idx = next
    }
    return idx == count
  }

  @_alwaysEmitIntoClient
  public var isEmpty: Bool {
    count == 0
  }
}

extension UTF8Span: ContiguousStorage {
  @_alwaysEmitIntoClient
  public var storage: Span<UInt8> {
    Span(
      unsafeStart: unsafeBaseAddress,
      byteCount: count,
      owner: self)
  }
}
