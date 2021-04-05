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

/// A simple bitmap of a fixed number of bits, implementing a sorted set of
/// small nonnegative `Int` values.
///
/// Because `_UnsafeBitset` implements a flat bit vector, it isn't suitable for
/// holding arbitrarily large integers. The maximal element a bitset can store
/// is fixed at its initialization.
@usableFromInline
@frozen
internal struct _UnsafeBitset {
  @usableFromInline
  internal let _words: UnsafeMutableBufferPointer<Word>

  @usableFromInline
  internal var _count: Int

  @inlinable
  @inline(__always)
  internal init(words: UnsafeMutableBufferPointer<Word>, count: Int) {
    self._words = words
    self._count = count
  }

  @inlinable
  @inline(__always)
  internal init(words: UnsafeMutablePointer<Word>, wordCount: Int, count: Int) {
    self._words = UnsafeMutableBufferPointer(start: words, count: wordCount)
    self._count = count
  }

  @inlinable
  @inline(__always)
  internal var count: Int {
    _count
  }
}

extension _UnsafeBitset {
  @usableFromInline
  internal var _actualCount: Int {
    return _words.reduce(0) { $0 + $1.count }
  }
}

extension _UnsafeBitset {
  @inlinable
  @inline(__always)
  static func withTemporaryBitset<R>(
    capacity: Int,
    run body: (inout _UnsafeBitset) throws -> R
  ) rethrows -> R {
    var result: R?
    try _withTemporaryBitset(capacity: capacity) { bitset in
      result = try body(&bitset)
    }
    return result!
  }

  @usableFromInline
  @inline(never)
  static func _withTemporaryBitset(
    capacity: Int,
    run body: (inout _UnsafeBitset) throws -> Void
  ) rethrows {
    let wordCount = _UnsafeBitset.wordCount(forCapacity: capacity)
    if wordCount <= 2 {
      var buffer: (Word, Word) = (.empty, .empty)
      return try withUnsafeMutablePointer(to: &buffer) { p in
        // Homogeneous tuples are layout-compatible with their component type.
        let words = UnsafeMutableRawPointer(p).assumingMemoryBound(to: Word.self)
        var bitset = _UnsafeBitset(words: words, wordCount: wordCount, count: 0)
        return try body(&bitset)
      }
    }
    let words = UnsafeMutableBufferPointer<Word>.allocate(capacity: wordCount)
    words.initialize(repeating: .empty)
    defer { words.deallocate() }
    var bitset = _UnsafeBitset(words: words, count: 0)
    return try body(&bitset)
  }
}

extension _UnsafeBitset {
  @inline(__always)
  internal static func word(for element: Int) -> Int {
    assert(element >= 0)
    // Note: We perform on UInts to get faster unsigned math (shifts).
    let element = UInt(bitPattern: element)
    let capacity = UInt(bitPattern: Word.capacity)
    return Int(bitPattern: element / capacity)
  }

  @inline(__always)
  internal static func bit(for element: Int) -> Int {
    assert(element >= 0)
    // Note: We perform on UInts to get faster unsigned math (masking).
    let element = UInt(bitPattern: element)
    let capacity = UInt(bitPattern: Word.capacity)
    return Int(bitPattern: element % capacity)
  }

  @inline(__always)
  internal static func split(_ element: Int) -> (word: Int, bit: Int) {
    return (word(for: element), bit(for: element))
  }

  @inline(__always)
  internal static func join(word: Int, bit: Int) -> Int {
    assert(bit >= 0 && bit < Word.capacity)
    return word &* Word.capacity &+ bit
  }
}

extension _UnsafeBitset {
  @usableFromInline
  @_effects(readnone)
  @inline(__always)
  internal static func wordCount(forCapacity capacity: Int) -> Int {
    return word(for: capacity &+ Word.capacity &- 1)
  }

  internal var capacity: Int {
    @inline(__always)
    get {
      return _words.count &* Word.capacity
    }
  }

  @inline(__always)
  internal func isValid(_ element: Int) -> Bool {
    return element >= 0 && element < capacity
  }

  @inline(__always)
  internal func contains(_ element: Int) -> Bool {
    assert(isValid(element))
    let (word, bit) = _UnsafeBitset.split(element)
    return _words[word].contains(bit)
  }

  @usableFromInline
  @_effects(releasenone)
  @discardableResult
  internal mutating func insert(_ element: Int) -> Bool {
    assert(isValid(element))
    let (word, bit) = _UnsafeBitset.split(element)
    let inserted = _words[word].insert(bit)
    if inserted { _count += 1 }
    return inserted
  }

