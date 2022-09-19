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

extension SortedSet: ExpressibleByArrayLiteral {
  /// Creates a new sorted set from the contents of an array literal.
  ///
  /// Duplicate elements in the literal are allowed, but the resulting
  /// set will only contain the last occurrence of each.
  ///
  /// Do not call this initializer directly. It is used by the compiler when
  /// you use an array literal. Instead, create a new set using an array
  /// literal as its value by enclosing a comma-separated list of values in
  /// square brackets. You can use an array literal anywhere a set is expected
  /// by the type context.
  ///
  /// - Parameter elements: A variadic list of elements of the new set.
  ///
  /// - Complexity: O(`n log n`) where `n` is the number of elements
  ///   in `elements`.
  @inlinable
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}
