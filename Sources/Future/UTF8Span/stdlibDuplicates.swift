/*

 Duplicates of functions currently in the stdlib

 */


import Builtin

@inlinable @inline(__always)
internal func _utf8ScalarLength(_ x: UInt8) -> Int {
  _internalInvariant(!UTF8.isContinuation(x))
  if UTF8.isASCII(x) { return 1 }
  // TODO(String micro-performance): check codegen
  return (~x).leadingZeroBitCount
}

@usableFromInline @_transparent
internal func _internalInvariant(
  _ condition: @autoclosure () -> Bool,
  _ message: @autoclosure () -> String = String(),
  file: StaticString = #file, line: UInt = #line
) {
  assert(condition(), message())
}

@inlinable
@inline(__always)
internal func _decodeUTF8(_ x: UInt8) -> Unicode.Scalar {
  _internalInvariant(UTF8.isASCII(x))
  return Unicode.Scalar(_unchecked: UInt32(x))
}

@inlinable
@inline(__always)
internal func _decodeUTF8(_ x: UInt8, _ y: UInt8) -> Unicode.Scalar {
  _internalInvariant(_utf8ScalarLength(x) == 2)
  _internalInvariant(UTF8.isContinuation(y))
  let x = UInt32(x)
  let value = ((x & 0b0001_1111) &<< 6) | _continuationPayload(y)
  return Unicode.Scalar(_unchecked: value)
}

@inlinable
@inline(__always)
internal func _decodeUTF8(
  _ x: UInt8, _ y: UInt8, _ z: UInt8
) -> Unicode.Scalar {
  _internalInvariant(_utf8ScalarLength(x) == 3)
  _internalInvariant(UTF8.isContinuation(y) && UTF8.isContinuation(z))
  let x = UInt32(x)
  let value = ((x & 0b0000_1111) &<< 12)
            | (_continuationPayload(y) &<< 6)
            | _continuationPayload(z)
  return Unicode.Scalar(_unchecked: value)
}

@inlinable
@inline(__always)
internal func _decodeUTF8(
  _ x: UInt8, _ y: UInt8, _ z: UInt8, _ w: UInt8
) -> Unicode.Scalar {
  _internalInvariant(_utf8ScalarLength(x) == 4)
  _internalInvariant(
    UTF8.isContinuation(y) && UTF8.isContinuation(z)
    && UTF8.isContinuation(w))
  let x = UInt32(x)
  let value = ((x & 0b0000_1111) &<< 18)
            | (_continuationPayload(y) &<< 12)
            | (_continuationPayload(z) &<< 6)
            | _continuationPayload(w)
  return Unicode.Scalar(_unchecked: value)
}

@inlinable
@inline(__always)
internal func _continuationPayload(_ x: UInt8) -> UInt32 {
  return UInt32(x & 0x3F)
}

extension Unicode.Scalar {
  @inlinable
  init(_unchecked value: UInt32) {
    // Hacked together
    self = Builtin.reinterpretCast(value)
  }
}

@inlinable @inline(__always)
internal func _utf8ScalarLength(
  _ utf8: UnsafeBufferPointer<UInt8>, endingAt i: Int
  ) -> Int {
  var len = 1
  while UTF8.isContinuation(utf8[i &- len]) {
    len &+= 1
  }
  _internalInvariant(len == _utf8ScalarLength(utf8[i &- len]))
  return len
}


