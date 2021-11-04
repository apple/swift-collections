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

extension CountedSet: ExpressibleByDictionaryLiteral {
  /// Creates a counted set initialized with a dictionary literal.
  ///
  /// Do not call this initializer directly. It is called by the compiler to
  /// handle dictionary literals. To use a dictionary literal as the initial
  /// value of a counted set, enclose a comma-separated list of key-value pairs
  /// in square brackets.
  ///
  /// For example, the code sample below creates a counted set with string keys.
  ///
  ///     let countriesOfOrigin = ["BR": 2, "GH": 1, "JP": 5]
  ///     print(countriesOfOrigin)
  ///     // Prints "["BR", "BR", "JP", "JP", "JP", "JP", "JP", "GH"]"
  ///
  /// - Parameter elements: The element-multiplicity pairs that will make up the
  /// new counted set.
  /// - Precondition: Each element must be unique.
  /// - Precondition: Each multiplicity must be positive.
  @inlinable
  public init(dictionaryLiteral elements: (Element, Int)...) {
    _storage = RawValue(
      uniqueKeysWithValues: elements.lazy.map {
        precondition($0.1.signum() == 1)
        return $0
      }
    )
  }
}

