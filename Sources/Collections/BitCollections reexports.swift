//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import BitCollections

public typealias BitSet = BitCollections.BitSet
public typealias BitArray = BitCollections.BitArray

extension BinaryInteger {
  /// Creates a new instance by truncating or extending the bits in the given
  /// bit array, as needed. The bit at position 0 in `source` will correspond
  /// to the least-significant bit in the result.
  ///
  /// If `Self` is an unsigned integer type, then the result will contain as
  /// many bits from `source` it can accommodate, truncating off any extras.
  ///
  ///     UInt8(truncatingIfNeeded: "" as BitArray) // 0
  ///     UInt8(truncatingIfNeeded: "0" as BitArray) // 0
  ///     UInt8(truncatingIfNeeded: "1" as BitArray) // 1
  ///     UInt8(truncatingIfNeeded: "11" as BitArray) // 3
  ///     UInt8(truncatingIfNeeded: "11111111" as BitArray) // 255
  ///     UInt8(truncatingIfNeeded: "1100000001" as BitArray) // 1
  ///     UInt8(truncatingIfNeeded: "1100000101" as BitArray) // 5
  ///
  /// If `Self` is a signed integer type, then the contents of the bit array
  /// are interpreted to be a two's complement representation of a signed
  /// integer value, with the last bit in the array representing the sign of
  /// the result.
  ///
  ///     Int8(truncatingIfNeeded: "" as BitArray) // 0
  ///     Int8(truncatingIfNeeded: "0" as BitArray) // 0
  ///     Int8(truncatingIfNeeded: "1" as BitArray) // -1
  ///     Int8(truncatingIfNeeded: "01" as BitArray) // 1
  ///     Int8(truncatingIfNeeded: "101" as BitArray) // -3
  ///     Int8(truncatingIfNeeded: "0101" as BitArray) // 5
  ///
  ///     Int8(truncatingIfNeeded: "00000001" as BitArray) // 1
  ///     Int8(truncatingIfNeeded: "00000101" as BitArray) // 5
  ///     Int8(truncatingIfNeeded: "01111111" as BitArray) // 127
  ///     Int8(truncatingIfNeeded: "10000000" as BitArray) // -128
  ///     Int8(truncatingIfNeeded: "11111111" as BitArray) // -1
  ///
  ///     Int8(truncatingIfNeeded: "000011111111" as BitArray) // -1
  ///     Int8(truncatingIfNeeded: "111100000000" as BitArray) // 0
  ///     Int8(truncatingIfNeeded: "111100000001" as BitArray) // 1
  @inlinable
  @inline(__always)
  public init(truncatingIfNeeded source: BitArray) {
    self = source._convertTruncating(to: Self.self)
  }
  
  /// Creates a new instance from the bits in the given bit array, if the
  /// corresponding integer value can be represented exactly.
  /// If the value is not representable exactly, then the result is `nil`.
  ///
  /// If `Self` is an unsigned integer type, then the contents of the bit array
  /// are interpreted to be the binary representation of a nonnegative
  /// integer value. The bit array is allowed to contain bits in unrepresentable
  /// positions, as long as they are all cleared.
  ///
  ///     UInt8(exactly: "" as BitArray) // 0
  ///     UInt8(exactly: "0" as BitArray) // 0
  ///     UInt8(exactly: "1" as BitArray) // 1
  ///     UInt8(exactly: "10" as BitArray) // 2
  ///     UInt8(exactly: "00000000" as BitArray) // 0
  ///     UInt8(exactly: "11111111" as BitArray) // 255
  ///     UInt8(exactly: "0000000000000" as BitArray) // 0
  ///     UInt8(exactly: "0000011111111" as BitArray) // 255
  ///     UInt8(exactly: "0000100000000" as BitArray) // nil
  ///     UInt8(exactly: "1111111111111" as BitArray) // nil
  ///
  /// If `Self` is a signed integer type, then the contents of the bit array
  /// are interpreted to be a two's complement representation of a signed
  /// integer value, with the last bit in the array representing the sign of
  /// the result.
  ///
  ///     Int8(exactly: "" as BitArray) // 0
  ///     Int8(exactly: "0" as BitArray) // 0
  ///     Int8(exactly: "1" as BitArray) // -1
  ///     Int8(exactly: "01" as BitArray) // 1
  ///     Int8(exactly: "101" as BitArray) // -3
  ///     Int8(exactly: "0101" as BitArray) // 5
  ///
  ///     Int8(exactly: "00000001" as BitArray) // 1
  ///     Int8(exactly: "00000101" as BitArray) // 5
  ///     Int8(exactly: "01111111" as BitArray) // 127
  ///     Int8(exactly: "10000000" as BitArray) // -128
  ///     Int8(exactly: "11111111" as BitArray) // -1
  ///
  ///     Int8(exactly: "00000000000" as BitArray) // 0
  ///     Int8(exactly: "00001111111" as BitArray) // 127
  ///     Int8(exactly: "00010000000" as BitArray) // nil
  ///     Int8(exactly: "11101111111" as BitArray) // nil
  ///     Int8(exactly: "11110000000" as BitArray) // -128
  ///     Int8(exactly: "11111111111" as BitArray) // -1
  @inlinable
  @inline(__always)
  public init?(exactly source: BitArray) {
    guard let v = source._convertExactly(to: Self.self) else { return nil }
    self = v
  }

  /// Creates a new instance from the bits in the given bit array, if the
  /// corresponding integer value can be represented exactly.
  /// If the value is not representable exactly, then a runtime error will
  /// occur.
  ///
  /// If `Self` is an unsigned integer type, then the contents of the bit array
  /// are interpreted to be the binary representation of a nonnegative
  /// integer value. The bit array is allowed to contain bits in unrepresentable
  /// positions, as long as they are all cleared.
  ///
  ///     UInt8("" as BitArray) // 0
  ///     UInt8("0" as BitArray) // 0
  ///     UInt8("1" as BitArray) // 1
  ///     UInt8("10" as BitArray) // 2
  ///     UInt8("00000000" as BitArray) // 0
  ///     UInt8("11111111" as BitArray) // 255
  ///     UInt8("0000000000000" as BitArray) // 0
  ///     UInt8("0000011111111" as BitArray) // 255
  ///     UInt8("0000100000000" as BitArray) // ERROR
  ///     UInt8("1111111111111" as BitArray) // ERROR
  ///
  /// If `Self` is a signed integer type, then the contents of the bit array
  /// are interpreted to be a two's complement representation of a signed
  /// integer value, with the last bit in the array representing the sign of
  /// the result.
  ///
  ///     Int8("" as BitArray) // 0
  ///     Int8("0" as BitArray) // 0
  ///     Int8("1" as BitArray) // -1
  ///     Int8("01" as BitArray) // 1
  ///     Int8("101" as BitArray) // -3
  ///     Int8("0101" as BitArray) // 5
  ///
  ///     Int8("00000001" as BitArray) // 1
  ///     Int8("00000101" as BitArray) // 5
  ///     Int8("01111111" as BitArray) // 127
  ///     Int8("10000000" as BitArray) // -128
  ///     Int8("11111111" as BitArray) // -1
  ///
  ///     Int8("00000000000" as BitArray) // 0
  ///     Int8("00001111111" as BitArray) // 127
  ///     Int8("00010000000" as BitArray) // ERROR
  ///     Int8("11101111111" as BitArray) // ERROR
  ///     Int8("11110000000" as BitArray) // -128
  ///     Int8("11111111111" as BitArray) // -1
  @inlinable
  @inline(__always)
  public init(_ source: BitArray) {
    self = source._convertForced(to: Self.self)
  }
}

#endif
