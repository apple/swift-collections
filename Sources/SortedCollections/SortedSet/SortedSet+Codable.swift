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

#if !$Embedded
extension SortedSet: Encodable where Element: Encodable {
  /// Encodes the elements of this ordered set into the given encoder.
  ///
  /// - Parameter encoder: The encoder to write data to.
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try self.forEach { element in
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
    var builder = _Tree.Builder(deduplicating: true)
    var previousElement: Element? = nil
    
    while !container.isAtEnd {
      let element = try container.decode(Element.self)
      guard previousElement == nil || previousElement! < element else {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Decoded elements out of order.")
        throw DecodingError.dataCorrupted(context)
      }
      builder.append(element)
      previousElement = element
    }
    
    self.init(_rootedAt: builder.finish())
  }
}
#endif
