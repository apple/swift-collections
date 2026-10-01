//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An unsafe-unowned bitset view over `UInt` storage, providing bit set
/// primitives.
@frozen
@usableFromInline
@unsafe
package struct _UnsafeBitSet {
  /// An unsafe-unowned storage view.
  @usableFromInline
  package let _words: UnsafeBufferPointer<_Word>

#if DEBUG
  /// True when this handle does not support table mutations.
  /// (This is only checked in debug builds.)
  @usableFromInline
  @safe
  internal let _mutable: Bool
#endif

  @inlinable
  @inline(__always)
  @safe
  package func ensureMutable() {
#if DEBUG
    assert(_mutable)
#endif
  }

  @inlinable
  @inline(__always)
  package var _mutableWords: UnsafeMutableBufferPointer<_Word> {
    ensureMutable()
    return unsafe UnsafeMutableBufferPointer(mutating: _words)
  }

  @inlinable
  @inline(__always)
  package init(
    words: UnsafeBufferPointer<_Word>,
    mutable: Bool
  ) {
    assert(unsafe words.baseAddress != nil)
    unsafe self._words = words
#if DEBUG
    self._mutable = mutable
#endif
  }

  @inlinable
  @inline(__always)
  package init(
    words: UnsafeMutableBufferPointer<_Word>,
    mutable: Bool
  ) {
    unsafe self.init(words: UnsafeBufferPointer(words), mutable: mutable)
  }
}

extension _UnsafeBitSet {
  @inlinable
  @inline(__always)
  @safe
  package var wordCount: Int {
    unsafe _words.count
  }
}

extension _UnsafeBitSet {
  @inlinable
  @inline(__always)
  package static func withTemporaryBitSet<R>(
    capacity: Int,
    run body: (inout _UnsafeBitSet) throws -> R
  ) rethrows -> R {
    let wordCount = _UnsafeBitSet.wordCount(forCapacity: UInt(capacity))
    return unsafe try withTemporaryBitSet(wordCount: wordCount, run: body)
  }

  @inlinable
  @inline(__always)
  package static func withTemporaryBitSet<R>(
    wordCount: Int,
    run body: (inout Self) throws -> R
  ) rethrows -> R {
    var result: R?
    unsafe try _withTemporaryBitSet(wordCount: wordCount) { bitset in
      result = unsafe try body(&bitset)
    }
    return result!
  }

  @inline(never)
  @usableFromInline
  internal static func _withTemporaryBitSet(
    wordCount: Int,
    run body: (inout Self) throws -> Void
  ) rethrows {
    unsafe try _withTemporaryUninitializedBitSet(wordCount: wordCount) { handle in
      unsafe handle._mutableWords.initialize(repeating: .empty)
      unsafe try body(&handle)
    }
  }

  internal static func _withTemporaryUninitializedBitSet(
    wordCount: Int,
    run body: (inout Self) throws -> Void
  ) rethrows {
    assert(wordCount >= 0)
    return try withUnsafeTemporaryAllocation(
      of: _Word.self, capacity: wordCount
    ) { words in
      var bitset = unsafe Self(words: words, mutable: true)
      return unsafe try body(&bitset)
    }
  }
}

extension _UnsafeBitSet {
  @_effects(readnone)
  @inlinable @inline(__always)
  @safe
  package static func wordCount(forCapacity capacity: UInt) -> Int {
    _Word.wordCount(forBitCount: capacity)
  }

  @inlinable @inline(__always)
  @safe
  package var capacity: UInt {
    UInt(wordCount &* _Word.capacity)
  }

  @inlinable @inline(__always)
  @safe
  internal func isWithinBounds(_ element: UInt) -> Bool {
    element < capacity
  }

  @_effects(releasenone)
  @inline(__always)
  @usableFromInline
  package func contains(_ element: UInt) -> Bool {
    let (word, bit) = Index(element).split
    guard word < wordCount else { return false }
    return unsafe _words[word].contains(bit)
  }

  @_effects(releasenone)
  @usableFromInline
  @discardableResult
  package mutating func insert(_ element: UInt) -> Bool {
    ensureMutable()
    assert(isWithinBounds(element))
    let index = Index(element)
    return unsafe _mutableWords[index.word].insert(index.bit)
  }

  @_effects(releasenone)
  @usableFromInline
  @discardableResult
  package mutating func remove(_ element: UInt) -> Bool {
    ensureMutable()
    let index = Index(element)
    if unsafe index.word >= _words.count { return false }
    return unsafe _mutableWords[index.word].remove(index.bit)
  }

