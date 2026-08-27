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
extension UniqueSet where Element: ~Copyable {
  /// Returns a Boolean value that indicates whether the given element exists
  /// in the set.
  ///
  /// This example uses the `contains(_:)` method to test whether an integer is
  /// a member of a set of prime numbers.
  ///
  ///     let primes = UniqueSet(copying: [2, 3, 5, 7])
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
    _storage._find(item).bucket != nil
  }
  
  /// Returns a reference to the given element in the set if it exists.
  ///
  /// This is particularly useful when the equality and hash function of a type
  /// is only based on a partial set of properties, such as an ID. The example
  /// uses `get` with just an employee ID to get a reference to the full
  /// employee value stored in the set.
  ///
  ///     let employees = UniqueSet(...)
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
    _storage.get(item)
  }
  
  // FIXME
  //
  /// Inserts the given element in the set if it is not already present;
  /// otherwise it returns a reference to the given element in the set.
  ///
  /// This is particularly useful when the equality and hash function of a type
  /// is only based on a partial set of properties, such as an ID. The example
  /// uses `get` with just an employee ID to get a reference to the full
  /// employee value stored in the set.
  ///
  ///     let employees = UniqueSet(...)
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
  @_lifetime(&self)
  public mutating func getOrInsert(_ item: consuming Element) -> Ref<Element> {
    _storage.getOrInsert(item)
  }
}

#endif
