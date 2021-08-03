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
  
  public mutating func remove(at: Int) {
    self[at] = false
    for index in (at+1)..<endIndex {
      if(self[index]) {
        self[index-1] = true
        self[index] = false
      }
    }
    _adjustExcessForRemove()
  }
  
  @discardableResult
  public mutating func removeLast() -> Bool {
    defer {
      self[endIndex-1] = false
      _adjustExcessForRemove()
    }
    return self[endIndex-1]
  }
  
  public mutating func removeLast(_ rangeSize: Int){
    if (rangeSize < excess) {
      for _ in 1...rangeSize {
        removeLast()
      }
      return
    } else if (rangeSize == excess) {
      storage.removeLast()
      excess = 0
      return
    }
    storage.removeLast()
    excess = 0
    let range = rangeSize - Int(excess)
    let removeableBytes: Int = range/(UNIT.bitWidth)
    storage.removeLast(removeableBytes)
    
    // slower than necessary
    if (range%8 != 0) {
      for _ in 1...range%(UNIT.bitWidth) {
        removeLast()
      }
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
    defer {
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
    let removeableBytes: Int = rangeSize/(UNIT.bitWidth)
    storage.removeFirst(removeableBytes)
    
    if (rangeSize%(UNIT.bitWidth) != 0) {
      for i in 0..<rangeSize%(UNIT.bitWidth) {
        self[i] = false
        _adjustExcessForRemove() // slower option
      }
      for i in rangeSize%(UNIT.bitWidth)..<self.endIndex {
        if (self[i]) {
          self[i-1] = true
          self[i] = false
        }
      }
    }
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
