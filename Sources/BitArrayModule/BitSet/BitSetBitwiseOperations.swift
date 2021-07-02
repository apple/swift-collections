//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    // in these implementations, the BitArray type storages do NOT have to be of same length, whereas for the current implementation of Bitwise Operations for BitArray, they do
    // needs revision and proper testing
    public mutating func formUnion(with: BitSet) {
        if (with.storage.count < self.storage.count) {
            for i in 0..<with.storage.storage.count {
                self.storage.storage[i] |= with.storage.storage[i]
            }
        } else if (self.storage.count < with.storage.count){
            for j in 0..<self.storage.storage.count {
                self.storage.storage[j] |= with.storage.storage[j]
            }
            for a in self.storage.count..<with.storage.count { // why does this work and doing storage.storage like the other for-loops not?
                if(with.storage[a]) {
                    self.append(a)
                }
            }
        } else {
            for b in 0..<self.storage.storage.count {
                self.storage.storage[b] |= with.storage.storage[b]
            }
        }
    }
    
    public mutating func formIntersection(with: BitSet) {
        let size: Int = (self.storage.storage.count >= with.storage.storage.count) ? with.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
        
        for i in 0..<size {
            self.storage.storage[i] &= with.storage.storage[i]
        }
        
        for i in size..<self.storage.storage.count {
            self.storage.storage[i] = 0
        }
    }
    
    public func intArrayView() -> [Int] { // previously named 'asAnIntArray' -- also probably needs to go into diff file
        var arrayView: [Int] = []
        
        var mask: UInt8 = 0
        
        for i in 0..<storage.storage.count {
            for j in 0..<8 {
                mask <<= j
                if (storage.storage[i] & mask != 0) {
                    arrayView.append(i*BitArray.UNIT.bitWidth + j)
                }
                mask = 1
            }
        }
        return arrayView
    }
    
    public func cartesianProduct(with: BitSet) -> [(Int, Int)] {
        var cartesianProduct: [(Int, Int)] = []
        
        return cartesianProduct
    }
    
}
