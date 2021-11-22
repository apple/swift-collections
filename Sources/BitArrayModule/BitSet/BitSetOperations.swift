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
  /// Checks whether the set contains a value or not
  ///
  ///     Example:
  ///     let bitSet: BitSet = [0, 2, 5, 6, 7]
  ///     let doesContain: Bool = bitSet.contains(0)
  ///     print(doesContain) // prints "true"
  ///     doesContain = bitSet.contains(8)
  ///     print(doesContain) // prints "false"
  ///
  /// - Parameter member: An element to look for in the set.
  /// - Returns: `true` if `member` exists in the set; otherwise returns `false`.
  public func contains(_ member: Int) -> Bool {
    
    precondition(member >= 0, "Input must be a positive number")
    if (member >= storage.count) {
      return false
    }
    return storage[member]
  }
  
}
