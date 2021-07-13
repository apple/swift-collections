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

extension SortedDictionary: Encodable where Key: Codable, Value: Codable {
  /// Encodes the contents of this dictionary into the given encoder.
  ///
  /// The dictionary's contents are encoded as alternating key-value pairs in
  /// an unkeyed container.
  ///
  /// This function throws an error if any values are invalid for the given
  /// encoder's format.
  ///
  /// - Note: Unlike the standard `Dictionary` type, sorted dictionaries
  ///    always encode themselves into an unkeyed container, because
  ///    `Codable`'s keyed containers do not guarantee that they preserve the
  ///    ordering of the items they contain. (And in popular encoding formats,
  ///    keyed containers tend to map to unordered data structures -- e.g.,
  ///    JSON's "object" construct is explicitly unordered.)
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

extension SortedDictionary: Decodable where Key: Decodable, Value: Decodable {
  @inlinable
  public init(from decoder: Decoder) throws {
    // We expect to be encoded as an array of alternating key-value pairs.
    var container = try decoder.unkeyedContainer()

    self.init()
    while !container.isAtEnd {
      let key = try container.decode(Key.self)
      
      guard !container.isAtEnd else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Unkeyed container reached end before value in key-value pair"
          )
        )
      }
      
      let value = try container.decode(Value.self)
      let oldValue = self.updateValue(value, forKey: key)
      if oldValue != nil {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Duplicate key at offset \(container.currentIndex - 1)")
        throw DecodingError.dataCorrupted(context)
      }
    }
  }
}
