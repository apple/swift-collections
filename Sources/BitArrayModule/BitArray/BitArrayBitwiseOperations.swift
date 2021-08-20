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
  
  
  public mutating func formBitwiseOr(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.endIndex {
      self.storage[i] |= other.storage[i]
    }
  }
  
  public mutating func formBitwiseAnd(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] &= other.storage[i]
    }
  }
  
  public mutating func formBitwiseXor(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] ^= other.storage[i]
    }
  }
  
  public mutating func formBitwiseNot() {
    
    if (count == 0) {
      return
    }
    
    let remaining: Int = (excess == 0) ? WORD.bitWidth : Int(excess)
    
    for i in 0..<self.storage.endIndex {
      self.storage[i] = ~self.storage[i]
    }
    
    var mask: WORD = 1 << remaining
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...((WORD.bitWidth)-Int(excess)) {
      self.storage[storage.endIndex-1] ^= mask
      mask <<= 1
    }
    
  }
  
  public func bitwiseOr(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseOr(other)
    return copy
  }
  
  public func bitwiseAnd(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseAnd(other)
    return copy
  }
  
  public func bitwiseXor(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseXor(other)
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
    copy.formBitwiseOr(rhs)
    return copy
  }
  
  public static func & (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseAnd(rhs)
    return copy
  }
  
  public static func ^ (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseXor(rhs)
    return copy
  }
  
  public static prefix func ~ (_ bitArray: BitArray) -> BitArray {
    var copy = bitArray
    copy.formBitwiseNot()
    return copy
  }
  
  public static func |= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseOr(rhs)
  }
  
  public static func &= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseAnd(rhs)
  }
  
  public static func ^= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseXor(rhs)
  }
  
}
