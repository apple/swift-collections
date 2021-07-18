//
//  BitArrayBitwiseOperations.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/18/21.
//

extension BitArray {
  
  
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
    for _ in 1...(8-self.excess) {
      self.storage[self.endIndex-1] ^= mask
      mask <<= 1
    }
    
  }
  
  public func bitwiseOR(with: BitArray) -> BitArray{
    
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayOR = BitArray()
    
    for i in 0..<self.storage.count {
      bitArrayOR.storage.append(self.storage[i] | with.storage[i])
    }
    return bitArrayOR
  }
  
  public func bitwiseAND(with: BitArray) -> BitArray{
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayAND = BitArray()
    
    for i in 0..<self.storage.count {
      bitArrayAND.storage.append(self.storage[i] & with.storage[i])
    }
    
    return bitArrayAND
  }
  
  public func bitwiseXOR(with: BitArray) -> BitArray{
    precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayXOR = BitArray()
    
    for i in 0..<self.storage.count {
      bitArrayXOR.storage.append(self.storage[i] ^ with.storage[i])
    }
    
    return bitArrayXOR
  }
  
  public func bitwiseNOT() -> BitArray {
    var bitArrayNOT = BitArray()
    
    for i in 0..<self.storage.count {
      bitArrayNOT.storage.append(~self.storage[i])
    }
    
    var lastByte = self.storage[self.endIndex-1]
    var mask: UInt8 = 1 << self.excess
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...(8-self.excess) {
      lastByte ^= mask
      mask <<= 1
    }
    
    bitArrayNOT.storage.append(lastByte)
    
    return bitArrayNOT
  }
}

extension BitArray {
  
  public static func | (lhs: BitArray, rhs: BitArray) -> BitArray {
    precondition(lhs.storage.count == rhs.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayOR = BitArray()
    
    for i in 0..<lhs.storage.count {
      bitArrayOR.storage.append(lhs.storage[i] | rhs.storage[i])
    }
    
    return bitArrayOR
  }
  
  public static func & (lhs: BitArray, rhs: BitArray) -> BitArray {
    precondition(lhs.storage.count == rhs.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayAND = BitArray()
    
    for i in 0..<lhs.storage.count {
      bitArrayAND.storage.append(lhs.storage[i] & rhs.storage[i])
    }
    
    return bitArrayAND
  }
  
  public static func ^ (lhs: BitArray, rhs: BitArray) -> BitArray {
    precondition(lhs.storage.count == rhs.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    var bitArrayXOR = BitArray()
    
    for i in 0..<lhs.storage.count {
      bitArrayXOR.storage.append(lhs.storage[i] ^ rhs.storage[i])
    }
    
    return bitArrayXOR
  }
  
  public static prefix func ~ (_ bitArray: BitArray) -> BitArray {
    var bitArrayNOT = BitArray()
    
    for i in 0..<bitArray.storage.count {
      bitArrayNOT.storage.append(~bitArray.storage[i])
    }
    
    var lastByte = bitArray.storage[bitArray.endIndex-1]
    var mask: UInt8 = 1 << bitArray.excess
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...(8-bitArray.excess) {
      lastByte ^= mask
      mask <<= 1
    }
    
    bitArrayNOT.storage.append(lastByte)
    
    return bitArrayNOT
  }
  
}
