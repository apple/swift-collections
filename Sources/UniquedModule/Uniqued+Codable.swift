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

extension Uniqued: Encodable where Base: Encodable {
  /// Encodes the elements of this deque into the given encoder in an unkeyed
  /// container.
  ///
  /// This function throws an error if any values are invalid for the given
  /// encoder's format.
  ///
  /// - Parameter encoder: The encoder to write data to.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(_elements)
  }
}

extension Uniqued: Decodable where Base: Decodable {
  /// Creates a new uniqued collection by decoding from the given decoder.
  ///
  /// This initializer throws an error if reading from the decoder fails, or
  /// if the decoded contents contain duplicate values.
  ///
  /// - Parameter decoder: The decoder to read data from.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let elements = try container.decode(Base.self)

    let (storage, end) = _HashTableStorage.create(
      from: elements,
      stoppingOnFirstDuplicateValue: true)
    guard end == elements.endIndex else {
      let offset = elements._offset(of: end)
      let context = DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Decoded elements aren't unique (first duplicate at offset \(offset))")
      throw DecodingError.dataCorrupted(context)
    }
    self.init(
      _uniqueElements: elements,
      storage: elements.count > _UnsafeHashTable.maximumUnhashedCount ? storage : nil)
  }
}
