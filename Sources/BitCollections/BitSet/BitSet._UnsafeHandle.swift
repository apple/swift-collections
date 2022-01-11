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

extension BitSet {
  /// An unsafe-unowned bitset view over `UInt` storage, providing bit set
  /// primitives.
  @usableFromInline
  @frozen
  internal struct _UnsafeHandle {
    /// An unsafe-unowned storage view.
    @usableFromInline
    internal let _words: UnsafeBufferPointer<_Word>

    /// The number of integers in this bit set.
    @usableFromInline
    internal var _count: Int

#if DEBUG
    /// True when this handle does not support table mutations.
    /// (This is only checked in debug builds.)
    @usableFromInline
    internal let _mutable: Bool
#endif

    internal var _mutableWords: UnsafeMutableBufferPointer<_Word> {
#if DEBUG
      assert(_mutable)
#endif
      return UnsafeMutableBufferPointer(mutating: _words)
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafeBufferPointer<_Word>,
      count: Int,
      mutable: Bool
    ) {
      assert(words.baseAddress != nil)
      self._words = words
      self._count = count
#if DEBUG
      self._mutable = mutable
#endif
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafeMutableBufferPointer<_Word>,
      count: Int,
      mutable: Bool
    ) {
      assert(words.baseAddress != nil)
      self._words = UnsafeBufferPointer(words)
      self._count = count
#if DEBUG
      self._mutable = mutable
#endif
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafePointer<_Word>,
      wordCount: Int,
      count: Int,
      mutable: Bool
    ) {
      self.init(
        words: UnsafeBufferPointer(start: words, count: wordCount),
        count: count,
        mutable: mutable)
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafeMutablePointer<_Word>,
      wordCount: Int,
      count: Int,
      mutable: Bool
    ) {
      self.init(
        words: UnsafeBufferPointer(start: words, count: wordCount),
        count: count,
        mutable: mutable)
    }
  }
}

extension BitSet._UnsafeHandle {
  @inlinable
  @inline(__always)
  internal var wordCount: Int {
    _words.count
  }

  @_spi(Testing)
  @usableFromInline
  internal var _actualCount: Int {
    return _words.reduce(0) { $0 + $1.count }
  }
}

extension BitSet._UnsafeHandle {
  @inlinable
  @inline(__always)
  static func withTemporaryBitset<R>(
    capacity: UInt,
    run body: (inout Self) throws -> R
  ) rethrows -> R {
    let wordCount = Self.wordCount(forCapacity: capacity)
    return try withTemporaryBitset(wordCount: wordCount, run: body)
  }

  @inlinable
  @inline(__always)
  static func withTemporaryBitset<R>(
    wordCount: Int,
    run body: (inout Self) throws -> R
  ) rethrows -> R {
    var result: R?
    try _withTemporaryBitset(wordCount: wordCount) { bitset in
      result = try body(&bitset)
    }
    return result!
  }

  @usableFromInline
  @inline(never)
  static func _withTemporaryBitset(
    wordCount: Int,
    run body: (inout Self) throws -> Void
  ) rethrows {
    try _withTemporaryUninitializedBitset(wordCount: wordCount) { handle in
      handle._mutableWords.initialize(repeating: .empty)
      try body(&handle)
    }
  }

  internal static func _withTemporaryUninitializedBitset(
    wordCount: Int,
    run body: (inout Self) throws -> Void
  ) rethrows {
    assert(wordCount >= 0)
    if wordCount <= 2 {
      var buffer: (_Word, _Word) = (.empty, .empty)
      return try withUnsafeMutablePointer(to: &buffer) { p in
        // Homogeneous tuples are layout-compatible with their component type.
        let words = UnsafeMutableRawPointer(p).assumingMemoryBound(to: _Word.self)
        var bitset = Self(
          words: words, wordCount: wordCount, count: 0, mutable: true)
        return try body(&bitset)
      }
    }
    let words = UnsafeMutableBufferPointer<_Word>.allocate(capacity: wordCount)
    defer { words.deallocate() }
    var bitset = Self(words: words, count: 0, mutable: true)
    return try body(&bitset)
  }
}

