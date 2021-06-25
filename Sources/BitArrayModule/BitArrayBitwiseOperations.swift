//
//  BitArrayBitwiseOperations.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/18/21.
//

extension BitArray {
    
    
    public mutating func formBitwiseOR(with: BitArray) { // arrays of different length?
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] |= with.storage[i]
        }
        
    }
    
    public mutating func formBitwiseAND(with: BitArray) { // arrays of different length?
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] &= with.storage[i]
        }
        
    }
    
    public mutating func formBitwiseXOR(with: BitArray) { // arrays of different length?
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            self.storage[i] ^= with.storage[i]
        }
        
    }
    
    public func bitwiseOR(with: BitArray) -> BitArray{ // arrays of different length?
        
        var bitArrayOR = BitArray()
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            bitArrayOR.storage.append(self.storage[i] | with.storage[i])
        }
        
        return bitArrayOR
    }
    
    public func bitwiseAND(with: BitArray) -> BitArray{ // arrays of different length?
        
        var bitArrayAND = BitArray()
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            bitArrayAND.storage.append(self.storage[i] & with.storage[i])
        }
        
        return bitArrayAND
    }
    
    public func bitwiseXOR(with: BitArray) -> BitArray{ // arrays of different length?
        
        var bitArrayXOR = BitArray()
        
        if(self.storage.count != with.storage.count) {
            fatalError("Bitwise operations on BitArrays of different length is currently not supported")
        }
        //precondition(self.storage.count == with.count, "Bitwise operations on BitArrays of different length is currently not supported")
        
        for i in 0..<self.storage.count {
            bitArrayXOR.storage.append(self.storage[i] ^ with.storage[i])
        }
        
        return bitArrayXOR
    }
}
