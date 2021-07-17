//
//  BitArrayBitwiseOperations.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/18/21.
//

extension BitArray {
    
    
    public mutating func formBitwiseOR(with: BitArray) { // arrays of different length?
        
        precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] |= with.storage[i]
        }
    }
    
    public mutating func formBitwiseAND(with: BitArray) { // arrays of different length?
        
        precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] &= with.storage[i]
        }
    }
    
    public mutating func formBitwiseXOR(with: BitArray) { // arrays of different length?
        
        precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] ^= with.storage[i]
        }
    }
    
    public func bitwiseOR(with: BitArray) -> BitArray{ // arrays of different length?
        
        var bitArrayOR = self
        bitArrayOR.formBitwiseOR(with: with)
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
    
    public func bitwiseXOR(with: BitArray) -> BitArray{ // arrays of different length?
        precondition(self.storage.count == with.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        var bitArrayXOR = BitArray()
        
        for i in 0..<self.storage.count {
            bitArrayXOR.storage.append(self.storage[i] ^ with.storage[i])
        }
        
        return bitArrayXOR
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
        
        return bitArrayNOT
    }
    
}
