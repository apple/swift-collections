//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
  
  public func contains(_ indexValue: Int) -> Bool {
    
    precondition(indexValue >= 0, "Input must be a positive number")
    if (indexValue >= storage.count) {
      return false
    }
    return storage[indexValue]
  }
  
}
