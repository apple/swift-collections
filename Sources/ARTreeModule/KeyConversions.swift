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

public protocol ConvertibleToOrderedBytes {
  func toOrderedBytes() -> [UInt8]
  static func fromOrderedBytes(_ bytes: [UInt8]) -> Self
}

///-- Unsigned Integers ------------------------------------------------------//

extension UInt: ConvertibleToOrderedBytes {
  public func toOrderedBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromOrderedBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt16: ConvertibleToOrderedBytes {
  public func toOrderedBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromOrderedBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt32: ConvertibleToOrderedBytes {
  public func toOrderedBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromOrderedBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

extension UInt64: ConvertibleToOrderedBytes {
  public func toOrderedBytes() -> [UInt8] {
    return withUnsafeBytes(of: self.bigEndian, Array.init)
  }

  public static func fromOrderedBytes(_ bytes: [UInt8]) -> Self {
    let ii = bytes.withUnsafeBytes {
        $0.assumingMemoryBound(to: Self.self).baseAddress!.pointee
      }
    return Self(bigEndian: ii)
  }
}

///-- Bytes ------------------------------------------------------------------//

extension [UInt8]: ConvertibleToOrderedBytes {
  public func toOrderedBytes() -> [UInt8] {
    return self
  }

  public static func fromOrderedBytes(_ bytes: [UInt8]) -> Key {
    return bytes
  }
}
