//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
  
  public func contains(indexValue: Int) -> Bool {
    return storage[indexValue]
  }
  
  
    //INCORPORATE THIS INTO REMOVE
  public mutating func dropExcessFalses() { // lol needs a better name
    // remove excess bytes
    let bitArrayEndByteIndex = storage.storage.endIndex-1
    while (storage.storage[storage.storage.endIndex-1] == 0) {
      storage.storage.removeLast()
    }
    
    // adjust excess value for storage: BitArray
    for i in (0...storage.excess).reversed() {
      if (((1<<i) & storage.storage[bitArrayEndByteIndex]) > 0) {
        storage.excess = i
        break
      }
    }
  }
}
