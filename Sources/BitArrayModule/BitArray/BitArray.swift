//
//  BitArray.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray {
  typealias UNIT = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
  
  // Will start off storing elements little-endian just because I have a hunch the calculations might be cleaner
  var storage : [UNIT] = []
  var excess: UInt8 = 0
  
  public init() { }
  
  public init<S>(_ elements: S) where S : Sequence, Bool == S.Element {
    storage.reserveCapacity(elements.underestimatedCount / UNIT.bitWidth)
    for value in elements {
        self.append(value)
    }
  }
  
  public init(arrayLiteral elements: Bool...) {
    storage.reserveCapacity(elements.underestimatedCount / UNIT.bitWidth) // for this, why not just use count?
    for value in elements {
        self.append(value)
    }
  }
  
  public init(repeating repeatedValue: Bool, count: Int) {
    if (count == 0) {
      return
    }
    
    if (repeatedValue) {
      let bytes: Int = (Int(count%(UNIT.bitWidth)) > 0) ? (count/(UNIT.bitWidth))+1 : count/(UNIT.bitWidth)
      storage = Array(repeating: UNIT.max, count: bytes)
      excess = UInt8(count%(UNIT.bitWidth))
      
      // flip remaining bits back to 0
      let remaining: Int = (excess == 0) ? UNIT.bitWidth : Int(excess)
      for i in remaining..<(UNIT.bitWidth) {
        storage[bytes-1] ^= (1<<i)
      }
      
    } else {
      let bytes: Int = (count%(UNIT.bitWidth) > 0) ? (count/(UNIT.bitWidth))+1 : count/(UNIT.bitWidth)
      storage = Array(repeating: 0, count: bytes)
      excess = UInt8(count%(UNIT.bitWidth))
    }
  }
  
  public init(_ bitSet: BitSet) {
    storage = bitSet.storage.storage
    excess = bitSet.storage.excess
  }
  
}
