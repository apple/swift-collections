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
    
    storage.excess = 0
  }
  
  public init(arrayLiteral elements: Int...) {
    for value in elements {
      while (value >= storage.count) {
        storage.storage.append(0)
      }
      storage[value] = true
    }
    
    storage.excess = 0
  }
  
  public init(_ bitArray: BitArray) {
    storage = bitArray
    
    // clean up overly excess false values
    while(storage.storage.count != 0 && storage.storage[storage.storage.endIndex-1] == 0) {
      storage.storage.removeLast()
    }
    
    storage.excess = 0
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
