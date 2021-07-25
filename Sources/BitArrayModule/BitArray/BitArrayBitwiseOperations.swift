//
//  BitArrayBitwiseOperations.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/18/21.
//

extension BitArray {
  
  // Need to make sure the lack of adjusting excess doesn't do anything weird here
  
  public mutating func formBitwiseOR(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] |= with.storage[i]
    }
  }
  
  public mutating func formBitwiseAND(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] &= with.storage[i]
    }
  }
  
  public mutating func formBitwiseXOR(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] ^= with.storage[i]
    }
  }
  
  public mutating func formBitwiseNOT() {
    
    for i in 0..<self.storage.count {
      self.storage[i] = ~self.storage[i]
    }
    
    var mask: UInt8 = 1 << self.excess
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...((UNIT.bitWidth)-Int(self.excess)) {
      self.storage[self.endIndex-1] ^= mask
      mask <<= 1
    }
    
  }
  
  public func bitwiseOR(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseOR(with: with)
    return copy
  }
  
  public func bitwiseAND(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseAND(with: with)
    return copy
  }
  
  public func bitwiseXOR(with: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseXOR(with: with)
    return copy
  }
  
  public func bitwiseNOT() -> BitArray {
    var copy = self
    copy.formBitwiseNOT()
    return copy
  }
}

// Overloaded Operators

extension BitArray {
  
  public static func | (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseOR(with: rhs)
    return copy
  }
  
  public static func & (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseAND(with: rhs)
    return copy
  }
  
  public static func ^ (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseXOR(with: rhs)
    return copy
  }
  
  public static prefix func ~ (_ bitArray: BitArray) -> BitArray {
    var copy = bitArray
    copy.formBitwiseNOT()
    return copy
  }
  
  public static func |= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseOR(with: rhs)
  }
  
  public static func &= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseAND(with: rhs)
  }
  
  public static func ^= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseXOR(with: rhs)
  }
  
}
