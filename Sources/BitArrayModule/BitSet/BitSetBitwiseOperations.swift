//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    // in these implementations, the BitArray type storages do NOT have to be of same length, whereas for the current implementation of Bitwise Operations for BitArray, they do
    public mutating func formUnion(with: BitSet) {
        if (with.storage.storage.count < self.storage.storage.count) {
            for i in 0..<with.storage.storage.count {
                if (self.storage[i] || with.storage[i]) {
                    self.storage[i] = true
                }
            }
        } else {
            for i in 0..<self.storage.storage.count {
                if (self.storage[i] || with.storage[i]) {
                    self.storage[i] = true
                }
            }
        }
    }
    
}
