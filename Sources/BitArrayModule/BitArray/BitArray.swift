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
  
  public init(repeating repeatedValue: Bool, count: Int) {
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
  
  public init(_ bitSet: BitSet) {
    storage = bitSet.storage.storage
    excess = bitSet.storage.excess
  }
  
}


