//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//

extension BitArray: Collection {
    
    public subscript(position: Int) -> Bool {
        
        if (position >= endIndex || position < startIndex) {
            fatalError("Index out of bounds")
        }
        
        let index: Int = position/UNIT.bitWidth
        let subPosition: Int = position - index*UNIT.bitWidth
        
        let mask: UInt8 = 1 << subPosition
        if (storage[index] & mask == 0) { return false } else { return true }
    }
    
    
    public func index(after i: Int) -> Int {
        if (i == endIndex) { return i }
        else { return i + 1 }
    }
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return (self.storage.count)*UNIT.bitWidth - (UNIT.bitWidth - Int(excess))
    }
    
    public var count: Int { get { endIndex } } // would this work for count?
    
}


extension BitArray: BidirectionalCollection {
    
    public func index(before i: Int) -> Int {
        if (i == startIndex) { return i }
        else { return i - 1 }
    }
    
}

extension BitArray: RandomAccessCollection, RangeReplaceableCollection {
    // Index is an Integer type which already is Strideable, hence nothing for RandomAccess
    // ... that's all for RangeReplaceable??
}
