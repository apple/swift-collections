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

extension BitArray: LosslessStringConvertible {
  /// Initializes a new bit array from a string representation.
  ///
  /// The string given is interpreted as if it was the binary representation
  /// of an integer value, consisting of the digits `0` and `1`, with the
  /// highest digits appearing first.
  ///
  ///     BitArray("") // []
  ///     BitArray("001") // [true, false, false]
  ///     BitArray("1110") // [false, true, true, true]
  ///     BitArray("42") // nil
  ///     BitArray("Foo") // nil
  ///
  public init?(_ description: String) {
    let bits: BitArray? = description.utf8.withContiguousStorageIfAvailable { buffer in
      Self(_utf8: buffer)
    } ?? Self(_utf8: description.utf8)
    guard let bits = bits else {
      return nil
    }
    self = bits
  }

  internal init?<C: Collection>(_utf8 utf8: C) where C.Element == UInt8 {
    let c = utf8.count
    self.init(repeating: false, count: c)
    var i = c &- 1
    let success = _update { handle in
      for byte in utf8 {
        if byte == ._ascii1 {
          handle.set(at: i)
        } else {
          guard byte == ._ascii0 else { return false }
        }
        i &-= 1
      }
      return true
    }
    guard success else { return nil }
  }
}
