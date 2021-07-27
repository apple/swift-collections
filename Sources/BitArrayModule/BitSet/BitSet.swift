//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

public struct BitSet: ExpressibleByArrayLiteral {
  
  var storage = BitArray()
  
  public init() { }
  
  public init<S>(_ sequence: __owned S) where S : Sequence, Int == S.Element {
    for value in sequence {
      while (value >= storage.count) {
        storage.storage.append(0)
      }
      storage[value] = true
    }
  }
  
  public init(arrayLiteral elements: Int...) {
    for value in elements {
      while (value >= storage.count) {
        storage.storage.append(0)
      }
      storage[value] = true
    }
  }
  
  public init(_ bitArray: BitArray) {
    storage = bitArray // Is this assignment working properly? How do I know? In other languages, assigning an array to a variable doesn't work quite right...
  }
  
  public struct Index {
    var bitArrayIndex: Int
    internal init(bitArrayIndex: Int) {
      self.bitArrayIndex = bitArrayIndex
    }
  }
  
}

extension BitSet.Index: Comparable, Hashable {
  
  public static func < (lhs: BitSet.Index, rhs: BitSet.Index) -> Bool {
    return (lhs.bitArrayIndex < rhs.bitArrayIndex)
  }
  
}
