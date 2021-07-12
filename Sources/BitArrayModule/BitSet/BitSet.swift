//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

public struct BitSet {
    
    var storage = BitArray() // Doesn't this technically make this an ordered set?
    
    public init() { }
    
    public struct Index {
        var bitArrayIndex: Int
        public init(startIndex: Int) {
            bitArrayIndex = startIndex
        }
    }
    
}
