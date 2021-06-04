//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//

extension BitArray: BidirectionalCollection, RandomAccessCollection, RangeReplaceableCollection {
    
    public func index(before i: Int) -> Int {
        if (i == startIndex) { return i }
        else { return i - 1 }
    }
    
}
