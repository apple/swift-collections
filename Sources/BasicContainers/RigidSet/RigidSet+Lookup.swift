//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @inlinable
  package borrowing func _find(
    _ item: borrowing Element
  ) -> (bucket: _Bucket?, hashValue: Int) {
    let storage = _memberBuf
    if _table.isSmall {
      let bucket = _table.find_Small(tester: { storage[$0] == item })
      return (bucket, 0)
    }
    let hashValue = _hashValue(for: item)
    let bucket = _table.find_Large(
      hashValue: hashValue,
      tester: { storage[$0] == item })
    return (bucket, hashValue)
  }
  
  /// Returns a Boolean value that indicates whether the given element exists
  /// in the set.
  ///
  /// This example uses the `contains(_:)` method to test whether an integer is
  /// a member of a set of prime numbers.
  ///
  ///     let primes = RigidSet(copying: [2, 3, 5, 7])
  ///     let x = 5
  ///     if primes.contains(x) {
  ///         print("\(x) is prime!")
  ///     } else {
  ///         print("\(x). Not prime.")
  ///     }
  ///     // Prints "5 is prime!"
  ///
  /// - Parameter item: An element to look for in the set.
  /// - Returns: `true` if `item` exists in the set; otherwise, `false`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public borrowing func contains(_ item: borrowing Element) -> Bool {
    _find(item).bucket != nil
  }
  
  /// Returns a reference to the given element in the set if it exists.
  ///
  /// This is particularly useful when the equality and hash function of a type
  /// is only based on a partial set of properties, such as an ID. The example
  /// uses `get` with just an employee ID to get a reference to the full
  /// employee value stored in the set.
  ///
  ///     let employees = RigidSet(...)
  ///     let employeeZero = Employee(id: 0)
  ///     if let ref = employees.get(employeeZero) {
  ///       print(ref.value) // Employee(id: 0, name: "Alex", age: 25)
  ///     }
  ///
  /// - Parameter item: An element to look for in the set.
  /// - Returns: A reference to the element if `item` exists in the set;
  ///            otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.4, *)
  @inlinable
  @_lifetime(borrow self)
  public borrowing func get(_ item: borrowing Element) -> Ref<Element>? {
    guard let bucket = _find(item).bucket else {
      return nil
    }
    
    return Ref(unsafeAddress: _memberPtr(at: bucket), borrowing: self)
  }
  
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowValue(at bucket: _Bucket) -> Ref<Element> {
    assert(self._table.isOccupied(bucket))
    return Ref(unsafeAddress: self._memberPtr(at: bucket), borrowing: self)
  }
}

#endif
