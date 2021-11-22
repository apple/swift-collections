//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitSet: Equatable {
  /// Inserts a new member into the set
  ///     The following examples insert a 2 into a set that already has a 2 and a set that doesn't, respectively
  ///         var bitSetWithTwo: BitSet = [0, 2, 4, 5]
  ///         var didInsert: Bool = bitSetWithTwo.insert(2)
  ///         print(didInsert)
  ///         // Prints "false"
  ///         print(Array(bitSetWithTwo))
  ///         // Prints "[0, 2, 4, 5]"
  ///
  ///         var bitSetWithoutTwo: BitSet = [0, 3, 4, 6]
  ///         didInsert = bitSetWithoutTwo.insert(2)
  ///         print(didInsert)
  ///         // Prints "true"
  ///         print(Array(bitSetWithoutTwo))
  ///         // Prints "[0, 2, 3, 4, 6]"
  ///
  /// - Parameter newMember: An element to insert into the set
  /// - Returns: `true` if `newMember` was not contained in the
  ///   set. If an element equal to `newMember` was already contained in the
  ///   set, the method returns `false`. Returned value is discarded without giving a warning if unused
  @discardableResult
  public mutating func insert(_ newMember: Int) -> Bool {
    precondition(newMember >= 0, "Inserts can only be executed with a positive number. Bit sets do not hold negative values.")
    if (newMember >= storage.count) {
      // can also try ceil()
      let padding: Double = (Double(newMember - storage.count + 1)/Double(BitArray.WORD.bitWidth)).rounded(.up)
      storage.storage += Array(repeating: 0, count: Int(padding))
    }
    
    let returnVal = !storage[newMember]
    storage[newMember] = true
    return returnVal
    
  }
  
  internal mutating func _forceInsert(_ newMember: Int) {
    precondition(newMember >= 0, "Inserts can only be executed with a positive number. Bit sets do not hold negative values.")
    while (storage.count-1 < newMember) {
      storage.storage.append(0)
    }
    storage[newMember] = true
  }
  /// Removes a member from the set
  ///     The following examples remove a 2 from a set that has a 2 and a set that doesn't, respectively
  ///         var bitSetWithTwo: BitSet = [0, 2, 4, 5]
  ///         var didRemove: Bool = bitSetWithTwo.remove(2)
  ///         print(didRemove)
  ///         // Prints "true"
  ///         print(Array(bitSetWithTwo))
  ///         // Prints "[0, 4, 5]"
  ///
  ///         var bitSetWithoutTwo: BitSet = [0, 3, 4, 6]
  ///         didRemove = bitSetWithoutTwo.remove(2)
  ///         print(didRemove)
  ///         // Prints "false"
  ///         print(Array(bitSetWithoutTwo))
  ///          // Prints "[0, 3, 4, 6]"
  ///
  /// - Parameter member: An element to remove from the set.
  /// - Returns: `true` if `member` was contained in the
  ///   set. If an element equal to `member` was not already contained in the
  ///   set, the method returns `false`. Returned value is discarded without giving a warning if unused
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
  /// creates a new BitSet that is the resulting union of itself and another set
  /// The union is the set of values that exist in either or both sets
  ///
  ///     The following example creates a set that is the union of two sets
  ///         let firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         let resultSet = firstBitSet.union(secondBitSet)
  ///         print(Array(resultSet)) // prints "[0, 2, 3, 4, 5, 6]"
  ///
  /// - Parameter other: Another BitSet
  /// - Returns: A new BitSet with the elements that are in this set or `other` or both.
  public func union(_ other: BitSet) -> BitSet {
    var newBitSet = self
    newBitSet.formUnion(other)
    return newBitSet
  }
  /// creates a new BitSet that is the resulting intersection of itself and another set
  /// The intersection is the set of values that exist both sets
  ///
  ///     The following example creates a set that is the union of two sets
  ///         let firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         let resultSet = firstBitSet.intersection(secondBitSet)
  ///         print(Array(resultSet)) // prints "[2, 5]"
  ///
  /// - Parameter other: Another BitSet
  /// - Returns: A new BitSet with the elements that are both in this set and `other`.
  public func intersection(_ other: BitSet) -> BitSet {
    var newBitSet = self
    newBitSet.formIntersection(other)
    return newBitSet
  }
  /// creates a new BitSet that is the resulting symmetric difference of itself and another set
  /// The symmetric difference is the set of values that exist one set or the other, but not both
  ///
  ///     The following example creates a set that is the symmetric difference of two sets
  ///         let firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         let resultSet = firstBitSet.symmetricDifference(secondBitSet)
  ///         print(Array(resultSet)) // prints "[0, 3, 4, 6]"
  ///
  /// - Parameter other: Another BitSet
  /// - Returns: A new BitSet with the elements that are in either this set or the other set, but not both
  public func symmetricDifference(_ other: BitSet) -> BitSet {
    var newBitSet = self
    newBitSet.formSymmetricDifference(other)
    return newBitSet
  }
  
  /// mutates self to be the resulting union of itself and another set
  /// The union is the set of values that exist in either or both sets
  ///
  ///     The following example takes a set and transforms it into the union of itself and another set
  ///         var firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         firstBitSet.formUnion(secondBitSet)
  ///         print(Array(firstBitSet)) // prints "[0, 2, 3, 4, 5, 6]"
  ///
  /// - Parameter other: Another BitSet. `other` must be finite
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
          self._forceInsert(a)
        }
      }
    } else {
      for b in 0..<self.storage.storage.count {
        self.storage.storage[b] |= other.storage.storage[b]
      }
    }
  }
  /// mutates self to be the resulting intersection of itself and another set
  /// The intersection is the set of values that exist both sets
  ///
  ///     The following example takes a set and transforms it into the intersection of itself and another set
  ///         var firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         firstBitSet.formIntersection(secondBitSet)
  ///         print(Array(firstBitSet)) // prints "[2, 5]"
  ///
  /// - Parameter other: Another BitSet
  public mutating func formIntersection(_ other: BitSet) {
    let size: Int = (self.storage.storage.count >= other.storage.storage.count) ? other.storage.storage.count : self.storage.storage.count // take the set with the smaller BitArray
    
    for i in 0..<size {
      self.storage.storage[i] &= other.storage.storage[i]
    }
    
    for i in size..<self.storage.storage.count {
      self.storage.storage[i] = 0
    }
  }
  /// mutates self to be the resulting symmetric difference of itself and another set
  /// The symmetric difference is the set of values that exist one set or the other, but not both
  ///
  ///     The following example takes a set and mutates it into the symmetric difference between itself and another set
  ///         var firstBitSet: BitSet = [0, 2, 3, 5]
  ///         let secondBitSet: BitSet = [2, 4, 5, 6]
  ///         firstBitSet.formSymmetricDifference(secondBitSet)
  ///         print(Array(firstBitSet)) // prints "[0, 3, 4, 6]"
  ///
  /// - Parameter other: Another BitSet
  public mutating func formSymmetricDifference(_ other: BitSet) { // can be optimized later
    
    if (other.storage.storage.count > self.storage.storage.count) {
      for i in 0..<self.storage.storage.count {
        self.storage.storage[i] ^= other.storage.storage[i]
      }
      for i in self.storage.storage.count..<other.storage.storage.count {
        self.storage.storage.append(other.storage.storage[i])
      }
    } else {
      for i in 0..<other.storage.storage.count {
        self.storage.storage[i] ^= other.storage.storage[i]
      }
    }
  }
  
  public static func == (lhs: BitSet, rhs: BitSet) -> Bool {
    return (lhs.storage == rhs.storage)
  }
  
}
