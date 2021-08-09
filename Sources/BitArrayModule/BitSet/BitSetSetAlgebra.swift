//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/14/21.
//

extension BitSet: Equatable {
  
  @discardableResult
  public mutating func insert(_ newMember: Int) -> Bool {
    precondition(member >= 0, "Inserts can only be executed with a positive number. Bit sets do not hold negative values.")
    if (newMember >= storage.count) {
        // can also try ceil()
        let padding: Double = (Double(newMember - storage.count + 1)/Double(BitArray.WORD.bitWidth)).rounded(.up)
        storage.storage += Array(repeating: 0, count: Int(padding))
    }
    
    let returnVal = !storage[newMember]
    storage[newMember] = true
    return returnVal

  }
  
  public mutating func forceInsert(_ newMember: Int) {
    precondition(member >= 0, "Inserts can only be executed with a positive number. Bit sets do not hold negative values.")
    // alternative shown in insert func above
    while (storage.count-1 < newMember) {
      storage.storage.append(0)
    }
    storage[newMember] = true
  }
  
  @discardableResult
  public mutating func remove(_ member: Int) -> Bool {
    precondition(member >= 0, "Removals can only be executed with a positive number. Bit sets do not hold negative values.")
    if (member >= storage.endIndex) {
      return false
    }
    
    let returnVal = storage[member]
    storage[member] = false
    return returnVal
  }
  
  // what is '__consuming'
  public __consuming func union(_ other: BitSet) -> BitSet { // Will need to simplify later (by adjusting the BitArray functions to that they can be called from here
    var newBitSet = self
    newBitSet.formUnion(other)
    return newBitSet
  }
  
  public __consuming func intersection(_ other: BitSet) -> BitSet {
    var newBitSet = BitSet()
    newBitSet.formIntersection(other)
    return newBitSet
  }
  
  public __consuming func symmetricDifference(_ other: BitSet) -> BitSet {
    var copy = self
    copy.formSymmetricDifference(other)
    return copy
  }
  
  
  public mutating func formUnion(_ other: BitSet) {
    
    if (other.storage.count < self.storage.count) {
      for i in 0..<other.storage.storage.count {
        self.storage.storage[i] |= other.storage.storage[i]
      }
    } else if (self.storage.count < other.storage.count){
      for j in 0..<self.storage.storage.count {
        self.storage.storage[j] |= other.storage.storage[j]
      }
      for a in self.storage.count..<other.storage.count {
        if(other.storage[a]) {
          self.forceInsert(a)
        }
      }
    } else {
      for b in 0..<self.storage.storage.count {
        self.storage.storage[b] |= other.storage.storage[b]
      }
    }
    
  }
  
  public mutating func formIntersection(_ other: BitSet) {
    let size: Int = (self.storage.storage.count >= other.storage.storage.count) ? other.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
    
    for i in 0..<size {
      self.storage.storage[i] &= other.storage.storage[i]
    }
    
    for i in size..<self.storage.storage.count {
      self.storage.storage[i] = 0
    }
  }
  
  public mutating func formSymmetricDifference(_ other: BitSet) { // can be optimized later
    self.formIntersection(other)
    for i in 0..<self.storage.storage.count {
      self.storage.storage[i] = ~self.storage.storage[i]
    }
  }
  
  public static func == (lhs: BitSet, rhs: BitSet) -> Bool {
    return (lhs.storage == rhs.storage) // BitArray also conforms to Equatable, so we good here
  }
  
}
