//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension UInt8 {
  @inline(__always)
  internal static var _ascii0: Self { 48 }

  @inline(__always)
  internal static var _ascii1: Self { 49 }
}

extension BitArray: CustomStringConvertible {
  /// A textual representation of this instance.
  /// Bit arrays print themselves as a string of binary bits, with the highest-indexed elements
  /// appearing first, as in the binary representation of integers:
  ///
  ///     let bits: BitArray = [false, false, false, true, true]
  ///     print(bits) // "11000"
  ///
  /// The description of an empty bit array is an empty string.
  public var description: String {
    _bitString
  }
}

extension BitArray: CustomDebugStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  ///
  /// Bit arrays print themselves as a string of binary bits, with the highest-indexed elements
  /// appearing first, as in the binary representation of integers:
  ///
  ///     let bits: BitArray = [false, false, false, true, true]
  ///     print(bits) // "11000"
  ///
  /// As a special case, the debug description of an empty bit array is an empty pair of brackets.
  /// This makes this case read better in structured printouts, like when the `BitArray` is printed
  /// as part of another collection value:
  ///
  ///     let list: [BitArray] = [[false, true], [], [false]]
  ///     print(list) // "[10, [], 0]"
  ///
  public var debugDescription: String {
    guard !isEmpty else { return "[]" }
    return description
  }
}

extension BitArray {
  internal var _bitString: String {
    guard !isEmpty else { return "" }
    var result: String
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      result = String(unsafeUninitializedCapacity: self.count) { target in
        var i = count - 1
        for v in self {
          target.initializeElement(at: i, to: v ? ._ascii1 : ._ascii0)
          i &-= 1
        }
        return count
      }
    } else {
      result = ""
      result.reserveCapacity(self.count)
      for v in self.reversed() {
        result.append(v ? "1" : "0")
      }
    }
    return result
  }
}
