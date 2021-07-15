//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/14/21.
//

extension BitSet: SetAlgebra {
    public __consuming func union(_ other: __owned BitSet) -> BitSet {
        <#code#>
    }
    
    public __consuming func intersection(_ other: BitSet) -> BitSet {
        <#code#>
    }
    
    public __consuming func symmetricDifference(_ other: __owned BitSet) -> BitSet {
        <#code#>
    }
    
    public mutating func remove(_ member: Int) -> Int? {
        <#code#>
    }
    
    public mutating func update(with newMember: __owned Int) -> Int? {
        <#code#>
    }
    
    public mutating func formUnion(_ other: __owned BitSet) {
        <#code#>
    }
    
    public mutating func formIntersection(_ other: BitSet) {
        <#code#>
    }
    
    public mutating func formSymmetricDifference(_ other: __owned BitSet) {
        <#code#>
    }
    
    public static func == (lhs: BitSet, rhs: BitSet) -> Bool {
        return (lhs.storage == rhs.storage) // BitArray also conforms to Equatable, so we good here
    }
    
    
    
}
