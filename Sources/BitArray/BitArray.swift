//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

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
    public func test() {
        print("Nice! We're in test function!")
    }
    
    mutating func append(_ newValue: Bool) {
        
        adjustExcess() // will abtracting reduce performance?
    }
    
    mutating private func adjustExcess(){
        if (self.excess == 7) {
            self.excess = 0
        } else {
            self.excess += 1
        }
    }
}

extension BitArray: Collection {
    
    //THE FUN FUNCTION
    public subscript(position: Int) -> Bool {
        #warning("This is definitely wrong. Just have this here to get it to conform to collection for now")
        // first get the appropriate element in storage
        let index: Int = position/UNIT.bitWidth
        let subPosition: Int = position - index*UNIT.bitWidth
        
        let value = query(value: self.storage[index], at: subPosition)
        
        if(value == 0) {return false} else if (value == 1) {return true} else { fatalError("Querying in subscript function returned a value other than 1 or 0")}
    }
    
    private func query(value: UNIT, at position: Int) -> Int {
        
        #warning("incomplete: Bit operations")
        return 1
    }
    
    public func index(after i: Int) -> Int {
        #warning("Wth is this.")
        return i
    }
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return self.storage.count + Int(excess)
    }
    
}
