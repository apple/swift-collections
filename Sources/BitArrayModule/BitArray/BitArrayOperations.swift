//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray {
  
  public mutating func append(_ newValue: Bool) {
    
    if (!newValue) {
      if(excess == 0) { storage.append(0)}
      _adjustExcessForAppend()
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
    if (self.excess == (WORD.bitWidth-1)) {
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
  /// Removes the last several values in the end of the BitArray
  ///
  /// The following example removes the last 3 elements of a BitArray
  ///     var bitArray: BitArray = [true, false, true, false, false, true]
  ///     bitArray.removeLast(3)
  ///     print(Array(bitArray))
  ///     Prints "[true, false, true]"
  ///
  /// - Parameters:
  ///   - k: an integer that represents the number of values desired to be removed from the beginning.
  ///`k` must be a positive number, and less than the `count` value of self
  public mutating func removeLast(_ k: Int){
    precondition(self.count != 0, "The bit array is empty. There are no items to remove.")
    precondition(k < endIndex, "The input amount is invalidly larger than the array itself.")
    precondition(k > 0, "Input amount must be a positive number.")
    let elementsInLastByte: Int = (excess == 0) ? WORD.bitWidth : Int(excess)
    if (k < elementsInLastByte) {
      for _ in 1...k {
        removeLast()
      }
      return
    } else if (k == elementsInLastByte) {
      storage.removeLast()
      excess = 0
      return
    }
    storage.removeLast()
    excess = 0
    let range = k - Int(elementsInLastByte)
    let removeableBytes: Int = range/(WORD.bitWidth)
    storage.removeLast(removeableBytes)
    
    // slower than necessary
    for _ in 0..<range%(WORD.bitWidth) {
      removeLast()
    }
  }
  
  private mutating func _adjustExcessForRemove() {
    if (excess == 0) {
      excess = WORD(WORD.bitWidth-1)
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
  /// Removes the first several values in the beginning of the BitArray
  /// self must not be empty
  ///
  /// The following example removes the first 3 elements of a BitArray
  ///     var bitArray: BitArray = [true, false, true, false, true]
  ///     bitArray.removeFirst(3)
  ///     print(Array(bitArray))
  ///     Prints "[false, true]"
  ///
  /// - Parameters:
  ///   - k: an integer that represents the number of values desired to be removed from the beginning.
  ///`k` must be a positive number, and less than the `count` value of `self`
  public mutating func removeFirst(_ k: Int) {
    precondition(self.count != 0, "The bit array is empty. There are no items to remove")
    precondition(k < endIndex, "The input rangeSize is invalidly larger than the bit array itself.")
    precondition(k > 0, "The input rangeSize must be a positive number.")
    let removeableBytes: Int = k/(WORD.bitWidth)
    let newCount = self.count-k
    storage.removeFirst(removeableBytes)
    
    let remainingElemCount = Int(k%(WORD.bitWidth))
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
      
      excess = WORD(newCount)%WORD((WORD.bitWidth))
      
      if (count != newCount) {
        storage.removeLast()
      }
    }
  }
  /// Returns the index of the first true value in the BitArray.
  /// If there are no true values in the BitArray, the function returns nil
  ///
  ///     Examples:
  ///     let bitArray: BitArray = [false, true, false, true]
  ///     let firstTrue: Int? = bitArray.firstTrue()
  ///     print(firstTrue)
  ///     Prints "2"
  ///
  ///     let allFalseBitArray: BitArray = [false, false, false]
  ///     let firstTrue: Int? = allFalseBitArray.firstTrue()
  ///     print(firstTrue)
  ///     Prints "nil"
  ///
  /// - Returns: An optional integer value of the index where the first true was found.
  /// If there are no true values in the BitArray, the function returns `nil`
  public func firstTrue() -> Int? {
    var counter = -1
    for item in storage {
      counter += 1
      if (item > 0) {
        return item.trailingZeroBitCount + counter*WORD.bitWidth
      }
    }
    return nil
  }
  /// Returns the index of the last true value in the BitArray.
  /// If there are no true values in the BitArray, the function returns nil
  ///
  ///     Examples:
  ///     let bitArray: BitArray = [false, true, false, true]
  ///     let lastTrue: Int? = bitArray.lastTrue()
  ///     print(lastTrue)
  ///     Prints "2"
  ///
  ///     let allFalseBitArray: BitArray = [false, false, false]
  ///     let lastTrue: Int? = allFalseBitArray.lastTrue()
  ///     print(lastTrue)
  ///     Prints "nil"
  ///
  /// - Returns: An optional integer value of the index where the last true was found
  /// If there are no true values in the BitArray, the function returns `nil`
  public func lastTrue() -> Int? {
    var counter = storage.count
    for item in storage.reversed() {
      counter -= 1
      if (item > 0) {
        return (WORD.bitWidth-item.leadingZeroBitCount) + counter*WORD.bitWidth - 1
      }
    }
    return nil
  }
  
}
