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

extension SortedSet: Encodable where Element: Encodable {
  /// Encodes the elements of this ordered set into the given encoder.
  ///
  /// - Parameter encoder: The encoder to write data to.
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for element in self {
      try container.encode(element)
    }
  }
}

extension SortedSet: Decodable where Element: Decodable {
  /// Creates a new ordered set by decoding from the given decoder.
  ///
  /// This initializer throws an error if reading from the decoder fails, or
  /// if the decoded contents contain duplicate values.
  ///
  /// - Parameter decoder: The decoder to read data from.
  @inlinable
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    self.init()
    while !container.isAtEnd {
      let element = try container.decode(Element.self)
      let (inserted, _) = self.insert(element)
      if !inserted {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Duplicate key at offset \(container.currentIndex - 1)")
        throw DecodingError.dataCorrupted(context)
      }
    }
  }
}
