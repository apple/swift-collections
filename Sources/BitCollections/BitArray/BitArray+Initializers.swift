//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension BitArray {
  /// Initialize a bit array from a bit set.
  ///
  /// The result contains exactly as many bits as the maximum item in
  /// the source set, plus one. If the set is empty, the result will
  /// be empty, too.
  ///
  ///     BitArray([] as BitSet)        // (empty)
  ///     BitArray([0] as BitSet)       // 1
  ///     BitArray([1] as BitSet)       // 10
  ///     BitArray([1, 2, 4] as BitSet) // 1011
  ///     BitArray([7] as BitSet)       // 1000000
  ///
  /// - Complexity: O(1)
  public init(_ set: BitSet) {
    guard let l = set.last else { self.init(); return }
    self.init(_storage: set._storage, count: l + 1)
  }

  /// Initialize a bit array from the binary representation of an integer.
  /// The result will contain exactly `value.bitWidth` bits.
  ///
  ///     BitArray(bitPattern: 3 as UInt8)  // 00000011
  ///     BitArray(bitPattern: 42 as Int8)  // 00101010
  ///     BitArray(bitPattern: -1 as Int8)  // 11111111
  ///     BitArray(bitPattern: 3 as Int16)  // 0000000000000111
  ///     BitArray(bitPattern: 42 as Int16) // 0000000000101010
  ///     BitArray(bitPattern: -1 as Int16) // 1111111111111111
  ///     BitArray(bitPattern: 3 as Int)    // 0000000000...0000000111
  ///     BitArray(bitPattern: 42 as Int)   // 0000000000...0000101010
  ///     BitArray(bitPattern: -1 as Int)   // 1111111111...1111111111
  ///
  /// - Complexity: O(value.bitWidth)
  public init(bitPattern value: some BinaryInteger) {
    var words = value.words.map { _Word($0) }
    let count = value.bitWidth
    if words.isEmpty {
      precondition(count == 0, "Inconsistent bitWidth")
    } else {
      let (w, b) = _UnsafeHandle._BitPosition(count).endSplit
      precondition(words.count == w + 1, "Inconsistent bitWidth")
      words[w].formIntersection(_Word(upTo: b))
    }
    self.init(_storage: words, count: count)
  }

  /// Creates a new, empty bit array with preallocated space for at least the
  /// specified number of elements.
  public init(minimumCapacity: Int) {
    self.init()
    reserveCapacity(minimumCapacity)
  }
}

extension BitArray {
  @usableFromInline
  internal func _foreachTwosComplementWordDownward(
    isSigned: Bool,
    body: (Int, UInt) -> Bool
  ) -> Bool {
    self._read {
      guard $0._words.count > 0 else { return false }

      var isNegative = false
      let end = $0.end.endSplit
      assert(end.bit > 0)
      let last = $0._words[end.word]
      if isSigned, last.contains(end.bit - 1) {
        // Sign extend last word
        isNegative = true
        if !body(end.word, last.union(_Word(upTo: end.bit).complement()).value) {
          return isNegative
        }
      } else if !body(end.word, last.value) {
        return isNegative
      }
      for i in stride(from: end.word - 1, through: 0, by: -1) {
        if !body(i, $0._words[i].value) { return isNegative }
      }
      return isNegative
    }
  }
}