extension BitSet._UnsafeHandle {
  @usableFromInline
  @_effects(readnone)
  @inline(__always)
  internal static func wordCount(forCapacity capacity: UInt) -> Int {
    Index(capacity + UInt(_Word.capacity) - 1).word
  }

  internal var capacity: UInt {
    @inline(__always)
    get {
      UInt(wordCount &* _Word.capacity)
    }
  }

  @inline(__always)
  internal func isValid(_ element: UInt) -> Bool {
    element < capacity
  }

  @inline(__always)
  internal func contains(_ element: UInt) -> Bool {
    let (word, bit) = Index(element).split
    guard word < wordCount else { return false }
    return _words[word].contains(bit)
  }

  internal mutating func updateCount() {
#if DEBUG
    assert(_mutable)
#endif
    _count = _words.reduce(into: 0) { $0 += $1.count }
  }

  internal func emptySuffix() -> Int {
    var i = wordCount - 1
    while i >= 0, _words[i].isEmpty {
      i -= 1
    }
    return wordCount - 1 - i
  }

  @usableFromInline
  @_effects(releasenone)
  @discardableResult
  internal mutating func insert(_ element: UInt) -> Bool {
    assert(isValid(element))
    let index = Index(element)
    let inserted = _mutableWords[index.word].insert(index.bit)
    if inserted { _count += 1 }
    return inserted
  }

