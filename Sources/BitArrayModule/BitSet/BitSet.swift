//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

public struct BitSet {
  
  var storage = BitArray() // Doesn't this technically make this an ordered set?
  
  public init() { }
  
  public init<S>(_ sequence: __owned S) where S : Sequence, Int == S.Element {
    // to be implemented
  }
  
  public init(arrayLiteral elements: Int...) {
    let largest = elements.max()
    for index in elements {
    }
  }
  
  public init(_ bitArray: BitArray) {
    storage = bitArray
  }
  
  public struct Index {
    var bitArrayIndex: Int
    internal init(bitArrayIndex: Int) { // considering to make it 'public init(_ bitArrayIndex: Int)'
      self.bitArrayIndex = bitArrayIndex
    }
  }
  
}

extension BitSet.Index: Comparable, Hashable {
  
  public static func < (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
    return (lhs.bitArrayIndex < rhs.bitArrayIndex)
  }
  
}
