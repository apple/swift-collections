//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet: Collection {
    
    public func index(after i: Int) -> Int { return i + 1 }
    
    public var count: Int { return storage.count }
    
    public var startIndex: Int { return 0 }
    
    public var endIndex: Int { return storage.count }
    
}

extension BitSet: BidirectionalCollection {
    
    public func index(before i: Int) -> Int { return i - 1 }
    
}

extension BitSet: MutableCollection {
    public subscript(position: Int) -> UInt8 {
        get {
            return storage[position]
        }
        set(newValue) {
            storage[position] = newValue
        }
    }
}

extension BitSet: RandomAccessCollection, RangeReplaceableCollection {
    // Index is an Integer type which already is Strideable, hence nothing for RandomAccess
    // ADD REPLACESUBRANGE
}
