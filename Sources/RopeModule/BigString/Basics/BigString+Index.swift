//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
extension BigString {
  public  struct Index: Sendable {
    typealias _Rope = BigString._Rope

    // ┌───────────────────────────────┬───┬───────────┬────────────────────┐
    // │ b63:b11                       │b10│ b9:b8     │ b7:b0              │
    // ├───────────────────────────────┼───┼───────────┼────────────────────┤
    // │ UTF-8 global offset           │ T │ alignment │ UTF-8 chunk offset │
    // └───────────────────────────────┴───┴───────────┴────────────────────┘
    // b10 (T): UTF-16 trailing surrogate indicator
    // b9: isCharacterAligned
    // b8: isScalarAligned
    //
    // 100: UTF-16 trailing surrogate
    // 001: Index known to be scalar aligned
    // 011: Index known to be Character aligned
    var _rawBits: UInt64

    /// A (possibly invalid) rope index.
    var _rope: _Rope.Index?

    internal init(_raw: UInt64, _rope: _Rope.Index?) {
      self._rawBits = _raw
      self._rope = _rope
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index {
  @inline(__always)
  internal static func _bitsForUTF8Offset(_ utf8Offset: Int) -> UInt64 {
    let v = UInt64(truncatingIfNeeded: UInt(bitPattern: utf8Offset))
    assert(v &>> 53 == 0)
    return v &<< 11
  }

  @inline(__always)
  internal static var _chunkIndexMask: UInt64 { 0x7FF }

  @inline(__always)
  internal static var _flagsMask: UInt64 { 0x700 }
  public var utf8Offset: Int {
    Int(truncatingIfNeeded: _rawBits &>> 11)
  }

  /// The specific index for the chunk. UTF-8 offset is only valid if `_rope`
  /// is not nil.
  internal var _chunkIndex: BigString._Chunk.Index {
    get {
      return BigString._Chunk.Index(
        UInt16(truncatingIfNeeded: _rawBits & Self._chunkIndexMask)
      )
    }

    set {
      // If the UTF-16 trailing surrogate bit is set, then the scalar and
      // character alignment bits can never be set.
      assert(newValue.flags <= 0x4)
      _rawBits &= ~Self._chunkIndexMask
      _rawBits |= UInt64(newValue.utf8Offset)
      _rawBits |= UInt64(newValue.flags) &<< 8
    }
  }

  @inline(__always)
  internal var _orderingValue: UInt64 {
    _rawBits &>> 10
  }

  /// The base offset of the addressed chunk. Only valid if `_rope` is not nil.
  internal var _utf8BaseOffset: Int {
    utf8Offset - Int(_chunkIndex.utf8Offset)
  }

  @inline(__always)
  internal var _flags: UInt64 {
    get {
      _rawBits & Self._flagsMask
    }
    set {
      assert(newValue & ~Self._flagsMask == 0)
      _rawBits &= ~Self._flagsMask
      _rawBits |= newValue
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index {
  internal mutating func _clearUTF16TrailingSurrogate() {
    _flags = 0
  }

  internal func _knownScalarAligned() -> Self {
    var copy = self
    copy._chunkIndex = _chunkIndex.scalarAligned
    return copy
  }

  internal func _knownCharacterAligned() -> Self {
    var copy = self
    copy._chunkIndex = _chunkIndex.characterAligned
    return copy
  }

  public init(_utf8Offset: Int) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
    _rope = nil
  }

  public init(_utf8Offset: Int, utf16TrailingSurrogate: Bool) {
    self.init(_utf8Offset: _utf8Offset)

    if utf16TrailingSurrogate {
      _chunkIndex = _chunkIndex.nextUTF16Trailing
    }
  }

  internal init(
    _utf8Offset: Int,
    utf16TrailingSurrogate: Bool = false,
    _rope: _Rope.Index,
    chunkOffset: Int
  ) {
    self.init(_utf8Offset: _utf8Offset, utf16TrailingSurrogate: utf16TrailingSurrogate)
    _chunkIndex.utf8Offset = chunkOffset
    self._rope = _rope
  }

  internal init(
    baseUTF8Offset: Int,
    _rope: _Rope.Index,
    chunk: BigString._Chunk.Index
  ) {
    self.init(
      _utf8Offset: baseUTF8Offset + Int(chunk.utf8Offset),
      utf16TrailingSurrogate: chunk.isUTF16TrailingSurrogate,
      _rope: _rope,
      chunkOffset: Int(chunk.utf8Offset))
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._orderingValue == right._orderingValue
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._orderingValue < right._orderingValue
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_orderingValue)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Index: CustomStringConvertible {
  public var description: String {
    let utf16Offset = _chunkIndex.isUTF16TrailingSurrogate ? "+1" : ""
    let alignment = _chunkIndex.isKnownCharacterAligned ? "C" : _chunkIndex.isKnownScalarAligned ? "S" : ""
    return "\(utf8Offset)[utf8]\(alignment)\(utf16Offset)"
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  func resolve(_ i: Index, preferEnd: Bool) -> Index {
    if var ri = i._rope, _rope.isValid(ri) {
      if preferEnd {
        guard i.utf8Offset > 0,
              i._chunkIndex.utf8Offset == 0,
              !i._chunkIndex.isUTF16TrailingSurrogate else {
          return i
        }
        _rope.formIndex(before: &ri)
        let length = _rope[ri].utf8Count
        let ci = _Chunk.Index(utf8Offset: length)
        var j = Index(baseUTF8Offset: i.utf8Offset - length, _rope: ri, chunk: ci)
        j._flags = i._flags
        return j
      }
      guard i.utf8Offset < _utf8Count,
            i._chunkIndex.utf8Offset == _rope[ri].utf8Count else {
        return i
      }
      _rope.formIndex(after: &ri)
      let ci = _Chunk.Index(utf8Offset: 0)
      var j = Index(baseUTF8Offset: i.utf8Offset, _rope: ri, chunk: ci)
      j._flags = i._flags
      return j
    }

    // Indices addressing trailing surrogates must never be resolved at the end of chunk,
    // because the +1 doesn't make sense on any endIndex.
    let trailingSurrogate = i._chunkIndex.isUTF16TrailingSurrogate

    let (ri, chunkOffset) = _rope.find(
      at: i.utf8Offset,
      in: _UTF8Metric(),
      preferEnd: preferEnd && !trailingSurrogate)

    let ci = _Chunk.Index(
      utf8Offset: chunkOffset,
      isUTF16TrailingSurrogate: trailingSurrogate)
    return Index(
      baseUTF8Offset: i.utf8Offset - ci.utf8Offset,
      _rope: ri,
      chunk: ci)
  }
}

#endif // compiler(>=6.2)
