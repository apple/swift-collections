//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    // in these implementations, the BitArray type storages do NOT have to be of same length, whereas for the current implementation of Bitwise Operations for BitArray, they do
    public mutating func formUnion(with: BitSet) {
        if (with.storage.count < self.storage.count) {
            for i in 0..<with.storage.count {
                if (self.storage[i] || with.storage[i]) {
                    self.storage[i] = true
                }
            }
        } else if (self.storage.count < with.storage.count){
            for i in 0..<self.storage.count {
                if (self.storage[i] || with.storage[i]) {
                    self.storage[i] = true
                }
            }
            for i in self.storage.count..<with.storage.count {
                if(with.storage[i]) {
                    self.append(i)
                }
            }
        } else {
            for i in 0..<self.storage.count {
                if (self.storage[i] || with.storage[i]) {
                    self.storage[i] = true
                }
            }
        }
    }
    
}
