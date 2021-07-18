//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//

extension BitArray: Collection {
  
  
  public func index(after i: Int) -> Int { return i + 1 }
  
  public var count: Int {
    
    let remaining: Int = (excess == 0) ? UNIT.bitWidth : Int(excess)
    return (storage.count)*UNIT.bitWidth - (UNIT.bitWidth - remaining)
    
  }
  
  public var startIndex: Int { return 0 }
  
  public var endIndex: Int { return count }
  
}


extension BitArray: BidirectionalCollection {
  
  public func index(before i: Int) -> Int { return i - 1 }
  
}

extension BitArray: MutableCollection {
  
  public subscript(position: Int) -> Bool  {
    
    get {
      
      // any other checks needed?
      precondition(position < endIndex && position >= startIndex, "Index out of bounds")
      
      let (index, mask) = _split(_position: position)
      return (storage[index] & mask != 0)
    }
    set {
      let (index, mask) = _split(_position: position)
      if (newValue) { storage[index] |= mask } else { storage[index] &= ~mask }
    }
    
  }
  
  internal func _split(_position: Int) -> (Int, UInt8) { // made internal so other files can access
    
    let index: Int = _position/UNIT.bitWidth
    let subPosition: Int = _position - index*UNIT.bitWidth
    let mask: UInt8 = 1 << subPosition
    
    return (index, mask)
    
  }
  
}

extension BitArray: RandomAccessCollection, RangeReplaceableCollection {
  // Index is an Integer type which already is Strideable, hence nothing for RandomAccess
  // ADD REPLACESUBRANGE
}

extension BitArray: Equatable {
  public static func == (lhs: BitArray, rhs: BitArray) -> Bool {
    if ((lhs.storage == rhs.storage) && (lhs.excess == rhs.excess)) {
      return true
    } else {
      return false
    }
  }
}
