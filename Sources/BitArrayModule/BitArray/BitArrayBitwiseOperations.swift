//
//  BitArrayBitwiseOperations.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/18/21.
//

extension BitArray {
  
  // Need to make sure the lack of adjusting excess doesn't do anything weird here
  
  public mutating func formBitwiseOr(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] |= with.storage[i]
    }
  }
  
  public mutating func formBitwiseAnd(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] &= with.storage[i]
    }
  }
  
  public mutating func formBitwiseXor(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] ^= with.storage[i]
    }
  }
  
  public mutating func formBitwiseNot() {
    
    for i in 0..<self.storage.count {
      self.storage[i] = ~self.storage[i]
    }
    
    var mask: UNIT = 1 << self.excess
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...((UNIT.bitWidth)-Int(self.excess)) {
      self.storage[self.endIndex-1] ^= mask
      mask <<= 1
    }
    
  }
  
  public func bitwiseOr(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseOr(with: with)
    return copy
  }
  
  public func bitwiseAnd(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseAnd(with: with)
    return copy
  }
  
  public func bitwiseXor(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseXor(with: with)
    return copy
  }
  
  public func bitwiseNot() -> BitArray {
    var copy = self
    copy.formBitwiseNot()
    return copy
  }
}

// Overloaded Operators

extension BitArray {
  
  public static func | (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseOr(with: rhs)
    return copy
  }
  
  public static func & (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseAnd(with: rhs)
    return copy
  }
  
  public static func ^ (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseXor(with: rhs)
    return copy
  }
  
  public static prefix func ~ (_ bitArray: BitArray) -> BitArray {
    var copy = bitArray
    copy.formBitwiseNot()
    return copy
  }
  
  public static func |= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseOr(with: rhs)
  }
  
  public static func &= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseAnd(with: rhs)
  }
  
  public static func ^= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseXor(with: rhs)
  }
  
}
