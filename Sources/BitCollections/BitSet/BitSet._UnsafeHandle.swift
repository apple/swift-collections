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

    @inline(__always)
    internal func ensureMutable() {
#if DEBUG
      assert(_mutable)
#endif
    }

    internal var _mutableWords: UnsafeMutableBufferPointer<_Word> {
      ensureMutable()
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
      self.init(
        words: UnsafeBufferPointer(words), count: count, mutable: mutable)
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
#if compiler(>=5.6)
    return try withUnsafeTemporaryAllocation(
      of: _Word.self, capacity: wordCount
    ) { words in
      var bitset = Self(words: words, count: 0, mutable: true)
      return try body(&bitset)
    }
#else
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
#endif
  }
}

extension BitSet._UnsafeHandle {
  @usableFromInline
  @_effects(readnone)
  @inline(__always)
  internal static func wordCount(forCapacity capacity: UInt) -> Int {
    _Word.wordCount(forBitCount: capacity)
  }

  internal var capacity: UInt {
    @inline(__always)
    get {
      UInt(wordCount &* _Word.capacity)
    }
  }

  @inline(__always)
  internal func isWithinBounds(_ element: UInt) -> Bool {
    element < capacity
  }

  @inline(__always)
  internal func isReachable(_ index: Index) -> Bool {
    index == endIndex || contains(index.value)
  }

  @inline(__always)
  internal func contains(_ element: UInt) -> Bool {
    let (word, bit) = Index(element).split
    guard word < wordCount else { return false }
    return _words[word].contains(bit)
  }

  internal mutating func updateCount() {
    ensureMutable()
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
    ensureMutable()
    assert(isWithinBounds(element))
    let index = Index(element)
    let inserted = _mutableWords[index.word].insert(index.bit)
    if inserted { _count += 1 }
    return inserted
  }

  @discardableResult
  internal mutating func remove(_ element: UInt) -> Bool {
    ensureMutable()
    let index = Index(element)
    if index.word >= _words.count { return false }
    let removed = _mutableWords[index.word].remove(index.bit)
    if removed { _count -= 1 }
    return removed
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func clear() {
    ensureMutable()
    guard wordCount > 0 else { return }
    _mutableWords.baseAddress?.assign(
      repeating: .empty, count: wordCount)
    _count = 0
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func insertAll(upTo max: UInt) {
    ensureMutable()
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
    ensureMutable()
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
    internal let bitset: _UnsafeHandle

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
  internal typealias Index = _BitPosition

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
    return Index(word: word, bit: _words[word].firstMember)
  }

  @inlinable
  internal var endIndex: Index {
    Index(word: wordCount, bit: 0)
  }
  
  @inlinable
  internal subscript(position: Index) -> UInt {
    position.value
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
    return Index(word: word, bit: w.firstMember)
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
    return Index(word: word, bit: w.lastMember)
  }
  
  @usableFromInline
  internal func distance(from start: Index, to end: Index) -> Int {
    precondition(start <= endIndex && end <= endIndex, "Index out of bounds")
    let isNegative = end < start
    let (start, end) = (Swift.min(start, end), Swift.max(start, end))
    
    let (w1, b1) = start.split
    let (w2, b2) = end.split
    
    if w1 == w2 {
      guard w1 < wordCount else { return 0 }
      let mask = _Word(upTo: b1).symmetricDifference(_Word(upTo: b2))
      let c = _words[w1].intersection(mask).count
      return isNegative ? -c : c
    }
    
    var c = 0
    var w = w1
    guard w < wordCount else { return isNegative ? -c : c }
    
    c &+= _words[w].subtracting(_Word(upTo: b1)).count
    w &+= 1
    while w < w2 {
      c &+= _words[w].count
      w &+= 1
    }
    guard w < wordCount else { return isNegative ? -c : c }
    c &+= _words[w].intersection(_Word(upTo: b2)).count
    return isNegative ? -c : c
  }
  
  @usableFromInline
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    precondition(i == endIndex || contains(i.value), "Invalid index")
    guard distance != 0 else { return i }
    var remaining = distance.magnitude
    if distance > 0 {
      var (w, b) = i.split
      precondition(w < wordCount, "Index out of bounds")
      if let v = _words[w].subtracting(_Word(upTo: b)).nthElement(&remaining) {
        return Index(word: w, bit: v)
      }
      while true {
        w &+= 1
        guard w < wordCount else { break }
        if let v = _words[w].nthElement(&remaining) {
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
      if let v = _words[w].intersection(_Word(upTo: b)).nthElementFromEnd(&remaining) {
        return Index(word: w, bit: v)
      }
    }
    while true {
      precondition(w > 0, "Index out of bounds")
      w &-= 1
      if let v = _words[w].nthElementFromEnd(&remaining) {
        return Index(word: w, bit: v)
      }
    }
  }
  
  @usableFromInline
  internal func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    precondition(i <= endIndex && limit <= endIndex, "Index out of bounds")
    precondition(i == endIndex || contains(i.value), "Invalid index")
    guard distance != 0 else { return i }
    var remaining = distance.magnitude
    if distance > 0 {
      guard i <= limit else {
        return self.index(i, offsetBy: distance)
      }
      var (w, b) = i.split
      if w < wordCount,
         let v = _words[w].subtracting(_Word(upTo: b)).nthElement(&remaining)
      {
        let r = Index(word: w, bit: v)
        return r <= limit ? r : nil
      }
      let maxWord = Swift.min(wordCount - 1, limit.word)
      while w < maxWord {
        w &+= 1
        if let v = _words[w].nthElement(&remaining) {
          let r = Index(word: w, bit: v)
          return r <= limit ? r : nil
        }
      }
      return remaining == 0 && limit == endIndex ? endIndex : nil
    }
    
    // distance < 0
    guard i >= limit else {
      return self.index(i, offsetBy: distance)
    }
    remaining &-= 1
    var (w, b) = i.endSplit
    if w < wordCount {
      if let v = _words[w].intersection(_Word(upTo: b)).nthElementFromEnd(&remaining) {
        let r = Index(word: w, bit: v)
        return r >= limit ? r : nil
      }
    }
    let minWord = limit.word
    while w > minWord {
      w &-= 1
      if let v = _words[w].nthElementFromEnd(&remaining) {
        let r = Index(word: w, bit: v)
        return r >= limit ? r : nil
      }
    }
    return nil
  }
}

extension BitSet._UnsafeHandle {
  internal mutating func combineSharedPrefix(
    with other: Self,
    using function: (inout _Word, _Word) -> Void
  ) {
    ensureMutable()
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
    ensureMutable()
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
    ensureMutable()
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
    ensureMutable()
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
    ensureMutable()
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
