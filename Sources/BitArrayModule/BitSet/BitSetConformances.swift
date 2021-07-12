//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet: Collection, BidirectionalCollection {
    
    
    public func index(after: BitSet.Index) -> BitSet.Index {
        return after
    }
    
    public func index(before: BitSet.Index) -> BitSet.Index {
        return before
    }
    
    public func index(_ index: BitSet.Index, offsetBy distance: Int) -> BitSet.Index {
        return index
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
    
    public var startIndex: BitSet.Index { return BitSet.Index(startIndex: storage.firstTrueIndex()) }
    
    public var endIndex: BitSet.Index { return BitSet.Index(startIndex: storage.firstTrueIndex()) }
    
}

extension BitSet: MutableCollection {
    public subscript(position: BitSet.Index) -> Int {
        get {
            
        }
        set {
            
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
