//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

import Foundation

public struct BitArray {
    typealias UNIT = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
    
    // Will start off storing elements little-endian just because I have a hunch the calculations might be cleaner
    var storage : [UNIT]
    var excess: UInt8 // I've been playng around with this variable to get some sort of size going. This probably isn't the best way but I'm working on it and evolving it. First I had this as 'size' which basically stored the count, but that was very obviously problematic, even if I just wanted it to get things initially working. Besides, only storing the 'excess' is probably closer to the solution Im anticipating to have
    
    public init() {
        storage = []
        excess = 0
    }
    
}


// NOTE: Research @inlinable

extension BitArray {
    
    public mutating func append(_ newValue: Bool) { // will abtracting reduce performance?
        if (excess == 0) {
            if (newValue == true) {
                self.storage.append(1)
            } else {
                self.storage.append(0)
            }
        } else if (newValue == true) {
            self.storage[storage.count-1] += UInt8(pow(2, Double(excess)))
        }
        adjustExcess()
    }
    
    private mutating func adjustExcess(){
        if (self.excess == 7) {
            self.excess = 0
        } else {
            self.excess += 1
        }
    }
}


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
