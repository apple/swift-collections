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

#if compiler(>=6.2) && !$Embedded

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  struct Index {
    var _utf8Offset: UInt8

    // ┌──────────────────┬───┬───────────┐
    // │ b7:b3            │b2 │ b1:b0     │
    // ├──────────────────┼───┼───────────┤
    // │ Unused           │ T │ alignment │
    // └──────────────────┴───┴───────────┘
    // b2 (T): UTF-16 trailing surrogate indicator
    // b1: isCharacterAligned
    // b0: isScalarAligned
    var flags: UInt8 = 0

    init(_ bits: UInt16) {
      _utf8Offset = UInt8(truncatingIfNeeded: bits & 0xFF)
      flags = UInt8(truncatingIfNeeded: bits &>> 8)
    }

    init(utf8Offset: Int, isUTF16TrailingSurrogate: Bool = false) {
      assert((UInt8.min...UInt8.max).contains(UInt8(utf8Offset)))
      _utf8Offset = UInt8(truncatingIfNeeded: utf8Offset)

      if isUTF16TrailingSurrogate {
        flags |= Self.utf16TrailingSurrogateBit
      }
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk.Index {
  @inline(__always)
  static var utf16TrailingSurrogateBit: UInt8 { 0x4 }

  @inline(__always)
  static var characterAlignmentBit: UInt8 { 0x2 }

  @inline(__always)
  static var scalarAlignmentBit: UInt8 { 0x1 }

  var isUTF16TrailingSurrogate: Bool {
    flags & Self.utf16TrailingSurrogateBit != 0
  }

  var isKnownCharacterAligned: Bool {
    flags & Self.characterAlignmentBit != 0
  }

  var isKnownScalarAligned: Bool {
    flags & Self.scalarAlignmentBit != 0
  }

  var characterAligned: Self {
    var copy = self
    copy.flags = Self.characterAlignmentBit | Self.scalarAlignmentBit
    return copy
  }

  var scalarAligned: Self {
    var copy = self
    copy.flags = Self.scalarAlignmentBit
    return copy
  }

  var utf8Offset: Int {
    get {
      Int(_utf8Offset)
    }

    set {
      assert((UInt8.min...UInt8.max).contains(UInt8(newValue)))
      _utf8Offset = UInt8(truncatingIfNeeded: newValue)
    }
  }

  var nextUTF16Trailing: Self {
    Self(utf8Offset: utf8Offset, isUTF16TrailingSurrogate: true)
  }

  var stripUTF16Trailing: Self {
    Self(utf8Offset: utf8Offset)
  }

  func offset(by len: Int) -> Self {
    Self(utf8Offset: utf8Offset + len)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk.Index: Equatable {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset &&
    lhs.isUTF16TrailingSurrogate == rhs.isUTF16TrailingSurrogate
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk.Index: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(utf8Offset)
    hasher.combine(isUTF16TrailingSurrogate)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk.Index: Comparable {
  static func <(lhs: Self, rhs: Self) -> Bool {
    switch (lhs.isUTF16TrailingSurrogate, rhs.isUTF16TrailingSurrogate) {
    case (false, false),
         (true, false),
         (true, true):
      return lhs.utf8Offset < rhs.utf8Offset
    case (false, true):
      return lhs.utf8Offset <= rhs.utf8Offset
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk.Index: CustomStringConvertible {
  public var description: String {
    let utf16Offset = isUTF16TrailingSurrogate ? "+1" : ""
    let alignment = isKnownCharacterAligned ? "C" : isKnownScalarAligned ? "S" : ""
    return "\(utf8Offset)[utf8]\(alignment)\(utf16Offset)"
  }
}

#endif // compiler(>=6.2) && !$Embedded
