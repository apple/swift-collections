//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet: Collection {
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public var count: Int {
        var mask: UInt8 = 1
        var count = 0
        
        for byte in storage.storage {
            for j in 0..<8 {
                mask <<= j
                if (byte & mask != 0) {
                    count += 1
                }
                mask = 1
            }
        }
        
        return count
    }
    
    public var startIndex: Int { return 0 }
    
    public var endIndex: Int { return count }
    
}

extension BitSet: BidirectionalCollection {
    public func index(before i: Int) -> Int { return i - 1 }
}

extension BitSet: MutableCollection {
    public subscript(position: Int) -> Bool { // How do we even want this function to work? Currently I just have it working like the BitArray, but that doesn't sound like it makes sense. I mean if this is a set... does it even work like an array? And the fact that this is technically sorted... hmm...
        get {
            precondition(position < endIndex && position >= startIndex, "Index out of bounds")
            
            let (index, mask) = _split(_position: position)
            return (storage.storage[index] & mask != 0)
        }
        set {
            let (index, mask) = _split(_position: position)
            if (newValue) { storage.storage[index] |= mask } else { storage.storage[index] &= ~mask }
        }
    }
    
    private func _split(_position: Int) -> (Int, UInt8) {
        let index: Int = _position/BitArray.UNIT.bitWidth
        let subPosition: Int = _position - index*BitArray.UNIT.bitWidth
        let mask: UInt8 = 1 << subPosition
        
        return (index, mask)
    }
    
    
}


extension BitSet: RandomAccessCollection, RangeReplaceableCollection {
    // Index is an Integer type which already is Strideable, hence nothing for RandomAccess
    // ADD REPLACESUBRANGE
}
