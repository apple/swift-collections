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
  
  // there is a potential to remove adjustExcess(), since the if-else block within adjustExcess() would only be need if newValue == true && excess != 0 (basically only if we get to the else block at the end of the append function). Basides that, all other cases would be excess += 1
  private mutating func _adjustExcess(){
    if (self.excess == 7) {
      self.excess = 0
    } else {
      self.excess += 1
    }
  }
  
  internal func firstTrueIndex() -> Int { // very bad function
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
    return endIndex // If public, return nil/optional
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
    return endIndex // big problem
  }
  
  /* TOGGLE FUNCTION ALREADY EXISTS AND WORKS??? */
  /*public mutating func toggle(at position: Int) -> Bool { // returns the new value. I don't know, I felt like having it return some contaxt as to what happened might be useful for a developer
   
   precondition(position < endIndex && position >= startIndex, "Index out of bounds")
   
   let (index, mask) = _split(_position: position)
   storage[index] ^= mask
   
   return self[position]
   }*/
  
}