  @discardableResult
  internal mutating func remove(_ element: UInt) -> Bool {
    let index = Index(element)
    if index.word >= _words.count { return false }
    let removed = _mutableWords[index.word].remove(index.bit)
    if removed { _count -= 1 }
    return removed
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func clear() {
    guard wordCount > 0 else { return }
    _mutableWords.baseAddress?.assign(
      repeating: .empty, count: wordCount)
    _count = 0
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func insertAll(upTo max: UInt) {
    assert(max <= capacity)
    guard max > 0 else { return }
    let (w, b) = Index(max).split
    for i in 0 ..< w {
      _count += _Word.capacity - _words[i].count
      _mutableWords[i] = .allBits
    }
    if b > 0 {
      _count += _mutableWords[w].insertAll(upTo: b)
    }
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func removeAll(upTo max: UInt) {
    assert(max <= capacity)
    guard max > 0 else { return }
    let (w, b) = Index(max).split
    for i in 0 ..< w {
      _count -= _words[i].count
      _mutableWords[i] = .empty
    }
    if b > 0 {
      _count -= _mutableWords[w].removeAll(upTo: b)
    }
  }
}

extension BitSet._UnsafeHandle: Sequence {
  @usableFromInline
  internal typealias Element = UInt

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
    internal typealias _UnsafeHandle = BitSet._UnsafeHandle

    @usableFromInline
    internal let bitset: BitSet._UnsafeHandle

    @usableFromInline
    internal var index: Int

    @usableFromInline
    internal var word: _Word

    @inlinable
    internal init(_ bitset: _UnsafeHandle) {
      self.bitset = bitset
      self.index = 0
      self.word = bitset.wordCount > 0 ? bitset._words[0] : .empty
    }

    @usableFromInline
    @_effects(releasenone)
    internal mutating func next() -> UInt? {
      if let bit = word.next() {
        return Index(word: index, bit: bit).value
      }
      while (index + 1) < bitset.wordCount {
        index += 1
        word = bitset._words[index]
        if let bit = word.next() {
          return Index(word: index, bit: bit).value
        }
      }
      return nil
    }
  }
}

extension BitSet._UnsafeHandle: BidirectionalCollection {
  @usableFromInline
  @frozen
  internal struct Index: Comparable, Hashable {
    @usableFromInline
    internal var value: UInt

    @inlinable
    internal init(_ value: UInt) {
      self.value = value
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
  }

  @inlinable
  @inline(__always)
  internal var count: Int {
    _count
  }

  @inlinable
  @inline(__always)
  internal var isEmpty: Bool {
    _count == 0
  }

  @inlinable
  internal var startIndex: Index {
    let word = _words.firstIndex { !$0.isEmpty }
    guard let word = word else { return endIndex }
    return Index(word: word, bit: _words[word].firstSetBit)
  }

  @inlinable
  internal var endIndex: Index {
    Index(word: wordCount, bit: 0)
  }

  @usableFromInline
  internal func index(after index: Index) -> Index {
    precondition(index < endIndex, "Index out of bounds")
    var word = index.word
    var w = _words[word]
    w.removeAll(through: index.bit)
    while w.isEmpty {
      word += 1
      guard word < wordCount else {
        return Index(word: wordCount, bit: 0)
      }
      w = _words[word]
    }
    return Index(word: word, bit: w.firstSetBit)
  }

  @usableFromInline
  internal func index(before index: Index) -> Index {
    precondition(index <= endIndex, "Index out of bounds")
    var word = index.word
    var w: _Word
    if index.bit > 0 {
      w = _words[word]
      w.removeAll(from: index.bit)
    } else {
      w = .empty
    }
    while w.isEmpty {
      word -= 1
      precondition(word >= 0, "Can't advance below startIndex")
      w = _words[word]
    }
    return Index(word: word, bit: w.lastSetBit)
  }

  @inlinable
  internal subscript(position: Index) -> UInt {
    position.value
  }
}

extension BitSet._UnsafeHandle {
  internal mutating func combineSharedPrefix(
    with other: Self,
    using function: (inout _Word, _Word) -> Void
  ) {
    let c = Swift.min(self.wordCount, other.wordCount)
    for w in 0 ..< c {
      function(&self._mutableWords[w], other._words[w])
    }
    updateCount()
  }
}


extension BitSet._UnsafeHandle {
  internal func count(in range: Range<UInt>) -> Int {
    let l = Index(Swift.min(range.lowerBound, capacity))
    let u = Index(Swift.min(range.upperBound, capacity))
    if l.word == u.word {
      guard l.word < wordCount else { return 0 }
      let w = _Word(from: l.bit, to: u.bit)
      return _words[l.word].intersection(w).count
    }
    var c = 0
    c += _words[l.word]
      .intersection(_Word(upTo: l.bit).complement())
      .count
    for i in l.word + 1 ..< u.word {
      c += _words[i].count
    }
    if u.word < _words.count {
      c += _words[u.word]
        .intersection(_Word(upTo: u.bit))
        .count
    }
    return c
  }

  internal mutating func formUnion(_ range: Range<UInt>) {
#if DEBUG
    assert(_mutable)
#endif
    let l = Index(range.lowerBound)
    let u = Index(range.upperBound)
    assert(u.value <= capacity)

    _count += Int(u.value - l.value) - count(in: range)
    if l.word == u.word {
      guard l.word < wordCount else { return }
      let w = _Word(from: l.bit, to: u.bit)
      _mutableWords[l.word].formUnion(w)
      return
    }
    _mutableWords[l.word].formUnion(_Word(upTo: l.bit).complement())
    for w in l.word + 1 ..< u.word {
      _mutableWords[w] = .allBits
    }
    if u.word < wordCount {
      _mutableWords[u.word].formUnion(_Word(upTo: u.bit))
    }
  }

  internal mutating func formIntersection(_ range: Range<UInt>) {
#if DEBUG
    assert(_mutable)
#endif
    let l = Index(Swift.min(range.lowerBound, capacity))
    let u = Index(Swift.min(range.upperBound, capacity))

    _count = count(in: range)

    for w in 0 ..< l.word {
      _mutableWords[w] = .empty
    }

    if l.word == u.word {
      guard l.word < wordCount else { return }

      let w = _Word(from: l.bit, to: u.bit)
      _mutableWords[l.word].formIntersection(w)
      return
    }

    _mutableWords[l.word].formIntersection(_Word(upTo: l.bit).complement())
    if u.word < wordCount {
      _mutableWords[u.word].formIntersection(_Word(upTo: u.bit))
      _mutableWords[(u.word + 1)...]
        ._rebased()
        .assign(repeating: .empty)
    }
  }

  internal mutating func formSymmetricDifference(_ range: Range<UInt>) {
#if DEBUG
    assert(_mutable)
#endif
    let l = Index(range.lowerBound)
    let u = Index(range.upperBound)
    assert(u.value <= capacity)

    _count += Int(u.value - l.value) - 2 * count(in: range)
    if l.word == u.word {
      guard l.word < wordCount else { return }
      let w = _Word(from: l.bit, to: u.bit)
      _mutableWords[l.word].formSymmetricDifference(w)
      return
    }
    _mutableWords[l.word]
      .formSymmetricDifference(_Word(upTo: l.bit).complement())
    for w in l.word + 1 ..< u.word {
      _mutableWords[w].formComplement()
    }
    if u.word < wordCount {
      _mutableWords[u.word].formSymmetricDifference(_Word(upTo: u.bit))
    }
  }

  internal mutating func subtract(_ range: Range<UInt>) {
#if DEBUG
    assert(_mutable)
#endif
    let l = Index(Swift.min(range.lowerBound, capacity))
    let u = Index(Swift.min(range.upperBound, capacity))

    _count -= count(in: range)
    if l.word == u.word {
      guard l.word < wordCount else { return }
      let w = _Word(from: l.bit, to: u.bit)
      _mutableWords[l.word].subtract(w)
      return
    }

    _mutableWords[l.word].subtract(_Word(upTo: l.bit).complement())
    _mutableWords[(l.word + 1) ..< u.word]
      ._rebased()
      .assign(repeating: .empty)
    if u.word < wordCount {
      _mutableWords[u.word].subtract(_Word(upTo: u.bit))
    }
  }

  internal func isDisjoint(with range: Range<UInt>) -> Bool {
    if self.isEmpty { return true }
    let lower = Index(Swift.min(range.lowerBound, capacity))
    let upper = Index(Swift.min(range.upperBound, capacity))
    if lower == upper { return true }

    if lower.word == upper.word {
      guard lower.word < wordCount else { return true }
      let w = _Word(from: lower.bit, to: upper.bit)
      return _words[lower.word].intersection(w).isEmpty
    }

    let lw = _Word(upTo: lower.bit).complement()
    guard _words[lower.word].intersection(lw).isEmpty else { return false }

    for i in lower.word + 1 ..< upper.word {
      guard _words[i].isEmpty else { return false }
    }
    if upper.word < wordCount {
      let uw = _Word(upTo: upper.bit)
      guard _words[upper.word].intersection(uw).isEmpty else { return false }
    }
    return true
  }

  internal func isSubset(of range: Range<UInt>) -> Bool {
    guard !range.isEmpty else { return isEmpty }
    let r = range.clamped(to: 0 ..< UInt(capacity))
    guard _count <= r.count else { return false }

    let lower = Index(range.lowerBound)
    let upper = Index(range.upperBound)

    for w in 0 ..< lower.word {
      guard _words[w].isEmpty else { return false }
    }

    let lw = _Word(upTo: lower.bit)
    guard _words[lower.word].intersection(lw).isEmpty else { return false }

    guard upper.word < wordCount else { return true }

    let hw = _Word(upTo: upper.bit).complement()
    guard _words[upper.word].intersection(hw).isEmpty else { return false }

    return true
  }

  internal func isSuperset(of range: Range<UInt>) -> Bool {
    guard !range.isEmpty else { return true }
    let r = range.clamped(to: 0 ..< UInt(capacity))
    guard r == range else { return false }
    guard _count >= r.count else { return false }

    let lower = Index(range.lowerBound)
    let upper = Index(range.upperBound)

    if lower.word == upper.word {
      let w = _Word(from: lower.bit, to: upper.bit)
      return _words[lower.word].intersection(w) == w
    }
    let lw = _Word(upTo: lower.bit).complement()
    guard _words[lower.word].intersection(lw) == lw else { return false }

    for w in lower.word + 1 ..< upper.word {
      guard _words[w].isFull else { return false }
    }

    guard upper.word < wordCount else { return true }
    let uw = _Word(upTo: upper.bit)
    return _words[upper.word].intersection(uw) == uw
  }
}
