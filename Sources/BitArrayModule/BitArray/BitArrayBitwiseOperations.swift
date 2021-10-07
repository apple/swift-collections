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

extension BitArray {
  
  /// mutates self by setting the value in each index to true if either self or the passed in BitArray -- or both -- have a true value in that respective index.
  ///
  /// The following example mutates a BitArray to be OR'd with another BitArray
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray.formBitwiseOr(secondBitArray)
  ///     print(Array(bitArray))
  ///     Prints "[true, false, true, true]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  public mutating func formBitwiseOr(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.endIndex {
      self.storage[i] |= other.storage[i]
    }
  }
  /// mutates self by setting the value in each index to true if both self and the passed in BitArray have a true value in that respective index.
  ///
  /// The following example mutates a BitArray to be AND'd with another BitArray
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray.formBitwiseAnd(secondBitArray)
  ///     print(Array(bitArray))
  ///     Prints "[true, false, false, false]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  public mutating func formBitwiseAnd(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] &= other.storage[i]
    }
  }
  /// mutates self by setting the value in each index to true if either self or the passed in BitArray -- but not both -- have a true value in that respective index.
  ///
  /// The following example mutates self to be XOR'd with another BitArray
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray.formBitwiseXor(secondBitArray)
  ///     print(Array(bitArray))
  ///     Prints "[false, false, true, true]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  public mutating func formBitwiseXor(_ other: BitArray) {
    
    precondition(self.storage.count == other.storage.count, "Bitwise operations on BitArrays of different length is currently not supported")
    
    for i in 0..<self.storage.count {
      self.storage[i] ^= other.storage[i]
    }
  }
  /// mutates self by flipping each binary value in self
  ///
  /// The following example mutates self to its own NOT or inverted self
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     bitArray.formBitwiseNot()
  ///     print(Array(bitArray))
  ///     Prints "[false, true, false, true]"
  public mutating func formBitwiseNot() {
    
    if (count == 0) {
      return
    }
    
    let remaining: Int = (excess == 0) ? WORD.bitWidth : Int(excess)
    
    for i in 0..<self.storage.endIndex {
      self.storage[i] = ~self.storage[i]
    }
    
    var mask: WORD = 1 << remaining
    
    // flip the last bits past excess that aren't part of the set back to 0
    for _ in 1...((WORD.bitWidth)-Int(excess)) {
      self.storage[storage.endIndex-1] ^= mask
      mask <<= 1
    }
    
  }
  /// creates and returns a new BitArray by setting the value in each index of the new BitArray to true if either self or the passed in BitArray -- or both -- have a true value in that respective index.
  ///
  /// The following example creates and returns a BitArray that is the OR'd result of self and another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray.bitwiseOr(secondBitArray)
  ///     print(Array(newBitArray))
  ///     Prints "[true, false, true, true]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  /// - Returns: The BitArray that is the XOR'd result of `self` and `other`
  public func bitwiseOr(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseOr(other)
    return copy
  }
  /// creates and returns a new BitArray by setting the value in each index of the new BitArray to true if both self and the passed in BitArray have a true value in that respective index.
  ///
  /// The following example creates and returns a BitArray that is the AND'd result of self and another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray.bitwiseAnd(secondBitArray)
  ///     print(Array(newBitArray))
  ///     Prints "[true, false, false, false]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  /// - Returns: The BitArray that is the AND'd result of `self` and `other`
  public func bitwiseAnd(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseAnd(other)
    return copy
  }
  /// creates a new BitArray by setting the value in each index of the new BitArray to true if either self or the passed in BitArray -- but not both -- have a true value in that respective index.
  ///
  /// The following example creates a new a BitArray that is the XOR'd result of self and another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray.bitwiseOr(secondBitArray)
  ///     print(Array(newBitArray))
  ///     Prints "[false, false, true, true]"
  ///
  /// - Parameters:
  ///   - other: An initialized BitArray. `other` must have the same count as `self`
  /// - Returns: The BitArray that is the XOR'd result of `self` and `other`
  public func bitwiseXor(_ other: BitArray) -> BitArray{
    var copy = self
    copy.formBitwiseXor(other)
    return copy
  }
  /// creates a new BitArray by setting each value in the new BitArray to the opposite value of that in self
  ///
  /// The following example creates a new a BitArray that is the inverse of self
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let newBitArray = bitArray.bitwiseNot()
  ///     print(Array(newBitArray))
  ///     Prints "[false, true, false, true]"
  ///
  /// - Returns: The BitArray that contains the inverse or opposite values of that in self
  public func bitwiseNot() -> BitArray {
    var copy = self
    copy.formBitwiseNot()
    return copy
  }
}

