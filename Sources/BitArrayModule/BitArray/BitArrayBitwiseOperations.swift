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
  
  
  public mutating func formBitwiseOr(with: BitArray) {
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.endIndex {
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