  @_effects(releasenone)
  @usableFromInline
  package mutating func update(_ member: UInt, to newValue: Bool) -> Bool {
    ensureMutable()
    let (w, b) = Index(member).split
    unsafe _mutableWords[w].update(b, to: newValue)
    return w == wordCount &- 1
  }

  @_effects(releasenone)
  @usableFromInline
  package mutating func insertAll(upTo max: UInt) {
    assert(max <= capacity)
    guard max > 0 else { return }
    let (w, b) = Index(max).split
    for i in 0 ..< w {
      unsafe _mutableWords[i] = .allBits
    }
    if b > 0 {
      unsafe _mutableWords[w].insertAll(upTo: b)
    }
  }

  @_alwaysEmitIntoClient
  @usableFromInline
  @inline(__always)
  @discardableResult
  package mutating func insert(_ element: Int) -> Bool {
    precondition(element >= 0)
    return unsafe insert(UInt(bitPattern: element))
  }

  @_alwaysEmitIntoClient
  @usableFromInline
  @inline(__always)
  @discardableResult
  package mutating func remove(_ element: Int) -> Bool {
    guard element >= 0 else { return false }
    return unsafe remove(UInt(bitPattern: element))
  }

  @_alwaysEmitIntoClient
  @usableFromInline
  @inline(__always)
  package mutating func insertAll(upTo max: Int) {
    precondition(max >= 0)
    return unsafe insertAll(upTo: UInt(bitPattern: max))
  }
}

extension _UnsafeBitSet: @unsafe Sequence {
  @usableFromInline
  package typealias Element = UInt

  @inlinable
  @inline(__always)
  package var underestimatedCount: Int {
    unsafe count // FIXME: really?
  }

  @inlinable
  @inline(__always)
  package func makeIterator() -> Iterator {
    return unsafe Iterator(self)
  }

  @frozen
  @usableFromInline
  @unsafe
  package struct Iterator: IteratorProtocol {
    @usableFromInline
    internal let _bitset: _UnsafeBitSet

    @usableFromInline
    internal var _index: Int

    @usableFromInline
    @safe
    internal var _word: _Word

    @inlinable
    internal init(_ bitset: _UnsafeBitSet) {
      unsafe self._bitset = bitset
      unsafe self._index = 0
      unsafe self._word = bitset.wordCount > 0 ? bitset._words[0] : .empty
    }

    @_effects(releasenone)
    @usableFromInline
    package mutating func next() -> UInt? {
      if let bit = _word.next() {
        return unsafe Index(word: _index, bit: bit).value
      }
      while unsafe (_index + 1) < _bitset.wordCount {
        unsafe _index += 1
        unsafe _word = _bitset._words[_index]
        if let bit = _word.next() {
          return unsafe Index(word: _index, bit: bit).value
        }
      }
      return nil
    }
  }
}

extension _UnsafeBitSet: @unsafe BidirectionalCollection {
  @inlinable
  package var count: Int {
    assert(unsafe _words.count <= Int.max / _Word.capacity)
    return unsafe _words.reduce(0) { $0 &+ $1.count }
  }

  @inlinable
  @inline(__always)
  package var isEmpty: Bool {
    unsafe _words.firstIndex(where: { !$0.isEmpty }) == nil
  }

  @inlinable
  package var startIndex: Index {
    let word = unsafe _words.firstIndex { !$0.isEmpty }
    guard let word = word else { return endIndex }
    return unsafe Index(word: word, bit: _words[word].firstMember!)
  }

  @inlinable
  @safe
  package var endIndex: Index {
    Index(word: wordCount, bit: 0)
  }
  
  @inlinable
  package subscript(position: Index) -> UInt {
    position.value
  }

  @_effects(releasenone)
  @usableFromInline
  package func index(after index: Index) -> Index {
    precondition(index < endIndex, "Index out of bounds")
    var word = index.word
    var w = unsafe _words[word]
    w.removeAll(through: index.bit)
    while w.isEmpty {
      word += 1
      guard word < wordCount else {
        return Index(word: wordCount, bit: 0)
      }
      w = unsafe _words[word]
    }
    return Index(word: word, bit: w.firstMember!)
  }