// Overloaded Operators

extension BitArray {
  /// overloaded operator that creates and returns a new BitArray by setting the value in each index to true if either the lhs BitArray or the rhs BitArray -- or both -- have a true value in that respective index.
  ///
  /// The following example creates and returns a BitArray that is the OR'd result of the lhs and rhs
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray | secondBitArray
  ///     print(Array(newBitArray))
  ///     Prints "[true, false, true, true]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  /// - Returns: The BitArray that is the XOR'd result of the lhs and rhs
  public static func | (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseOr(rhs)
    return copy
  }
  /// overloaded operator that creates and returns a new BitArray by setting the value in each index of the new BitArray to true if both the lhs BitArray and the rhs BitArray have a true value in that respective index.
  ///
  /// The following example creates and returns a BitArray that is the AND'd result of self and another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray & secondBitArray
  ///     print(Array(newBitArray))
  ///     Prints "[true, false, false, false]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  /// - Returns: The BitArray that is the AND'd result of the lhs and rhs
  public static func & (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseAnd(rhs)
    return copy
  }
  /// creates a new BitArray by setting the value in each index of the new BitArray to true if either lhs BitArray or the rhs BitArray -- but not both -- have a true value in that respective index.
  ///
  /// The following example creates a new a BitArray that is the XOR'd result of self and another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     let newBitArray = bitArray ^ secondBitArray
  ///     print(Array(newBitArray))
  ///     Prints "[false, false, true, true]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  /// - Returns: The BitArray that is the XOR'd result of the lhs and rhs
  public static func ^ (lhs: BitArray, rhs: BitArray) -> BitArray {
    var copy = lhs
    copy.formBitwiseXor(rhs)
    return copy
  }
  /// The bitwise NOT operator (`~`) is a prefix operator that returns a value in which all the Bools of its argument are flipped
  ///
  /// The following example creates a new a BitArray to be NOT'd with another BitArray
  ///     let bitArray: BitArray = [true, false, true, false]
  ///     let newBitArray = ~bitArray
  ///     print(Array(newBitArray))
  ///     Prints "[false, true, false, true]"
  ///
  /// - Returns: The `BitArray` that contains the inverse or opposite values of that in `self`
  public static prefix func ~ (_ bitArray: BitArray) -> BitArray {
    var copy = bitArray
    copy.formBitwiseNot()
    return copy
  }
  /// overloaded operator that mutates the lhs BitArray by setting the value in each index to true if either the lhs BitArray or the rhs BitArray -- or both -- have a true value in that respective index.
  ///
  /// The following example mutates the lhs to be OR'd with the rhs
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray |= secondBitArray
  ///     print(Array(bitArray))
  ///     Prints "[true, false, true, true]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  public static func |= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseOr(rhs)
  }
  /// overloaded operator that mutates the lhs BitArray by setting the value in each index to true if both the lhs BitArray and the rhs BitArray have a true value in that respective index.
  ///
  /// The following example mutates the lhs to be AND'd with the rhs
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray &= secondBitArray
  ///     print(Array(bitArray))
  ///     Prints "[true, false, false, false]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  public static func &= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseAnd(rhs)
  }
  /// overloaded operator that mutates the lhs BitArray by setting the value in each index to true if either the lhs BitArray or the rhs BitArray -- but not both -- have a true value in that respective index.
  ///
  /// The following example mutates a BitArray to be XOR'd with another BitArray
  ///     var bitArray: BitArray = [true, false, true, false]
  ///     let secondBitArray = [true, false, false, true]
  ///     bitArray ^= secondBitArray
  ///     print(Array(bitArray))
  ///     Prints "[false, false, true, true]"
  ///
  /// - Parameters:
  ///   - lhs: An initialized BitArray
  ///   - rhs: An initialized BitArray. `rhs` must have same count as `lhs`
  public static func ^= (lhs: inout BitArray, rhs: BitArray) {
    lhs.formBitwiseXor(rhs)
  }
  
}
