//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

public struct BitSet {
  
  var storage = BitArray()
  
  public init() { }
  
  public init<S>(_ sequence: __owned S) where S : Sequence, Int == S.Element {
    guard let max = sequence.max() else {
      // sequence must be empty and nothing needs to be done
      return
    }
    let bytes: Int = (max/8) + 1
    
    for _ in 0..<bytes {
      storage.storage.append(0)
    }
    
    for value in sequence {
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
