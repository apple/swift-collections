//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//



// NOTE: Research @inlinable

extension BitArray {
  
  public mutating func append(_ newValue: Bool) {
    
    if (!newValue) {
      if(excess == 0) { storage.append(0)}
      _adjustExcess() // excess += 1
      return
    }
    
    if (excess == 0) {
      storage.append(1)
    } else {
      storage[storage.endIndex-1] += (1 << excess)
    }
    
    _adjustExcess()
  }
  
  private mutating func _adjustExcess(){
    if (self.excess == 7) {
      self.excess = 0
    } else {
      self.excess += 1
    }
  }
  
  internal func firstTrueIndex() -> Int {
    var counter = -1
    for item in storage {
      counter += 1
      if (item > 0) {
        for pointer in 0..<8 {
          if ( (item & (1 << pointer)) > 0 ) {
            return pointer + counter*BitArray.UNIT.bitWidth
          }
        }
      } else {
        fatalError("Error in first true index function")
      }
    }
    return endIndex // If public, return nil/optional and probably not have the fatalError()
  }
  
  internal func lastTrueIndex() -> Int {
    var counter = storage.count
    for item in storage.reversed() {
      counter -= 1
      if (item > 0) {
        for pointer in 0..<8 {
          if ( (item & (1 << pointer)) > 0 ) {
            return pointer + counter*BitArray.UNIT.bitWidth
          }
        }
      } else {
        fatalError("Error in first true index function")
      }
    }
    return endIndex
  }
  
  public func asBitSet() -> BitSet {
    return BitSet(self)
  }
  
}
