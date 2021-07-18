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
    // to be implemented
  }
  
  public init(arrayLiteral elements: Bool...) {
    var counter = 0
    for i in 0..<elements.endIndex {
      if (counter%8 == 0) {
        storage.append(0)
      }
      if (elements[i]) {
        self[i] = true
      }
      counter += 1
    }
    
    excess = UInt8(elements.count%8)
  }
  
  public init(_ bitSet: BitSet) {
    storage = bitSet.storage.storage
    excess = bitSet.storage.excess
  }
  
  // What is this?
  /*public init(repeating repeatedValue: Bool, count: Int) {
    
  }*/
  
}
