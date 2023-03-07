//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8)

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct Index: Sendable {
    typealias Rope = _BString.Rope

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
    var _rope: Rope.Index?

    internal init(_raw: UInt64, rope: Rope.Index?) {
      self._rawBits = _raw
      self._rope = rope
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index {
  @inline(__always)
  internal static func _bitsForUTF8Offset(_ utf8Offset: Int) -> UInt64 {
    let v = UInt64(truncatingIfNeeded: UInt(bitPattern: utf8Offset))
    assert(v &>> 53 == 0)
    return v &<< 11
  }

  @inline(__always)
  internal static var _flagsMask: UInt64 { 0x700 }

  @inline(__always)
  internal static var _utf16TrailingSurrogateBits: UInt64 { 0x400 }

  @inline(__always)
  internal static var _characterAlignmentBits: UInt64 { 0x300 }

  @inline(__always)
  internal static var _scalarAlignmentBits: UInt64 { 0x100 }

  internal var _utf8Offset: Int {
    Int(truncatingIfNeeded: _rawBits &>> 11)
  }

  @inline(__always)
  internal var _orderingValue: UInt64 {
    _rawBits &>> 10
  }

  /// The offset within the addressed chunk. Only valid if `_rope` is not nil.
  internal var _utf8ChunkOffset: Int {
    assert(_rope != nil)
    return Int(truncatingIfNeeded: _rawBits & 0xFF)
  }

  /// The base offset of the addressed chunk. Only valid if `_rope` is not nil.
  internal var _utf8BaseOffset: Int {
    _utf8Offset - _utf8ChunkOffset
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

extension String.Index {
  @available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
  func _copyingAlignmentBits(from i: _BString.Index) -> String.Index {
    var bits = _abi_rawBits & ~3
    bits |= (i._flags &>> 8) & 3
    return String.Index(_rawBits: bits)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index {
  internal var _chunkIndex: String.Index {
    assert(_rope != nil)
    return String.Index(
      _utf8Offset: _utf8ChunkOffset, utf16TrailingSurrogate: _isUTF16TrailingSurrogate
    )._copyingAlignmentBits(from: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index {
  internal mutating func _clearUTF16TrailingSurrogate() {
    _flags = 0
  }

  internal var _isUTF16TrailingSurrogate: Bool {
    _orderingValue & 1 != 0
  }

  internal func _knownScalarAligned() -> Self {
    var copy = self
    copy._flags = Self._scalarAlignmentBits
    return copy
  }

  internal func _knownCharacterAligned() -> Self {
    var copy = self
    copy._flags = Self._characterAlignmentBits
    return copy
  }

  internal var _isKnownScalarAligned: Bool {
    _rawBits & Self._scalarAlignmentBits != 0
  }

  internal var _isKnownCharacterAligned: Bool {
    _rawBits & Self._characterAlignmentBits != 0
  }

  internal init(_utf8Offset: Int) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
    _rope = nil
  }

  internal init(_utf8Offset: Int, utf16TrailingSurrogate: Bool) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
    if utf16TrailingSurrogate {
      _rawBits |= Self._utf16TrailingSurrogateBits
    }
    _rope = nil
  }

  internal init(
    _utf8Offset: Int, utf16TrailingSurrogate: Bool = false, rope: Rope.Index, chunkOffset: Int
  ) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
    if utf16TrailingSurrogate {
      _rawBits |= Self._utf16TrailingSurrogateBits
    }
    assert(chunkOffset >= 0 && chunkOffset <= 0xFF)
    _rawBits |= UInt64(truncatingIfNeeded: chunkOffset) & 0xFF
    self._rope = rope
  }

  internal init(baseUTF8Offset: Int, rope: Rope.Index, chunk: String.Index) {
    let chunkUTF8Offset = chunk._utf8Offset
    self.init(
      _utf8Offset: baseUTF8Offset + chunkUTF8Offset,
      utf16TrailingSurrogate: chunk._isUTF16TrailingSurrogate,
      rope: rope,
      chunkOffset: chunkUTF8Offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._orderingValue == right._orderingValue
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Comparable {
  static func <(left: Self, right: Self) -> Bool {
    left._orderingValue < right._orderingValue
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(_orderingValue)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: CustomStringConvertible {
  internal var description: String {
    let utf16Offset = _isUTF16TrailingSurrogate ? "+1" : ""
    return "\(_utf8Offset)[utf8]\(utf16Offset)"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func resolve(_ i: Index, preferEnd: Bool) -> Index {
    if var ri = i._rope, rope.isValid(ri) {
      if preferEnd {
        guard i._utf8ChunkOffset == 0, i._utf8Offset > 0 else { return i }
        rope.formIndex(before: &ri)
        let length = rope[ri].utf8Count
        let ci = String.Index(_utf8Offset: length)
        var j = Index(baseUTF8Offset: i._utf8Offset - length, rope: ri, chunk: ci)
        j._flags = i._flags
        return j
      }
      guard i._utf8ChunkOffset == rope[ri].utf8Count else { return i }
      rope.formIndex(after: &ri)
      let ci = String.Index(_utf8Offset: 0)
      var j = Index(baseUTF8Offset: i._utf8Offset, rope: ri, chunk: ci)
      j._flags = i._flags
      return j
    }

    let (ri, chunkOffset) = rope.find(
      at: i._utf8Offset, in: UTF8Metric(), preferEnd: preferEnd)
    let ci = String.Index(
        _utf8Offset: chunkOffset, utf16TrailingSurrogate: i._isUTF16TrailingSurrogate)
    return Index(baseUTF8Offset: i._utf8Offset - ci._utf8Offset, rope: ri, chunk: ci)
  }
}
#endif
