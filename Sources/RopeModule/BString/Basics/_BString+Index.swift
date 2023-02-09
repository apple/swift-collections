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
  internal struct Index {
    // The layout is similar to (and somewhat compatible with) String.Index.
    // ┌──────────┬────────────────┬───────────────────────┐
    // │ b63:b16  │      b15:b14   │     b13:b0            │
    // ├──────────┼────────────────┼───────────────────────┤
    // │ position │ transc. offset │ reserved              │
    // └──────────┴────────────────┴───────────────────────┘
    
    internal var _rawBits: UInt64
    
    internal init(_raw: UInt64) {
      self._rawBits = _raw
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index {
  @inline(__always)
  internal var _orderingValue: UInt64 {
    _rawBits &>> 14
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    left._orderingValue == right._orderingValue
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Comparable {
  internal static func <(left: Self, right: Self) -> Bool {
    left._orderingValue < right._orderingValue
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: Hashable {
  internal func hash(into hasher: inout Hasher) {
    hasher.combine(_orderingValue)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index: CustomStringConvertible {
  internal var description: String {
    let offset = _utf16Delta == 0 ? "" : "+\(_utf16Delta)"
    return "\(_utf8Offset)[utf8]\(offset)"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Index {
  @inline(__always)
  internal static func _bitsForUTF8Offset(_ utf8Offset: Int) -> UInt64 {
    let v = UInt64(truncatingIfNeeded: UInt(bitPattern: utf8Offset))
    assert(v &>> 48 == 0)
    return v &<< 16
  }
  
  @inline(__always)
  internal static func _bitsForUTF16Delta(_ utf16Delta: Int) -> UInt64 {
    let v = UInt64(truncatingIfNeeded: UInt(bitPattern: utf16Delta))
    assert(v == v & 1)
    return (v & 1) &<< 14
  }
  
  internal init(_utf8Offset: Int) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
  }
  
  internal init(_utf8Offset: Int, utf16Delta: Int) {
    _rawBits = Self._bitsForUTF8Offset(_utf8Offset)
    _rawBits |= Self._bitsForUTF16Delta(utf16Delta)
  }
  
  internal var _utf8Offset: Int {
    Int(truncatingIfNeeded: _rawBits &>> 16)
  }
  
  internal var _utf16Delta: Int {
    Int(truncatingIfNeeded: _orderingValue & 0x3)
  }

  internal func _advanceUTF8(by delta: Int) -> Self {
    Self(_utf8Offset: _utf8Offset + delta)
  }
}

#endif