internal func _quickHasGraphemeBreakBetween(
  _ lhs: Unicode.Scalar, _ rhs: Unicode.Scalar
) -> Bool {

  // CR-LF is a special case: no break between these
  if lhs == Unicode.Scalar(_CR) && rhs == Unicode.Scalar(_LF) {
    return false
  }

  // Whether the given scalar, when it appears paired with another scalar
  // satisfying this property, has a grapheme break between it and the other
  // scalar.
  func hasBreakWhenPaired(_ x: Unicode.Scalar) -> Bool {
    // TODO: This doesn't generate optimal code, tune/re-write at a lower
    // level.
    //
    // NOTE: Order of case ranges affects codegen, and thus performance. All
    // things being equal, keep existing order below.
    switch x.value {
    // Unified CJK Han ideographs, common and some supplemental, amongst
    // others:
    //   U+3400 ~ U+A4CF
    case 0x3400...0xa4cf: return true

    // Repeat sub-300 check, this is beneficial for common cases of Latin
    // characters embedded within non-Latin script (e.g. newlines, spaces,
    // proper nouns and/or jargon, punctuation).
    //
    // NOTE: CR-LF special case has already been checked.
    case 0x0000...0x02ff: return true

    // Non-combining kana:
    //   U+3041 ~ U+3096
    //   U+30A1 ~ U+30FC
    case 0x3041...0x3096: return true
    case 0x30a1...0x30fc: return true

    // Non-combining modern (and some archaic) Cyrillic:
    //   U+0400 ~ U+0482 (first half of Cyrillic block)
    case 0x0400...0x0482: return true

    // Modern Arabic, excluding extenders and prependers:
    //   U+061D ~ U+064A
    case 0x061d...0x064a: return true

    // Precomposed Hangul syllables:
    //   U+AC00 ~ U+D7AF
    case 0xac00...0xd7af: return true

    // Common general use punctuation, excluding extenders:
    //   U+2010 ~ U+2029
    case 0x2010...0x2029: return true

    // CJK punctuation characters, excluding extenders:
    //   U+3000 ~ U+3029
    case 0x3000...0x3029: return true

    // Full-width forms:
    //   U+FF01 ~ U+FF9D
    case 0xFF01...0xFF9D: return true

    default: return false
    }
  }
  return hasBreakWhenPaired(lhs) && hasBreakWhenPaired(rhs)
}


private var _CR: UInt8 { return 0x0d }
private var _LF: UInt8 { return 0x0a }

internal func _allASCII(_ input: UnsafeBufferPointer<UInt8>) -> Bool {
  if input.isEmpty { return true }

  // NOTE: Avoiding for-in syntax to avoid bounds checks
  //
  // TODO(String performance): SIMD-ize
  //
  let count = input.count
  var ptr = UnsafeRawPointer(input.baseAddress._unsafelyUnwrappedUnchecked)

  let asciiMask64 = 0x8080_8080_8080_8080 as UInt64
  let asciiMask32 = UInt32(truncatingIfNeeded: asciiMask64)
  let asciiMask16 = UInt16(truncatingIfNeeded: asciiMask64)
  let asciiMask8 = UInt8(truncatingIfNeeded: asciiMask64)

  let end128 = ptr + count & ~(MemoryLayout<(UInt64, UInt64)>.stride &- 1)
  let end64 = ptr + count & ~(MemoryLayout<UInt64>.stride &- 1)
  let end32 = ptr + count & ~(MemoryLayout<UInt32>.stride &- 1)
  let end16 = ptr + count & ~(MemoryLayout<UInt16>.stride &- 1)
  let end = ptr + count


  while ptr < end128 {
    let pair = ptr.loadUnaligned(as: (UInt64, UInt64).self)
    let result = (pair.0 | pair.1) & asciiMask64
    guard result == 0 else { return false }
    ptr = ptr + MemoryLayout<(UInt64, UInt64)>.stride
  }

  // If we had enough bytes for two iterations of this, we would have hit
  // the loop above, so we only need to do this once
  if ptr < end64 {
    let value = ptr.loadUnaligned(as: UInt64.self)
    guard value & asciiMask64 == 0 else { return false }
    ptr = ptr + MemoryLayout<UInt64>.stride
  }

  if ptr < end32 {
    let value = ptr.loadUnaligned(as: UInt32.self)
    guard value & asciiMask32 == 0 else { return false }
    ptr = ptr + MemoryLayout<UInt32>.stride
  }

  if ptr < end16 {
    let value = ptr.loadUnaligned(as: UInt16.self)
    guard value & asciiMask16 == 0 else { return false }
    ptr = ptr + MemoryLayout<UInt16>.stride
  }

  if ptr < end {
    let value = ptr.loadUnaligned(fromByteOffset: 0, as: UInt8.self)
    guard value & asciiMask8 == 0 else { return false }
  }
  _internalInvariant(ptr == end || ptr + 1 == end)
  return true
}


extension Optional {
  /// - Returns: `unsafelyUnwrapped`.
  ///
  /// This version is for internal stdlib use; it avoids any checking
  /// overhead for users, even in Debug builds.
  @inlinable
  internal var _unsafelyUnwrappedUnchecked: Wrapped {
    @inline(__always)
    get {
      if let x = self {
        return x
      }
      _internalInvariant(false, "_unsafelyUnwrappedUnchecked of nil optional")
    }
  }
}

extension Unicode.Scalar {
  internal static var _replacementCharacter: Unicode.Scalar {
    return Unicode.Scalar(_unchecked: 0xFFFD)
  }
}

