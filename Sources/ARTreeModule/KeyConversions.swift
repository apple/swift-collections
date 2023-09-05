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

public protocol ConvertibleToBinaryComparableBytes {
  func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
  static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self
}

extension ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    self.withUnsafeBinaryComparableBytes { Array($0) }
  }
}

///-- Unsigned Integers ----------------------------------------------------------------------//

extension UInt: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try withUnsafeBytes(of: self.bigEndian) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt16: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try withUnsafeBytes(of: self.bigEndian) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt32: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try withUnsafeBytes(of: self.bigEndian) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt64: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try withUnsafeBytes(of: self.bigEndian) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

///-- Signed Integers ------------------------------------------------------------------------//

fileprivate func _flipSignBit<T: SignedInteger & FixedWidthInteger>(_ val: T) -> T {
  return val ^ (1 << (T.bitWidth - 1))
}

extension Int: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    let ii = _flipSignBit(self).bigEndian
    return try withUnsafeBytes(of: ii) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

extension Int32: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    let ii = _flipSignBit(self).bigEndian
    return try withUnsafeBytes(of: ii) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

extension Int64: ConvertibleToBinaryComparableBytes {
  public func withUnsafeBinaryComparableBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    let ii = _flipSignBit(self).bigEndian
    return try withUnsafeBytes(of: ii) {
      try body($0)
    }
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

///-- String ---------------------------------------------------------------------------------//

// extension String: ConvertibleToBinaryComparableBytes {
//   public func toBinaryComparableBytes() -> [UInt8] {
//     return self.withUnsafe
//   }

//   public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Key {
//     return bytes
//   }
// }

///-- Bytes ----------------------------------------------------------------------------------//

// TODO: Disable until, we support storing bytes with shared prefixes.
// extension [UInt8]: ConvertibleToBinaryComparableBytes {
//   public func toBinaryComparableBytes() -> [UInt8] {
//     return self
//   }

//   public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Key {
//     return bytes
//   }
// }
