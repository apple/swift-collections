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
    var counter = 0
    for value in elements {
      if (counter%8 == 0) {
        storage.append(0)
      }
      if (value) {
        self[counter] = true
      }
      counter += 1
    }
    
    excess = UInt8(counter%8)
  }
  
  public init(arrayLiteral elements: Bool...) {
    for i in 0..<elements.endIndex {
      if (i%8 == 0) {
        storage.append(0)
      }
      if (elements[i]) {
        self[i] = true
      }
    }
    
    excess = UInt8(elements.count%8)
  }
  
  public init(repeating repeatedValue: Bool, count: Int) {
    if (count == 0) {
      return
    }
    
    if (repeatedValue) {
      let bytes: Int = (Int(count%8) > 0) ? (count/8)+1 : count/8
      for _ in 1...bytes {
        storage.append(255)
      }
      
      excess = UInt8(count%8)
      
      // flip remaining bits back to 0
      let remaining: Int = (excess == 0) ? UNIT.bitWidth : Int(excess)
      
      for i in remaining..<8 {
        storage[bytes-1] ^= (1<<i)
      }
    } else {
      let bytes: Int = (count%8 > 0) ? (count/8)+1 : count/8
      for _ in 1...bytes {
        storage.append(0)
      }
      excess = UInt8(count%8)
    }
  }
  
  public init(_ bitSet: BitSet) {
    storage = bitSet.storage.storage
    excess = bitSet.storage.excess
  }
  
}
