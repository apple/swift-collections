//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SparseSet: Encodable where Key: Encodable, Value: Encodable {
  /// Encodes the contents of this sparse set into the given encoder.
  ///
  /// The sparse set's contents are encoded as alternating key-value pairs in
  /// an unkeyed container.
  ///
  /// This function throws an error if any values are invalid for the given
  /// encoder's format.
  ///
  /// - Parameter encoder: The encoder to write data to.
  @inlinable
  public func encode(to encoder: Encoder) throws {
    // Encode contents as an array of alternating key-value pairs.
    var container = encoder.unkeyedContainer()
    for (key, value) in self {
      try container.encode(key)
      try container.encode(value)
    }
  }
}

extension SparseSet: Decodable where Key: Decodable, Value: Decodable {
  /// Creates a new sparse set by decoding from the given decoder.
  ///
  /// `SparseSet` expects its contents to be encoded as alternating
  /// key-value pairs in an unkeyed container.
  ///
  /// This initializer throws an error if reading from the decoder fails, or
  /// if the decoded contents are not in the expected format.
  ///
  /// - Parameter decoder: The decoder to read data from.
  @inlinable
  public init(from decoder: Decoder) throws {
    // We expect to be encoded as an array of alternating key-value pairs.
    var container = try decoder.unkeyedContainer()

    self.init()
    while !container.isAtEnd {
      let key = try container.decode(Key.self)
      let index = _find(key: key)
      guard index == nil else {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Duplicate key at offset \(container.currentIndex - 1)")
        throw DecodingError.dataCorrupted(context)
      }

      guard !container.isAtEnd else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Unkeyed container reached end before value in key-value pair"
          )
        )
      }
      let value = try container.decode(Value.self)
      _append(value: value, key: key)
    }
  }
}