  @usableFromInline
  @_effects(releasenone)
  @discardableResult
  internal mutating func remove(_ element: Int) -> Bool {
    assert(isValid(element))
    let (word, bit) = _UnsafeBitset.split(element)
    let removed = _words[word].remove(bit)
    if removed { _count -= 1 }
    return removed
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func clear() {
    guard _words.count > 0 else { return }
    _words.baseAddress!.assign(repeating: .empty, count: _words.count)
    _count = 0
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func insertAll(upTo max: Int) {
    assert(max <= capacity)
    guard max > 0 else { return }
    let (w, b) = _UnsafeBitset.split(max)
    for i in 0 ..< w {
      _count += Word.capacity - _words[i].count
      _words[i] = .allBits
    }
    if b > 0 {
      _count += _words[w].insert(bitsBelow: b)
    }
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func removeAll(upTo max: Int) {
    assert(max <= capacity)
    guard max > 0 else { return }
    let (w, b) = _UnsafeBitset.split(max)
    for i in 0 ..< w {
      _count -= _words[i].count
      _words[i] = .empty
    }
    if b > 0 {
      _count -= _words[w].remove(bitsBelow: b)
    }
  }
}

extension _UnsafeBitset: Sequence {
  @usableFromInline
  internal typealias Element = Int

  @inlinable
  @inline(__always)
  internal var underestimatedCount: Int {
    return count
  }

  @inlinable
  @inline(__always)
  func makeIterator() -> Iterator {
    return Iterator(self)
  }

  @usableFromInline
  @frozen
  internal struct Iterator: IteratorProtocol {
    @usableFromInline
    internal let bitset: _UnsafeBitset

    @usableFromInline
    internal var index: Int

    @usableFromInline
    internal var word: Word

    @inlinable
    internal init(_ bitset: _UnsafeBitset) {
      self.bitset = bitset
      self.index = 0
      self.word = bitset._words.count > 0 ? bitset._words[0] : .empty
    }

    @usableFromInline
    @_effects(releasenone)
    internal mutating func next() -> Int? {
      if let bit = word.next() {
        return _UnsafeBitset.join(word: index, bit: bit)
      }
      while (index + 1) < bitset._words.count {
        index += 1
        word = bitset._words[index]
        if let bit = word.next() {
          return _UnsafeBitset.join(word: index, bit: bit)
        }
      }
      return nil
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
extension _UnsafeBitset {
  @usableFromInline
  @frozen
  internal struct Word {
    @usableFromInline
    internal var value: UInt

    @inlinable
    @inline(__always)
    internal init(_ value: UInt) {
      self.value = value
    }
  }
}

extension _UnsafeBitset.Word {
  @inlinable
  @inline(__always)
  internal static var capacity: Int {
    return UInt.bitWidth
  }

  @inlinable
  @inline(__always)
  internal var count: Int {
    value.nonzeroBitCount
  }

  @inlinable
  @inline(__always)
  internal var isEmpty: Bool {
    value == 0
  }

  @inlinable
  @inline(__always)
  internal func contains(_ bit: Int) -> Bool {
    assert(bit >= 0 && bit < UInt.bitWidth)
    return value & (1 &<< bit) != 0
  }

  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func insert(_ bit: Int) -> Bool {
    assert(bit >= 0 && bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let inserted = value & mask == 0
    value |= mask
    return inserted
  }

  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func remove(_ bit: Int) -> Bool {
    assert(bit >= 0 && bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let removed = value & mask != 0
    value &= ~mask
    return removed
  }
}

extension _UnsafeBitset.Word {
  @inlinable
  @inline(__always)
  internal mutating func insert(bitsBelow bit: Int) -> Int {
    assert(bit >= 0 && bit < Self.capacity)
    let mask: UInt = (1 as UInt &<< bit) &- 1
    let inserted = bit - (value & mask).nonzeroBitCount
    value |= mask
    return inserted
  }

  @inlinable
  @inline(__always)
  internal mutating func remove(bitsBelow bit: Int) -> Int {
    assert(bit >= 0 && bit < Self.capacity)
    let mask = UInt.max &<< bit
    let removed = (value & ~mask).nonzeroBitCount
    value &= mask
    return removed
  }
}

extension _UnsafeBitset.Word {
  @inlinable
  @inline(__always)
  internal static var empty: Self {
    Self(0)
  }

  @inlinable
  @inline(__always)
  internal static var allBits: Self {
    Self(UInt.max)
  }
}

// Word implements Sequence by using a copy of itself as its Iterator.
// Iteration with `next()` destroys the word's value; however, this won't cause
// problems in normal use, because `next()` is usually called on a separate
// iterator, not the original word.
extension _UnsafeBitset.Word: Sequence, IteratorProtocol {
  @inlinable
  internal var underestimatedCount: Int {
    count
  }

  /// Return the index of the lowest set bit in this word,
  /// and also destructively clear it.
  @inlinable
  internal mutating func next() -> Int? {
    guard value != 0 else { return nil }
    let bit = value.trailingZeroBitCount
    value &= value &- 1       // Clear lowest nonzero bit.
    return bit
  }
}
