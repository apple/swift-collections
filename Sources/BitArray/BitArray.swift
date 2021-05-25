//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray {
    var storage : [UInt8]
    
    public init() {
        storage = []
    }
    
}


// NOTE: Research @inlinable

extension BitArray {
    public func test() {
        print("Nice! We're in test function!")
    }
}

extension BitArray: Collection {
    
    //THE FUN FUNCTION
    public subscript(position: Int) -> Bool {
        #warning("This is definitely wrong. Just have this here to get it to conform to collection for now")
        
        return true
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
        return self.storage.count // for now
        //return _buffer.immutableCount
    }
    
}
