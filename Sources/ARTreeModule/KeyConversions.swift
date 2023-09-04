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
  func toBinaryComparableBytes() -> [UInt8]
  static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self
}

///-- Unsigned Integers ----------------------------------------------------------------------//

extension UInt: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt16: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt32: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt64: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
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
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: _flipSignBit(self).bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

extension Int32: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: _flipSignBit(self).bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

extension Int64: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return withUnsafeBytes(of: _flipSignBit(self).bigEndian, Array.init)
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return _flipSignBit(Self(bigEndian: ii))
  }
}

///-- Bytes ----------------------------------------------------------------------------------//

extension [UInt8]: ConvertibleToBinaryComparableBytes {
  public func toBinaryComparableBytes() -> [UInt8] {
    return self
  }

  public static func fromBinaryComparableBytes(_ bytes: [UInt8]) -> Key {
    return bytes
  }
}
