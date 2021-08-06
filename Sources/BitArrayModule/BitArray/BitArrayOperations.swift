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
      _adjustExcessForAppend() // excess += 1
      return
    }
    
    if (excess == 0) {
      storage.append(1)
    } else {
      storage[storage.endIndex-1] += (1 << excess)
    }
    
    _adjustExcessForAppend()
  }
  
  private mutating func _adjustExcessForAppend(){
    if (self.excess == (UNIT.bitWidth-1)) {
      self.excess = 0
    } else {
      self.excess += 1
    }
  }
  
  @discardableResult
  public mutating func remove(at: Int) -> Bool {
    precondition(self.count != 0, "The bit array is empty. There are no items to remove.")
    precondition(at < endIndex && at >= 0, "The index entered is out of range")
    defer {
      self[at] = false
      for index in (at+1)..<endIndex {
        if(self[index]) {
          self[index-1] = true
          self[index] = false
        }
      }
      _adjustExcessForRemove()
    }
    return self[at]
  }
  
  @discardableResult
  public mutating func removeLast() -> Bool {
    precondition(self.count != 0, "The bit array is empty. There are no items to remove.")
    defer {
      self[endIndex-1] = false
      _adjustExcessForRemove()
    }
    return self[endIndex-1]
  }
  
  public mutating func removeLast(_ rangeSize: Int){
    precondition(self.count != 0, "The bit array is empty. There are no items to remove.")
    precondition(rangeSize < endIndex, "The input amount is invalidly larger than the array itself.")
    precondition(rangeSize > 0, "Input amount must be a positive number.")
    let elementsInLastByte: Int = (excess == 0) ? UNIT.bitWidth : Int(excess)
    if (rangeSize < elementsInLastByte) {
      for _ in 1...rangeSize {
        removeLast()
      }
      return
    } else if (rangeSize == elementsInLastByte) {
      storage.removeLast()
      excess = 0
      return
    }
    storage.removeLast()
    excess = 0
    let range = rangeSize - Int(elementsInLastByte)
    let removeableBytes: Int = range/(UNIT.bitWidth)
    storage.removeLast(removeableBytes)
    
    // slower than necessary
    for _ in 0..<range%(UNIT.bitWidth) {
      removeLast()
    }
  }
  
  private mutating func _adjustExcessForRemove() {
    if (excess == 0) {
      excess = UNIT(UNIT.bitWidth-1)
    } else {
      excess -= 1
      if (excess == 0) {
        storage.removeLast()
      }
    }
  }
  
  public mutating func removeAll() {
    storage = []
    excess = 0
  }
  
  @discardableResult
  public mutating func removeFirst() -> Bool {
    precondition(self.count != 0, "The bit array is empty. There are no items to remove")
    defer {
      self[0] = false
      for index in 1..<endIndex {
        if(self[index]) {
          self[index-1] = true
          self[index] = false
        }
      }
      _adjustExcessForRemove()
    }
    return self[0]
  }
  
  public mutating func removeFirst(_ rangeSize: Int) {
    precondition(self.count != 0, "The bit array is empty. There are no items to remove")
    precondition(rangeSize < endIndex, "The input rangeSize is invalidly larger than the bit array itself.")
    precondition(rangeSize > 0, "The input rangeSize must be a positive number.")
    let removeableBytes: Int = rangeSize/(UNIT.bitWidth)
    let newCount = self.count-rangeSize
    storage.removeFirst(removeableBytes)
    
    let remainingElemCount = Int(rangeSize%(UNIT.bitWidth))
    
    if (remainingElemCount != 0) {
      for i in 0..<remainingElemCount {
        self[i] = false
      }
      for i in remainingElemCount..<endIndex {
        if (self[i]) {
          self[i-remainingElemCount] = true
          self[i] = false
        }
      }
      
      if(remainingElemCount >= excess) {
        storage.removeLast()
      }
      
      excess = UNIT(newCount)%UNIT((UNIT.bitWidth))
      
      /*for _ in 1...remainingElemCount {
       _adjustExcessForRemove()
       }*/
      /*if (remainingElemCount > excess) {
       excess = UNIT(UNIT.bitWidth) - (UNIT(remainingElemCount)-excess)
       self.removeLast(remainingElemCount)
       } else if (remainingElemCount == excess) {
       excess = 0
       } else {
       excess -= UNIT(remainingElemCount)
       }*/
      //excess = (remainingElemCount > excess) ? UNIT(UNIT.bitWidth)-UNIT(remainingElemCount) : (excess-UNIT(remainingElemCount))
    }
  }
  
  // make public
  internal func firstTrueIndex() -> Int? {
    var counter = -1
    for item in storage {
      counter += 1
      if (item > 0) {
        return item.trailingZeroBitCount + counter*UNIT.bitWidth
      }
    }
    return nil // If public, return nil/optional and probably not have the fatalError()
  }
  
  internal func lastTrueIndex() -> Int? {
    var counter = storage.count
    for item in storage.reversed() {
      counter -= 1
      if (item > 0) {
        return (UNIT.bitWidth-item.leadingZeroBitCount) + counter*UNIT.bitWidth - 1
      }
    }
    return nil
  }
  
}
