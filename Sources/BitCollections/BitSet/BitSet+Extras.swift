//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitSet {
  /// A subscript operation for querying or updating membership in this
  /// bit set as a boolean value.
  ///
  /// This is operation is a convenience shortcut for the `contains`, `insert`
  /// and `remove` operations, enabling a uniform syntax that resembles the
  /// corresponding `BitArray` subscript operation.
  ///
  ///     var bits: BitSet = [1, 2, 3]
  ///     bits[member: 4] = true // equivalent to `bits.insert(4)`
  ///     bits[member: 2] = false // equivalent to `bits.remove(2)`
  ///     bits[member: 5].toggle()

  ///     print(bits) // [1, 3, 4, 5]
  ///     print(bits[member: 4]) // true, equivalent to `bits.contains(4)`
  ///     print(bits[member: -4]) // false
  ///     print(bits[member: 10]) // false
  ///
  /// Note that unlike `BitArray`'s subscript, this operation may dynamically
  /// resizes the underlying bitmap storage as needed.
  ///
  /// - Parameter member: An integer value. When setting membership via this
  ///    subscript, the value must be nonnegative.
  /// - Returns: `true` if the bit set contains `member`, `false` otherwise.
  /// - Complexity: O(1)
  public subscript(member member: Int) -> Bool {
    get {
      contains(member)
    }
    set {
      if newValue {
        insert(member)
      } else {
        remove(member)
      }
    }
  }

  /// Accesses the contiguous subrange of the collection’s elements that are
  /// contained within a specific integer range.
  ///
  ///     let bits: BitSet = [2, 5, 6, 8, 9]
  ///     let a = bits[3..<7] // [5, 6]
  ///     let b = bits[4...] // [5, 6, 8, 9]
  ///     let c = bits[..<8] // [2, 5, 6]
  ///
  /// This enables you to easily find the closest set member to any integer
  /// value.
  ///
  ///     let firstMemberNotLessThanFive = bits[5...].first // Optional(6)
  ///     let lastMemberBelowFive = bits[..<5].last // Optional(2)
  ///
  /// - Complexity: Equivalent to two invocations of `index(after:)`.
  public subscript(members bounds: Range<Int>) -> Slice<BitSet> {
    let bounds: Range<Index> = _read { handle in
      let bounds = bounds._clampedToUInt()
      var lower = _BitPosition(bounds.lowerBound)
      if lower >= handle.endIndex {
        lower = handle.endIndex
      } else if !handle.contains(lower.value) {
        lower = handle.index(after: lower)
      }
      assert(lower == handle.endIndex || handle.contains(lower.value))

      var upper = _BitPosition(bounds.upperBound)
      if upper <= lower {
        upper = lower
      } else if upper >= handle.endIndex {
        upper = handle.endIndex
      } else if !handle.contains(upper.value) {
        upper = handle.index(after: upper)
      }
      assert(upper == handle.endIndex || handle.contains(upper.value))
      assert(lower <= upper)
      return Range(
        uncheckedBounds: (Index(_position: lower), Index(_position: upper)))
    }
    return Slice(base: self, bounds: bounds)
  }

  /// Accesses the contiguous subrange of the collection’s elements that are
  /// contained within a specific integer range expression.
  ///
  ///     let bits: BitSet = [2, 5, 6, 8, 9]
  ///     let a = bits[members: 3..<7] // [5, 6]
  ///     let b = bits[members: 4...] // [5, 6, 8, 9]
  ///     let c = bits[members: ..<8] // [2, 5, 6]
  ///
  /// This enables you to easily find the closest set member to any integer
  /// value.
  ///
  ///     let firstMemberNotLessThanFive = bits[members: 5...].first
  ///     // Optional(6)
  ///
  ///     let lastMemberBelowFive = bits[members: ..<5].last
  ///     // Optional(2)
  ///
  /// - Complexity: Equivalent to two invocations of `index(after:)`.
  public subscript<R: RangeExpression>(members bounds: R) -> Slice<BitSet>
  where R.Bound == Int
  {
    let bounds = bounds.relative(to: Int.min ..< Int.max)
    return self[members: bounds]
  }

  /// Returns the current set (already sorted).
  ///
  /// - Complexity: O(1)
  public func sorted() -> BitSet { self }
}
