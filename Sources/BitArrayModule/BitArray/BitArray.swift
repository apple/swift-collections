//
//  BitArray.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray: ExpressibleByArrayLiteral {
  typealias WORD = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
  
  // Will start off storing elements little-endian just because I have a hunch the calculations might be cleaner
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
    storage.reserveCapacity(elements.underestimatedCount / WORD.bitWidth) // for this, why not just use count?
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
