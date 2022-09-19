//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
@frozen
internal struct _BitPosition: Comparable, Hashable {
  @usableFromInline
  internal var value: UInt

  @inlinable
  internal init(_ value: UInt) {
    self.value = value
  }

  @inlinable
  internal init(_ value: Int) {
    self.value = UInt(value)
  }

  @inlinable
  internal init(word: Int, bit: UInt) {
    assert(word >= 0 && word <= Int.max / _Word.capacity)
    assert(bit < _Word.capacity)
    self.value = UInt(word &* _Word.capacity) &+ bit
  }

  @inlinable
  internal var word: Int {
    // Note: We perform on UInts to get faster unsigned math (shifts).
    Int(truncatingIfNeeded: value / UInt(bitPattern: _Word.capacity))
  }

  @inlinable
  internal var bit: UInt {
    // Note: We perform on UInts to get faster unsigned math (masking).
    value % UInt(bitPattern: _Word.capacity)
  }

  @inlinable
  internal var split: (word: Int, bit: UInt) {
    (word, bit)
  }

  @inlinable
  internal var endSplit: (word: Int, bit: UInt) {
    let w = word
    let b = bit
    if w > 0, b == 0 { return (w &- 1, UInt(_Word.capacity)) }
    return (w, b)
  }

  @inlinable
  static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }

  @inlinable
  static func <(left: Self, right: Self) -> Bool {
    left.value < right.value
  }

  @inlinable
  func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  @inlinable
  func successor() -> Self {
    Self(value + 1)
  }

  @inlinable
  func predecessor() -> Self {
    Self(value - 1)
  }
}
