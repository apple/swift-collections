//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
import _CollectionsUtilities

/**
 Type alias for _UnsafeBitSet._Word
*/
@usableFromInline
internal typealias _Word = _UnsafeBitSet._Word

/**
 Extension on Array where Element is of type _Word.
*/
extension Array where Element == _Word {
  /**
   Encodes the array of _Word elements as UInt64 and appends to the given container.
   - Parameter container: UnkeyedEncodingContainer to which the encoded elements will be appended.
   - Throws: Any error that may occur during encoding.
  */
  internal func _encodeAsUInt64(to container: inout UnkeyedEncodingContainer) throws {
    // If the capacity of _Word is 64 bits, we can directly encode each word as a UInt64
    if _Word.capacity == 64 {
      for word in self {
        try container.encode(UInt64(truncatingIfNeeded: word.value))
      }
      return
    }
    // If the capacity of _Word is not 64 bits, we assert that it is 32 bits and proceed
    assert(_Word.capacity == 32, "Unsupported platform")
    // We use a variable 'first' to keep track of whether we are encoding the first or second 32 bits of a 64 bit word
    var first = true
    var w: UInt64 = 0
    for word in self {
      if first {
        // If this is the first 32 bits, we store it in 'w'
        w = UInt64(truncatingIfNeeded: word.value)
        first = false
      } else {
        // If this is the second 32 bits, we shift it left by 32 bits and or it with the first 32 bits stored in 'w'
        w |= UInt64(truncatingIfNeeded: word.value) &<< 32
        // We then encode the combined 64 bits and reset 'first'
        try container.encode(w)
        first = true
      }
    }
    // If there is a remaining 32 bits in 'w' that hasn't been encoded, we encode it
    if !first {
      try container.encode(w)
    }
  }

  /**
   Initializes the array of _Word elements from the given container.
   - Parameter container: UnkeyedDecodingContainer from which the elements will be decoded.
   - Parameter count: A hint for the number of elements in the container. This can be used to reserve the capacity of the array, which can improve performance.
   - Throws: Any error that may occur during decoding.
  */
  internal init(_fromUInt64 container: inout UnkeyedDecodingContainer, reservingCount count: Int? = nil) throws {
    // Initialize an empty array
    self = []
    if Element.capacity == 64 {
      // If the capacity of _Word is 64 bits, we can directly decode each word as a UInt64
      if let c = count {
        self.reserveCapacity(c)
      }
      while !container.isAtEnd {
        let v = try container.decode(UInt64.self)
        self.append(Element(UInt(truncatingIfNeeded: v)))
      }
      return
    }
    // If the capacity of _Word is not 64 bits, we assert that it is 32 bits and proceed
    assert(Element.capacity == 32, "Unsupported platform")
if let c = count {
    // If the count parameter is provided, we use it to reserve the capacity of the array
    self.reserveCapacity(2 * c)
}
while !container.isAtEnd {
    // We decode a UInt64 from the container
    let v = try container.decode(UInt64.self)
    // We append the first 32 bits of the UInt64 as a _Word element
    self.append(Element(UInt(truncatingIfNeeded: v)))
    // We append the second 32 bits of the UInt64 as a _Word element
    self.append(Element(UInt(truncatingIfNeeded: v &>> 32)))
    }
}


