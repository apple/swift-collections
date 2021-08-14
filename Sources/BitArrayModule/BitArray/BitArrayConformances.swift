//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//

extension BitArray: Collection, RandomAccessCollection {
  
  
  public func index(after i: Int) -> Int {
    return i + 1
  }
  
  public var count: Int {
    let remaining: Int = (excess == 0) ? WORD.bitWidth : Int(excess)
    return (storage.count)*WORD.bitWidth - (WORD.bitWidth - remaining)
  }
  
  public var startIndex: Int {
    return 0
  }
  
  public var endIndex: Int {
    return count
  }
  
}


extension BitArray: BidirectionalCollection {
  
  public func index(before i: Int) -> Int {
    return i - 1
  }
  
}

extension BitArray: MutableCollection {
  
  public subscript(position: Int) -> Bool  {
    
    get {
      precondition(position < endIndex && position >= startIndex, "Index out of bounds")
      
      let (index, mask) = _split(_position: position)
      return (storage[index] & mask != 0)
    }
    set {
      let (index, mask) = _split(_position: position)
      if (newValue) { storage[index] |= mask } else { storage[index] &= ~mask }
    }
    
  }
  
  private func _split(_position: Int) -> (Int, WORD) {
    
    let index: Int = _position/WORD.bitWidth
    let subPosition: Int = _position - index*WORD.bitWidth
    let mask: WORD = 1 << subPosition
    
    return (index, mask)
    
  }
  
}

extension BitArray: Equatable {
    public static func == (lhs: BitArray, rhs: BitArray) -> Bool {
        return ((lhs.excess == rhs.excess) && (lhs.storage == rhs.storage))
    }
}
