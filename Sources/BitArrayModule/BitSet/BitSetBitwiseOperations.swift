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
    
}
