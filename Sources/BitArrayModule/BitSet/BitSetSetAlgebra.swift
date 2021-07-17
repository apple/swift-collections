//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/14/21.
//

extension BitSet: SetAlgebra {
    
    public mutating func insert(_ newMember: __owned Int) -> (inserted: Bool, memberAfterInsert: Int) { // what is the difference between insert and update?
        while (storage.count-1 < newMember) {
            storage.storage.append(0)
        }
        // check if member already existed -> false
        storage[newMember] = true
        
        return (true, newMember) // umm when would this ever be false?
    }
    
    // what is '__consuming' and '__owned'?
    public __consuming func union(_ other: __owned BitSet) -> BitSet { // Will need to simplify later (by adjusting the BitArray functions to that they can be called from here
        var newBitSet = BitSet()
        
        if (other.storage.count < self.storage.count) {
            for i in 0..<other.storage.storage.count {
                let newVal: UInt8 = self.storage.storage[i] | other.storage.storage[i]
                newBitSet.storage.storage.append(newVal)
            }
            for a in other.storage.count..<self.storage.count { // why does this work and doing storage.storage like the other for-loops not?
                if(self.storage[a]) {
                    newBitSet.append(a)
                }
            }
        } else if (self.storage.count < other.storage.count){
            for j in 0..<self.storage.storage.count {
                let newVal = storage.storage[j] | other.storage.storage[j]
                newBitSet.storage.storage.append(newVal)
            }
            for b in self.storage.count..<other.storage.count { // why does this work and doing storage.storage like the other for-loops not?
                if(other.storage[b]) {
                    newBitSet.append(b)
                }
            }
        } else {
            for c in 0..<self.storage.storage.count {
                let newVal = self.storage.storage[c] | other.storage.storage[c]
                newBitSet.storage.storage.append(newVal)
            }
        }
        return newBitSet
    }
    
    public __consuming func intersection(_ other: BitSet) -> BitSet {
        let size: Int = (self.storage.storage.count >= other.storage.storage.count) ? other.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
        var newBitSet = BitSet()
        
        for i in 0..<size {
            newBitSet.storage.storage.append(self.storage.storage[i] & other.storage.storage[i])
        }
        
        for i in size..<self.storage.storage.count {
            newBitSet.storage.storage[i] = 0
        }
        
        return newBitSet
    }
    
    public __consuming func symmetricDifference(_ other: __owned BitSet) -> BitSet {
        var copy = self
        copy.formSymmetricDifference(other)
        return copy
    }
    
    public mutating func remove(_ member: Int) -> Int? {
        let returnVal: Int? = (storage[member]) ? member : nil
        storage[member] = false
        return returnVal
    }
    
    public mutating func update(with newMember: __owned Int) -> Int? { // use this INSTEAD of append?
        // what is the purpose of returning what was already in the set? (there are no duplicates in this set, right?)
        while (storage.count-1 < newMember) {
            storage.storage.append(0)
        }
        
        let returnVal: Int? = (storage[newMember]) ? newMember : nil
        
        storage[newMember] = true
        
        return returnVal
    }
    
    public mutating func formUnion(_ other: __owned BitSet) {
        if (other.storage.count < self.storage.count) {
            for i in 0..<other.storage.storage.count {
                self.storage.storage[i] |= other.storage.storage[i]
            }
        } else if (self.storage.count < other.storage.count){
            for j in 0..<self.storage.storage.count {
                self.storage.storage[j] |= other.storage.storage[j]
            }
            for a in self.storage.count..<other.storage.count { // why does this work and doing storage.storage like the other for-loops not?
                if(other.storage[a]) {
                    self.append(a)
                }
            }
        } else {
            for b in 0..<self.storage.storage.count {
                self.storage.storage[b] |= other.storage.storage[b]
            }
        }

    }
    
    public mutating func formIntersection(_ other: BitSet) {
        let size: Int = (self.storage.storage.count >= other.storage.storage.count) ? other.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
        
        for i in 0..<size {
            self.storage.storage[i] &= other.storage.storage[i]
        }
        
        for i in size..<self.storage.storage.count {
            self.storage.storage[i] = 0
        }
    }
    
    public mutating func formSymmetricDifference(_ other: __owned BitSet) { // can be optimized later
        self.formIntersection(other)
        for i in 0..<self.storage.storage.count {
            self.storage.storage[i] = ~self.storage.storage[i]
        }
    }
    
    public static func == (lhs: BitSet, rhs: BitSet) -> Bool {
        return (lhs.storage == rhs.storage) // BitArray also conforms to Equatable, so we good here
    }
    
    
    
}
