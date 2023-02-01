//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray {
  /// Stores the result of performing a bitwise OR operation on two
  /// equal-sized bit arrays in the left-hand-side variable.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Complexity: O(left.count)
  public static func |=(left: inout Self, right: Self) {
    precondition(left.count == right.count)
    left._update { target in
      right._read { source in
        for i in 0 ..< target._words.count {
          target._mutableWords[i].formUnion(source._words[i])
        }
      }
    }
    left._checkInvariants()
  }

  /// Returns the result of performing a bitwise OR operation on two
  /// equal-sized bit arrays.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Returns: The bitwise OR of `left` and `right`.
  /// - Complexity: O(left.count)
  public static func |(left: Self, right: Self) -> Self {
    precondition(left.count == right.count)
    var result = left
    result |= right
    return result
  }

  /// Stores the result of performing a bitwise AND operation on two given
  /// equal-sized bit arrays in the left-hand-side variable.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Complexity: O(left.count)
  public static func &=(left: inout Self, right: Self) {
    precondition(left.count == right.count)
    left._update { target in
      right._read { source in
        for i in 0 ..< target._words.count {
          target._mutableWords[i].formIntersection(source._words[i])
        }
      }
    }
    left._checkInvariants()
  }

  /// Returns the result of performing a bitwise AND operation on two
  /// equal-sized bit arrays.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Returns: The bitwise AND of `left` and `right`.
  /// - Complexity: O(left.count)
  public static func &(left: Self, right: Self) -> Self {
    precondition(left.count == right.count)
    var result = left
    result &= right
    return result
  }

  /// Stores the result of performing a bitwise XOR operation on two given
  /// equal-sized bit arrays in the left-hand-side variable.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Complexity: O(left.count)
  public static func ^=(left: inout Self, right: Self) {
    precondition(left.count == right.count)
    left._update { target in
      right._read { source in
        for i in 0 ..< target._words.count {
          target._mutableWords[i].formSymmetricDifference(source._words[i])
        }
      }
    }
    left._checkInvariants()
  }

  /// Returns the result of performing a bitwise XOR operation on two
  /// equal-sized bit arrays.
  ///
  /// - Parameter left: A bit array.
  /// - Parameter right: Another bit array of the same size.
  /// - Returns: The bitwise XOR of `left` and `right`.
  /// - Complexity: O(left.count)
  public static func ^(left: Self, right: Self) -> Self {
    precondition(left.count == right.count)
    var result = left
    result ^= right
    return result
  }

  /// Returns the complement of the given bit array.
  ///
  /// - Parameter value: A bit array.
  /// - Returns: A bit array constructed by flipping each bit in `value`.
  ///     flipped.
  /// - Complexity: O(value.count)
  public static prefix func ~(value: Self) -> Self {
    var result = value
    result.toggleAll()
    return result
  }

  public mutating func toggleAll() {
    _update { handle in
      let w = handle._mutableWords
      for i in 0 ..< handle._words.count {
        w[i].formComplement()
      }
      let p = handle.end
      if p.bit > 0 {
        w[p.word].subtract(_Word(upTo: p.bit).complement())
      }
    }
    _checkInvariants()
  }

  public mutating func toggleAll(in range: Range<Int>) {
    precondition(range.upperBound <= count, "Range out of bounds")
    _update { handle in
      let words = handle._mutableWords
      let start = _BitPosition(range.lowerBound)
      let end = _BitPosition(range.upperBound)
      if start.word == end.word {
        let bits = _Word(from: start.bit, to: end.bit)
        words[start.word].formSymmetricDifference(bits)
        return
      }
      words[start.word].formSymmetricDifference(
        _Word(upTo: start.bit).complement())
      for i in stride(from: start.word + 1, to: end.word, by: 1) {
        words[i].formComplement()
      }
      if end.bit > 0 {
        words[end.word].formSymmetricDifference(_Word(upTo: end.bit))
      }
    }
  }

  @inlinable
  public mutating func toggleAll<R: RangeExpression>(
    in range: R
  ) where R.Bound == Int {
    toggleAll(in: range.relative(to: self))
  }
}
