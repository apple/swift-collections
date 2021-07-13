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
        public init(bitArrayIndex: Int) { // considering to make it 'public init(_ bitArrayIndex: Int)'
            self.bitArrayIndex = bitArrayIndex
        }
    }
    
}

extension BitSet.Index: Comparable, Hashable { // Hashable worked?? Cool.
    
    public static func < (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
        return (lhs.bitArrayIndex < rhs.bitArrayIndex)
    }
    
    public static func <= (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
        return (lhs.bitArrayIndex <= rhs.bitArrayIndex)
    }
    
    public static func == (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
        return (lhs.bitArrayIndex == rhs.bitArrayIndex)
    }
    
    public static func >= (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
        return (lhs.bitArrayIndex >= rhs.bitArrayIndex)
    }
    
    public static func > (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
        return (lhs.bitArrayIndex > rhs.bitArrayIndex)
    }
    
}
