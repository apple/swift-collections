//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet: Collection, BidirectionalCollection {
    
    
    public func index(after: Index) -> Index { // mutates passed in Index
        // Add preconditions
        for i in (after.bitArrayIndex+1)..<storage.count {
            if (storage[i]) {
                return Index(bitArrayIndex: i)
            }
        }
        fatalError("After not found :(")
    }
    
    public func index(before: Index) -> Index {
        // Add preconditions
        for i in stride(from: (before.bitArrayIndex-1), through: 0, by: -1) {
            if (storage[i]) {
                return Index(bitArrayIndex: i)
            }
        }
        fatalError("Before not found :(")
    }
    
    public func index(_ index: Index, offsetBy distance: Int) -> Index {
        // Add preconditions
        if (distance == 0) {
            return index
        } else if (distance > 1) {
            for i in (index.bitArrayIndex+1)..<storage.count {
                if (storage[i]) {
                    return Index(bitArrayIndex: i)
                }
            }
        } else {
            for i in stride(from: index.bitArrayIndex-1, through: 0, by: -1) {
                if (storage[i]) {
                    return Index(bitArrayIndex: i)
                }
            }
        }
        fatalError("Index not found :(")
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
    
    public var startIndex: Index { return Index(bitArrayIndex: storage.firstTrueIndex()) } // test first(where: {}) instead
    
    public var endIndex: Index { return Index(bitArrayIndex: storage.firstTrueIndex()) } // needs completing
    
}

extension BitSet: MutableCollection {
    public subscript(position: Index) -> Int {
        get {
            return position.bitArrayIndex
        }
        set {
            // what to do here?
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
