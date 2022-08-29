//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray: Codable {
  /// Encodes this bit array into the given encoder.
  ///
  /// Bit arrays are encoded as an unkeyed container of `UInt` values,
  /// representing the total number of bits in the array, followed by
  /// UInt-sized pieces of the underlying bitmap.
  ///
  /// - Parameter encoder: The encoder to write data to.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(_count)
    for word in _storage {
      try container.encode(word.value)
    }
  }

  /// Creates a new bit array by decoding from the given decoder.
  ///
  /// Bit arrays are encoded as an unkeyed container of `UInt` values,
  /// representing the total number of bits in the array, followed by
  /// UInt-sized pieces of the underlying bitmap.
  ///
  /// - Parameter decoder: The decoder to read data from.
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let count = try container.decode(UInt.self)
    var words: [_Word] = []
    if let c = container.count {
      words.reserveCapacity(c)
    }
    while !container.isAtEnd {
      words.append(_Word(try container.decode(UInt.self)))
    }
    guard
      count <= words.count * _Word.capacity,
      count > (words.count - 1) * _Word.capacity
    else {
      let context = DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Decoded words don't match expected count")
      throw DecodingError.dataCorrupted(context)
    }
    let bit = _BitPosition(count).bit
    if bit > 0, !words.last!.subtracting(_Word(upTo: bit)).isEmpty {
      let context = DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Unexpected bits after end")
      throw DecodingError.dataCorrupted(context)
    }
    self.init(_storage: words, count: count)
  }
}
