//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//

extension BitArray: Collection {
     
    public func index(after i: Int) -> Int {
        /* if (i == endIndex) { return i }  // Removed due to conversation about putting all checks within subscript function
        else { return i + 1 } */
        return i + 1
    }
    
    public var startIndex: Int { // would it be worth making this a stored propery (public var startIndex: Int = 0) and place it in BitArray.swift ?
        return 0
    }
    
    public var count: Int {
        var remaining: Int { get { if (excess == 0) { return UNIT.bitWidth } else { return Int(excess)}} }
        return (self.storage.count)*UNIT.bitWidth - (UNIT.bitWidth - remaining)
    }
    
    public var endIndex: Int { get { if (count == 0) { return count + 1} else { return count } } } // switched count and endIndex code and altered closure to meet this "edge case"
   
}


extension BitArray: BidirectionalCollection {
    
    public func index(before i: Int) -> Int { // no checks since, from out conversation, we'll be doing all checks within subscript
        return i - 1
    }
    
}

extension BitArray: MutableCollection {
    public subscript(position: Int) -> Bool  {
        // how can I retain some of my code from get to use in set
        
        get { // I read online that _read is not officially part of the language yet, and to change this to get
            
            // any other checks needed?
            if (position >= endIndex || position < startIndex) {
                fatalError("Index out of bounds") // can we do something other than this? And how do we test for this?
            }
            
            let index: Int = position/UNIT.bitWidth
            let subPosition: Int = position - index*UNIT.bitWidth
            
            let mask: UInt8 = 1 << subPosition
            if (storage[index] & mask == 0) { return false } else { return true }
        }
        set(newValue) {
            let index: Int = position/UNIT.bitWidth
            let subPosition: Int = position - index*UNIT.bitWidth
            let mask: UInt8 = 1 << subPosition
            
            var currentVal: Bool { get { if (storage[index] & mask == 0) { return false } else { return true } } }
            
            if (currentVal == newValue) {  } else {  storage[index] = storage[index] ^ mask}
        }
    }
    
    
}

extension BitArray: RandomAccessCollection, RangeReplaceableCollection {
    // Index is an Integer type which already is Strideable, hence nothing for RandomAccess
    // ... that's all for RangeReplaceable?? -- ADD FUNCTION
}
