//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/14/21.
//

extension BitSet: Equatable {
  
  public mutating func insert(_ newMember: __owned Int) -> Bool {
    while (storage.count-1 < newMember) {
      storage.storage.append(0)
    }
    
    if (storage[newMember]) {
      return false
    } else {
      storage[newMember] = true
      return true
    }
    /* // alternative:
     let returnVal = !storage[newMember]
     storage[newMember] = true
     return returnVal
     */
  }
  
  public mutating func forceInsert(_ newMember: __owned Int) {
    while (storage.count-1 < newMember) {
      storage.storage.append(0)
    }
    storage[newMember] = true
  }
  
  public mutating func remove(_ member: Int) -> Bool {
    if (member >= storage.endIndex) {
      return false // I chose to do this instead of crash since this is a Set, and there aren't really array index limits to a set
    }
    
    // alternative: similar to how its done in insert function
    let returnVal = storage[member]
    storage[member] = false
    return returnVal
  }
  
  // what is '__consuming' and '__owned'? 
  public __consuming func union(_ other: __owned BitSet) -> BitSet { // Will need to simplify later (by adjusting the BitArray functions to that they can be called from here
    var newBitSet = BitSet()
    
    if (other.storage.count < self.storage.count) {
      for i in 0..<other.storage.storage.count {
        let newVal: UInt8 = self.storage.storage[i] | other.storage.storage[i]
        newBitSet.storage.storage.append(newVal)
      }
      for a in other.storage.count..<self.storage.count {
        if(self.storage[a]) {
          newBitSet.forceInsert(a)
        }
      }
    } else if (self.storage.count < other.storage.count){
      for j in 0..<self.storage.storage.count {
        let newVal = storage.storage[j] | other.storage.storage[j]
        newBitSet.storage.storage.append(newVal)
      }
      for b in self.storage.count..<other.storage.count {
        if(other.storage[b]) {
          newBitSet.forceInsert(b)
        }
      }
    } else {
      for c in 0..<self.storage.storage.count {
        let newVal = self.storage.storage[c] | other.storage.storage[c]
        newBitSet.storage.storage.append(newVal)
      }
    }
    return newBitSet
  }
  
  public __consuming func intersection(_ other: BitSet) -> BitSet {
    let size: Int = (self.storage.storage.count >= other.storage.storage.count) ? other.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
    var newBitSet = BitSet()
    
    for i in 0..<size {
      newBitSet.storage.storage.append(self.storage.storage[i] & other.storage.storage[i])
    }
    
    for i in size..<self.storage.storage.count {
      newBitSet.storage.storage[i] = 0
    }
    
    return newBitSet
  }
  
  public __consuming func symmetricDifference(_ other: __owned BitSet) -> BitSet {
    var copy = self
    copy.formSymmetricDifference(other)
    return copy
  }
  
  
  public mutating func formUnion(_ other: __owned BitSet) {
    if (other.storage.count < self.storage.count) {
      for i in 0..<other.storage.storage.count {
        self.storage.storage[i] |= other.storage.storage[i]
      }
    } else if (self.storage.count < other.storage.count){
      for j in 0..<self.storage.storage.count {
        self.storage.storage[j] |= other.storage.storage[j]
      }
      for a in self.storage.count..<other.storage.count { // why does this work and doing storage.storage like the other for-loops not?
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
  
  public mutating func formSymmetricDifference(_ other: __owned BitSet) { // can be optimized later
    self.formIntersection(other)
    for i in 0..<self.storage.storage.count {
      self.storage.storage[i] = ~self.storage.storage[i]
    }
  }
  
  public static func == (lhs: BitSet, rhs: BitSet) -> Bool {
    return (lhs.storage == rhs.storage) // BitArray also conforms to Equatable, so we good here
  }
  
}
