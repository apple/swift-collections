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
    if (self.excess == (UNIT.bitWidth-1)) {
      self.excess = 0
    } else {
      self.excess += 1
    }
  }
  
  public mutating func remove(at: Int) {
    self[at] = false
    for index in (at+1)..<endIndex {
      if(self[index]) {
        self[index-1] = true
        self[index] = false
      }
    }
    
  }
  
  public mutating func removeLast() {
    self[endIndex-1] = false
  }
  
  
  
  internal func firstTrueIndex() -> Int {
    var counter = -1
    for item in storage {
      counter += 1
      if (item > 0) {
        return item.leadingZeroBitCount + counter*UNIT.bitWidth
      }
    }
    return endIndex // If public, return nil/optional and probably not have the fatalError()
  }
  
  internal func lastTrueIndex() -> Int? {
    var counter = storage.count
    for item in storage.reversed() {
      counter -= 1
      if (item > 0) {
        return item.trailingZeroBitCount + counter*UNIT.bitWidth
      }
    }
    return nil
  }
  
}
