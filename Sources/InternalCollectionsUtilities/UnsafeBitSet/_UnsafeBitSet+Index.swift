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

extension _UnsafeBitSet {
  @frozen
  @usableFromInline
  package struct Index: Comparable, Hashable {
    @usableFromInline
    internal typealias _Word = _UnsafeBitSet._Word

    @usableFromInline
    package var value: UInt

    @inlinable
    package init(_ value: UInt) {
      self.value = value
    }

    @inlinable
    package init(_ value: Int) {
      self.value = UInt(value)
    }

    @inlinable
    package init(word: Int, bit: UInt) {
      assert(word >= 0 && word <= Int.max / _Word.capacity)
      assert(bit < _Word.capacity)
      self.value = UInt(word &* _Word.capacity) &+ bit
    }
  }
}

extension _UnsafeBitSet.Index {
  @inlinable
  package var word: Int {
    // Note: We perform on UInts to get faster unsigned math (shifts).
    Int(truncatingIfNeeded: value / UInt(bitPattern: _Word.capacity))
  }

  @inlinable
  package var bit: UInt {
    // Note: We perform on UInts to get faster unsigned math (masking).
    value % UInt(bitPattern: _Word.capacity)
  }

  @inlinable
  package var split: (word: Int, bit: UInt) {
    (word, bit)
  }

  @inlinable
  package var endSplit: (word: Int, bit: UInt) {
    let w = word
    let b = bit
    if w > 0, b == 0 { return (w &- 1, UInt(_Word.capacity)) }
    return (w, b)
  }

  @inlinable
  package static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }

  @inlinable
  package static func <(left: Self, right: Self) -> Bool {
    left.value < right.value
  }

  @inlinable
  package func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  @inlinable
  internal func _successor() -> Self {
    Self(value + 1)
  }

  @inlinable
  internal func _predecessor() -> Self {
    Self(value - 1)
  }
}
