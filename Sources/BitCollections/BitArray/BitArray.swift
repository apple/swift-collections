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
public struct BitArray: ExpressibleByArrayLiteral, Codable {
  typealias WORD = UInt  // created for experimental purposes to make it easier to test different UInts without having to change much of the code
  
  var storage : [WORD] = []
  var excess: WORD = 0
  
  public init() { }
  
  public init<S>(_ elements: S) where S : Sequence, Bool == S.Element {
    storage.reserveCapacity(elements.underestimatedCount / WORD.bitWidth)
    for value in elements {
      self.append(value)
    }
  }
  
  public init(arrayLiteral elements: Bool...) {
    storage.reserveCapacity(elements.underestimatedCount / WORD.bitWidth)
    for value in elements {
      self.append(value)
    }
  }
  /// Creates a new collection containing the specified number of a single, repeated `Bool`
  ///
  /// The following example creates a BitArray initialized with 5 true values
  ///
  ///     let fiveTrues = BitArray(repeating: true, count: 5)
  ///     print(fiveTrues)
  ///     // Prints "BitArray(storage: [31], excess: 5)"
  ///     print(Array(fiveTrues))
  ///     // Prints "[true, true, true, true, true]"
  ///
  /// - Parameters:
  ///   - repeatedValue: The  `Bool` to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  public init(repeating repeatedValue: Bool, count: Int) {
    precondition(count >= 0, "Count must be greater than or equal to 0")
    if (count == 0) {
      return
    }
    
    if (repeatedValue) {
      let bytes: Int = (Int(count%(WORD.bitWidth)) > 0) ? (count/(WORD.bitWidth))+1 : count/(WORD.bitWidth)
      storage = Array(repeating: WORD.max, count: bytes)
      excess = WORD(count%(WORD.bitWidth))
      
      // flip remaining bits back to 0
      let remaining: Int = (excess == 0) ? WORD.bitWidth : Int(excess)
      for i in remaining..<(WORD.bitWidth) {
        storage[bytes-1] ^= (1<<i)
      }
      
    } else {
      let bytes: Int = (count%(WORD.bitWidth) > 0) ? (count/(WORD.bitWidth))+1 : count/(WORD.bitWidth)
      storage = Array(repeating: 0, count: bytes)
      excess = WORD(count%(WORD.bitWidth))
    }
  }

  #if false
  /// Creates a new BitArray using a BitSet, where the indices in the BitSet become the true values in the BitArray. The resulting BitArray often contains many padded false values at the end from empty bits that fill up the word
  ///
  /// The following example creates a BitArray initialized by a BitSet
  ///     let bitSet: BitSet = [0, 1, 3, 5]
  ///     let bitArray = BitArray(bitSet)
  ///     print(bitArray)
  ///     // Prints "BitArray(storage: [43], excess: 0)"
  ///     print(Array(bitArray))
  ///     // Prints "[true, true, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]"
  ///
  /// - Parameters:
  ///   - bitSet: An initialized BitSet
  public init(_ bitSet: BitSet) {
    storage = bitSet.storage.storage
    excess = bitSet.storage.excess
  }
  #endif
}


