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
extension BitSet {
  
  public func contains(_ indexValue: Int) -> Bool {
    
    precondition(indexValue >= 0, "Input must be a positive number")
    if (indexValue >= storage.count) {
      return false
    }
    return storage[indexValue]
  }
  
}