  @_effects(releasenone)
  @usableFromInline
  package func index(before index: Index) -> Index {
    precondition(index <= endIndex, "Index out of bounds")
    var word = index.word
    var w: _Word
    if index.bit > 0 {
      w = unsafe _words[word]
      w.removeAll(from: index.bit)
    } else {
      w = .empty
    }
    while w.isEmpty {
      word -= 1
      precondition(word >= 0, "Cannot advance below startIndex")
      w = unsafe _words[word]
    }
    return Index(word: word, bit: w.lastMember!)
  }
  
  @_effects(releasenone)
  @usableFromInline
  package func distance(from start: Index, to end: Index) -> Int {
    precondition(start <= endIndex && end <= endIndex, "Index out of bounds")
    let isNegative = end < start
    let (start, end) = (Swift.min(start, end), Swift.max(start, end))
    
    let (w1, b1) = start.split
    let (w2, b2) = end.split
    
    if w1 == w2 {
      guard w1 < wordCount else { return 0 }
      let mask = _Word(from: b1, to: b2)
      let c = unsafe _words[w1].intersection(mask).count
      return isNegative ? -c : c
    }
    
    var c = 0
    var w = w1
    guard w < wordCount else { return 0 }
    
    c &+= unsafe _words[w].subtracting(_Word(upTo: b1)).count
    w &+= 1
    while w < w2 {
      c &+= unsafe _words[w].count
      w &+= 1
    }
    guard w < wordCount else { return isNegative ? -c : c }
    c &+= unsafe _words[w].intersection(_Word(upTo: b2)).count
    return isNegative ? -c : c
  }
  
  @_effects(releasenone)
  @usableFromInline
  package func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    precondition(unsafe i == endIndex || contains(i.value), "Invalid index")
    guard distance != 0 else { return i }
    var remaining = distance.magnitude
    if distance > 0 {
      var (w, b) = i.split
      precondition(w < wordCount, "Index out of bounds")
      if let v = unsafe _words[w].subtracting(_Word(upTo: b)).nthElement(&remaining) {
        return Index(word: w, bit: v)
      }
      while true {
        w &+= 1
        guard w < wordCount else { break }
        if let v = unsafe _words[w].nthElement(&remaining) {
          return Index(word: w, bit: v)
        }
      }
      precondition(remaining == 0, "Index out of bounds")
      return endIndex
    }

    // distance < 0
    remaining -= 1
    var (w, b) = i.endSplit
    if w < wordCount {
      if let v = unsafe _words[w].intersection(_Word(upTo: b)).nthElementFromEnd(&remaining) {
        return Index(word: w, bit: v)
      }
    }
    while true {
      precondition(w > 0, "Index out of bounds")
      w &-= 1
      if let v = unsafe _words[w].nthElementFromEnd(&remaining) {
        return Index(word: w, bit: v)
      }
    }
  }
  
  @_effects(releasenone)
  @usableFromInline
  package func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    precondition(i <= endIndex && limit <= endIndex, "Index out of bounds")
    precondition(unsafe i == endIndex || contains(i.value), "Invalid index")
    guard distance != 0 else { return i }
    var remaining = distance.magnitude
    if distance > 0 {
      guard i <= limit else {
        return unsafe self.index(i, offsetBy: distance)
      }
      var (w, b) = i.split
      if w < wordCount,
         let v = unsafe _words[w].subtracting(_Word(upTo: b)).nthElement(&remaining)
      {
        let r = Index(word: w, bit: v)
        return r <= limit ? r : nil
      }
      let maxWord = Swift.min(wordCount - 1, limit.word)
      while w < maxWord {
        w &+= 1
        if let v = unsafe _words[w].nthElement(&remaining) {
          let r = Index(word: w, bit: v)
          return r <= limit ? r : nil
        }
      }
      return remaining == 0 && limit == endIndex ? endIndex : nil
    }
    
    // distance < 0
    guard i >= limit else {
      return unsafe self.index(i, offsetBy: distance)
    }
    remaining &-= 1
    var (w, b) = i.endSplit
    if w < wordCount {
      if let v = unsafe _words[w].intersection(_Word(upTo: b)).nthElementFromEnd(&remaining) {
        let r = Index(word: w, bit: v)
        return r >= limit ? r : nil
      }
    }
    let minWord = limit.word
    while w > minWord {
      w &-= 1
      if let v = unsafe _words[w].nthElementFromEnd(&remaining) {
        let r = Index(word: w, bit: v)
        return r >= limit ? r : nil
      }
    }
    return nil
  }
}
