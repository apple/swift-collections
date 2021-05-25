//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray {
    typealias UNIT = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
    var storage : [UNIT]
    
    public init() {
        storage = []
    }
    
}


// NOTE: Research @inlinable

extension BitArray {
    public func test() {
        print("Nice! We're in test function!")
    }
    
    mutating func append(_ newValue: Bool) {
        
    }
}

extension BitArray: Collection {
    
    //THE FUN FUNCTION
    public subscript(position: Int) -> Bool {
        #warning("This is definitely wrong. Just have this here to get it to conform to collection for now")
        // first get the appropriate element in storage
        let index: Int = position/UNIT.bitWidth
        let subPosition: Int = position - index*UNIT.bitWidth
        
        let value = query(index: self.storage[index], at: subPosition)
        
        if(value == 0) {return false} else if (value == 1) {return true} else { fatalError("Querying in subscript function returned a value other than 1 or 0")}
    }
    
    private func query(index: UNIT, at position: Int) -> Int {
        
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
        get {
          return _getCount()
        }
    }
    
    internal func _getCount() -> Int {
        #warning("fix this get count function to be, ummm, appropriate lol. Oh! And also try to see how this is internally gonna differ from an array. Especially considering the storage literally is an array.")
        return self.storage.count*UNIT.bitWidth // for now
        //return _buffer.immutableCount
    }
    
}
