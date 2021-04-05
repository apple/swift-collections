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

/// A non-owning handle to hash table storage, implementing higher-level table operations.
///
/// - Warning: `_UnsafeHashTable` values do not have ownership of their underlying storage buffer.
///     You must not escape these handles outside the closure call that produced them.
@_spi(Testing) public struct _UnsafeHashTable {
  /// A pointer to the table header.
  internal var _header: UnsafeMutablePointer<_HashTableHeader>

  /// A pointer to bucket storage.
  internal var _buckets: UnsafeMutablePointer<UInt64>

  #if DEBUG
  /// True when this handle does not support table mutations.
  /// (This is only checked in debug builds.)
  internal let _readonly: Bool
  #endif

  /// Initialize a new hash table handle for storage at the supplied locations.
  @inline(__always)
  internal init(
    header: UnsafeMutablePointer<_HashTableHeader>,
    buckets: UnsafeMutablePointer<UInt64>,
    readonly: Bool
  ) {
    self._header = header
    self._buckets = buckets
    #if DEBUG
    self._readonly = readonly
    #endif
  }

  /// Check that this handle supports mutating operations.
  /// Every member that mutates table data must start by calling this function.
  /// This helps preventing COW violations.
  ///
  /// Note that this is a noop in release builds.
  @inline(__always)
  func assertMutable() {
    #if DEBUG
    assert(!_readonly, "Attempt to mutate a hash table through a read-only handle")
    #endif
  }
}

extension _UnsafeHashTable {
  /// The minimum hash table scale.
  @inline(__always)
  @_spi(Testing)
  public static var minimumScale: Int { 5 }

  /// The maximum hash table scale.
  @inline(__always)
  @_spi(Testing)
  public static var maximumScale: Int {
    Swift.min(Int.bitWidth, 56)
  }

  /// The maximum number of items for which we do not create a hash table.
  @inline(__always)
  @_spi(Testing)
  public static var maximumUnhashedCount: Int {
    (1 &<< (minimumScale - 1)) - 1
  }

  /// The maximum hash table load factor.
  @inline(__always)
  static var maximumLoadFactor: Double { 3 / 4 }

  /// The minimum hash table load factor.
  @inline(__always)
  static var minimumLoadFactor: Double { 1 / 4 }

  /// The maximum number of items that can be held in a hash table of the given scale.
  @_spi(Testing)
  public static func maximumCapacity(forScale scale: Int) -> Int {
    guard scale >= minimumScale else { return maximumUnhashedCount }
    let bucketCount = 1 &<< scale
    return Int(Double(bucketCount) * maximumLoadFactor)
  }

  /// The maximum number of items that can be held in a hash table of the given scale.
  @_spi(Testing)
  public static func minimumCapacity(forScale scale: Int) -> Int {
    guard scale >= minimumScale else { return 0 }
    let bucketCount = 1 &<< scale
    return Int(Double(bucketCount) * minimumLoadFactor)
  }

  /// The minimum hash table scale that can hold the specified number of elements.
  @_spi(Testing)
  public static func scale(forCapacity capacity: Int) -> Int {
    guard capacity > maximumUnhashedCount else { return 0 }
    let capacity = Swift.max(capacity, 1)
    // Calculate the minimum number of entries we need to allocate to satisfy
    // the maximum load factor. `capacity + 1` below ensures that we always
    // leave at least one hole.
    let minimumEntries = Swift.max(
      Int((Double(capacity) / maximumLoadFactor).rounded(.up)),
      capacity + 1)
    // The actual number of entries we need to allocate is the lowest power of
    // two greater than or equal to the minimum entry count. Calculate its
    // exponent.
    let scale = (Swift.max(minimumEntries, 2) - 1)._binaryLogarithm() + 1
    assert(scale >= minimumScale && scale < Int.bitWidth)
    // The scale is the exponent corresponding to the bucket count.
    assert(self.maximumCapacity(forScale: scale) >= capacity)
    return scale
  }

  @_spi(Testing)
  public static func biasRange(scale: Int) -> Range<Int> {
    guard scale != 0 else { return 0 ..< 1 }
    return 0 ..< (1 &<< scale) - 1
  }

  /// The count of 64-bit words that a hash table of the specified scale
  /// will need to have in its storage.
  internal static func wordCount(forScale scale: Int) -> Int {
    ((scale &<< scale) + UInt64.bitWidth - 1) / UInt64.bitWidth
  }
}

extension _UnsafeHashTable {
  /// The scale of the hash table. A table of scale *n* holds 2^*n* buckets,
  /// each of which contain an *n*-bit value.
  @inline(__always)
  internal var scale: Int { _header.pointee.scale }

  /// The scale corresponding to the last call to `reserveCapacity`.
  /// We store this to make sure we don't shrink the table below its reserved size.
  @inline(__always)
  internal var reservedScale: Int {
    get { _header.pointee.reservedScale }
    nonmutating set { _header.pointee.reservedScale = newValue }
  }

  /// The hasher seed to use within this hash table.
  @inline(__always)
  internal var seed: Int { _header.pointee.seed }

  /// A bias value that needs to be added to buckets to convert them into offsets
  /// into element storage. (This allows O(1) insertions at the front when the
  /// underlying storage supports it.)
  @inline(__always)
  internal var bias: Int {
    get { _header.pointee.bias }
    nonmutating set { _header.pointee.bias = newValue }
  }

  /// The number of buckets within this hash table. This is always a power of two.
  @inline(__always)
  internal var bucketCount: Int { 1 &<< scale }

  @inline(__always)
  internal var bucketMask: UInt64 { UInt64(truncatingIfNeeded: bucketCount) - 1 }

  /// The number of bits used to store all the buckets in this hash table.
  /// Each bucket holds a value that is `scale` bits wide.
  @inline(__always)
  internal var bitCount: Int { scale &<< scale }

  /// The number of 64-bit words that are available in the storage buffer,
  /// rounded up to the nearest whole number if necessary.
  @inline(__always)
  internal var wordCount: Int { (bitCount + UInt64.bitWidth - 1) / UInt64.bitWidth }

  /// The maximum number of items that can fit into this table.
  @inline(__always)
  internal var capacity: Int { _UnsafeHashTable.maximumCapacity(forScale: scale) }

  /// Return the bucket logically following `bucket` in this hash table.
  /// The buckets form a cycle, so the last bucket is logically followed by the first.
  @inline(__always)
  func bucket(after bucket: _Bucket) -> _Bucket {
    var offset = bucket.offset + 1
    if offset == bucketCount {
      offset = 0
    }
    return _Bucket(offset: offset)
  }

  /// Return the bucket logically preceding `bucket` in this hash table.
  /// The buckets form a cycle, so the first bucket is logically preceded by the last.
  @inline(__always)
  func bucket(before bucket: _Bucket) -> _Bucket {
    let offset = (bucket.offset == 0 ? bucketCount : bucket.offset) - 1
    return _Bucket(offset: offset)
  }

  /// Return the index of the word logically following `word` in this hash table.
  /// The buckets form a cycle, so the last word is logically followed by the first.
  ///
  /// Note that the last word may be only partially filled if `scale` is less than 6.
  @inline(__always)
  func word(after word: Int) -> Int {
    var result = word + 1
    if result == wordCount {
      result = 0
    }
    return result
  }

  /// Return the index of the word logically preceding `word` in this hash table.
  /// The buckets form a cycle, so the first word is logically preceded by the first.
  ///
  /// Note that the last word may be only partially filled if `scale` is less than 6.
  @inline(__always)
  func word(before word: Int) -> Int {
    if word == 0 {
      return wordCount - 1
    }
    return word - 1
  }

  /// Return the index of the 64-bit storage word that holds the first bit
  /// corresponding to `bucket`, along with its bit position within the word.
  internal func position(of bucket: _Bucket) -> (word: Int, bit: Int) {
    let start = bucket.offset &* scale
    return (start &>> 6, start & 0x3F)
  }
}

extension _UnsafeHashTable {
  /// Decode and return the logical value corresponding to the specified bucket value.
  ///
  /// The nil value is represented by an all-zero bit pattern.
  /// Other values are stored as the complement of the lowest `scale` bits
  /// after taking `bias` into account.
  /// The range of representable values is `0 ..< bucketCount - 1`.
  /// (Note that the value `bucketCount - 1` is missing from this range, as its
  /// encoding is used for `nil`. This isn't an issue, because the maximum load
  /// factor guarantees that the hash table will never be completely full.)
  func _value(forBucketContents bucketContents: UInt64) -> Int? {
    let mask = bucketMask
    assert(bucketContents <= mask)
    guard bucketContents != 0 else { return nil }
    let v = (bucketContents ^ mask) &+ UInt64(truncatingIfNeeded: bias)
    return Int(truncatingIfNeeded: v >= mask ? v - mask : v)
  }

  /// Encodes the specified logical value into a `scale`-bit bit pattern suitable
  /// for storing into a bucket.
  ///
  /// The nil value is represented by an all-zero bit pattern.
  /// Other values are stored as the complement of their lowest `scale` bits.
  /// The range of representable values is `0 ..< bucketCount - 1`.
  /// (Note that the value `bucketCount - 1` is missing from this range, as it
  /// its encoding is used for `nil`. This isn't an issue, because the maximum
  /// load factor guarantees that the hash table will never be completely full.)
  func _bucketContents(for value: Int?) -> UInt64 {
    guard var value = value else { return 0 }
    let mask = Int(truncatingIfNeeded: bucketMask)
    assert(value >= 0 && value < mask)
    value &-= bias
    if value < 0 { value += mask }
    assert(value >= 0 && value < mask)
    return UInt64(truncatingIfNeeded: value ^ mask)
  }

  subscript(word word: Int) -> UInt64 {
    @inline(__always) get {
      assert(word >= 0 && word < bucketCount)
      return _buckets[word]
    }
    @inline(__always) nonmutating set {
      assert(word >= 0 && word < bucketCount)
      assertMutable()
      _buckets[word] = newValue
    }
  }

  subscript(raw bucket: _Bucket) -> UInt64 {
    get {
      assert(bucket.offset < bucketCount)
      let (word, bit) = position(of: bucket)
      var value = self[word: word] &>> bit
      let extractedBits = 64 - bit
      if extractedBits < scale {
        let word2 = self.word(after: word)
        value &= (1 &<< extractedBits) - 1
        value |= self[word: word2] &<< extractedBits
      }
      return value & bucketMask
    }
    nonmutating set {
      assertMutable()
      assert(bucket.offset < bucketCount)
      let mask = bucketMask
      assert(newValue <= mask)
      let (word, bit) = position(of: bucket)
      self[word: word] &= ~(mask &<< bit)
      self[word: word] |= newValue &<< bit
      let extractedBits = 64 - bit
      if extractedBits < scale {
        let word2 = self.word(after: word)
        self[word: word2] &= ~((1 &<< (scale - extractedBits)) - 1)
        self[word: word2] |= newValue &>> extractedBits
      }
    }
  }

  func isOccupied(_ bucket: _Bucket) -> Bool {
    self[raw: bucket] != 0
  }

  /// Return or update the current value stored in the specified bucket.
  /// A nil value indicates that the bucket is empty.
  subscript(bucket: _Bucket) -> Int? {
    get {
      let contents = self[raw: bucket]
      return _value(forBucketContents: contents)
    }
    nonmutating set {
      assertMutable()
      let v = _bucketContents(for: newValue)
      self[raw: bucket] = v
    }
  }
}

extension _UnsafeHashTable {
  /// An infinite iterator construct for visiting a chain of buckets within the hash table.
  /// This is a convenient tool for linear probing.
  ///
  /// Beyond merely providing bucket values, bucket iterators can also tell
  /// you their current oposition within the hash table, and (for mutable hash tables)
  /// they allow you update the value of the currently visited bucket.
  /// (This is useful when implementing simple insertions, for example.)
  ///
  /// The bucket iterator caches some bucket contents, so if you are looping over an iterator
  /// you must be careful to only modify hash table contents through the iterator itself.
  ///
  /// - Warning: Like `_UnsafeHashTable` itself, `BucketIterator` does not have
  ///     ownership of its underlying storage buffer. You must not escape iterator
  ///     values outside the closure call that produced the original hash table.
  struct BucketIterator {
    /// The hash table we are iterating over.
    let _hashTable: _UnsafeHashTable

    /// The current position within the hash table.
    var _currentBucket: _Bucket

    /// The raw bucket value corresponding to `_currentBucket`.
    var _currentRawValue: UInt64

    /// Remaining bits not yet processed from the last word read.
    var _nextBits: UInt64

    /// Count of usable bits in `_nextBits`. (They start at bit 0.)
    var _remainingBitCount: Int

    /// Create a new iterator starting at the specified bucket.
    init(hashTable: _UnsafeHashTable, startingAt bucket: _Bucket) {
      assert(hashTable.scale >= _UnsafeHashTable.minimumScale)
      assert(bucket.offset >= 0 && bucket.offset < hashTable.bucketCount)
      self._hashTable = hashTable
      self._currentBucket = bucket
      var (word, bit) = hashTable.position(of: bucket)

      // The `scale == 5` case is special because the last word is only half filled there,
      // which is why the code below needs to special case it.
      // (For all scales > 5, the last bucket ends exactly on a word boundary.)

      if bit + hashTable.scale <= 64 {
        // We're in luck, the current bucket is stored entirely within one word.
        let w = _hashTable[word: word]
        _currentRawValue = (w &>> bit) & _hashTable.bucketMask
        let c = (hashTable.scale == 5 && word == hashTable.wordCount - 1 ? 32 : 64)
        self._remainingBitCount = c - (bit + hashTable.scale)
        self._nextBits = (_remainingBitCount == 0 ? 0 : w &>> (bit + hashTable.scale))
        assert(_remainingBitCount >= 0)
        assert(bit < c)
      } else {
        // We need to read two words.
        assert(hashTable.scale != 5 || word < hashTable.wordCount - 1)
        assert(bit > 0)
        let w1 = _hashTable[word: word]
        word = hashTable.word(after: word)
        let w2 = _hashTable[word: word]
        self._currentRawValue = ((w1 &>> bit) | (w2 &<< (64 - bit))) & _hashTable.bucketMask
        let overhang = hashTable.scale - (64 - bit)
        self._nextBits = w2 &>> overhang
        let c = (hashTable.scale == 5 && word == hashTable.wordCount - 1 ? 32 : 64)
        self._remainingBitCount = c - overhang
      }
      assert(_currentRawValue <= _hashTable.bucketMask)
    }

    /// The scale of the hash table. A table of scale *n* holds 2^*n* buckets,
    /// each of which contain an *n*-bit value.
    @inline(__always)
    var _scale: Int { _hashTable.scale }

    /// The current position within the hash table.
    @inline(__always)
    var currentBucket: _Bucket { _currentBucket }

    var isOccupied: Bool {
      _currentRawValue != 0
    }

    /// The value of the bucket at the current position in the hash table.
    /// Setting this property overwrites the bucket value.
    ///
    /// A nil value indicates an empty bucket.
    var currentValue: Int? {
      @inline(__always)
      get { _hashTable._value(forBucketContents: _currentRawValue) }
      set {
        _hashTable.assertMutable()
        let v = _hashTable._bucketContents(for: newValue)
        let pattern = v ^ _currentRawValue

        assert(_currentBucket.offset < _hashTable.bucketCount)
        let (word, bit) = _hashTable.position(of: _currentBucket)
        _hashTable[word: word] ^= pattern &<< bit
        let extractedBits = 64 - bit
        if extractedBits < _scale {
          let word2 = _hashTable.word(after: word)
          _hashTable[word: word2] ^= pattern &>> extractedBits
        }
        _currentRawValue = v
      }
    }

    /// Advance this iterator to the next bucket within the hash table.
    /// The buckets form a cycle, so the last bucket is logically followed
    /// by the first. Therefore, the iterator never runs out of buckets --
    /// you must devise some way to guarantee to stop iterating.
    ///
    /// In the typical case, you stop iterating buckets when you find the
    /// element you're looking for, or when you run across an empty bucket
    /// (terminating the chain with a negative lookup result).
    mutating func advance() {
      _currentBucket = _hashTable.bucket(after: _currentBucket)
      if _remainingBitCount >= _scale {
        _currentRawValue = _nextBits & _hashTable.bucketMask
        _nextBits &>>= _scale
        _remainingBitCount -= _scale
        return
      }
      var word = _hashTable.position(of: _currentBucket).word
      if _remainingBitCount != 0 {
        word = _hashTable.word(after: word)
      }
      let c = (_hashTable.scale == 5 && word == _hashTable.wordCount - 1 ? 32 : 64)
      let w = _hashTable[word: word]
      _currentRawValue = (_nextBits | (w &<< _remainingBitCount)) & _hashTable.bucketMask
      _nextBits = w &>> (_scale - _remainingBitCount)
      _remainingBitCount = c - (_scale - _remainingBitCount)
    }

    /// Advance this iterator until it points to an occupied bucket with the
    /// specified value, or an unoccupied bucket -- whichever comes first.
    mutating func advance(until expected: Int) {
      while isOccupied && currentValue != expected {
        advance()
      }
    }

    /// Advance this iterator until it points to an unoccupied bucket.
    /// Useful when inserting an element that we know isn't already in the table.
    mutating func advanceToNextUnoccupiedBucket() {
      while isOccupied {
        advance()
      }
    }
  }

  @inline(__always)
  func idealBucket(forHashValue hashValue: Int) -> _Bucket {
    return _Bucket(offset: hashValue & (bucketCount - 1))
  }

  @inline(__always)
  func idealBucket<Element: Hashable>(for element: Element) -> _Bucket {
    let hashValue = element._rawHashValue(seed: seed)
    return idealBucket(forHashValue: hashValue)
  }

  /// Return a bucket iterator for the chain starting at the bucket corresponding
  /// to the specified value.
  @inline(__always)
  func bucketIterator<Element: Hashable>(for element: Element) -> BucketIterator {
    let bucket = idealBucket(for: element)
    return bucketIterator(startingAt: bucket)
  }

  /// Return a bucket iterator for the chain starting at the specified bucket.
  @inline(__always)
  func bucketIterator(startingAt bucket: _Bucket) -> BucketIterator {
    BucketIterator(hashTable: self, startingAt: bucket)
  }
}

extension _UnsafeHashTable {
  internal func _find<Base: RandomAccessCollection>(
    _ item: Base.Element,
    in elements: Base
  ) -> (offset: Int?, bucket: _Bucket)
  where Base.Element: Hashable {
    var iterator = self.bucketIterator(for: item)
    let start = iterator.currentBucket
    repeat {
      guard let offset = iterator.currentValue else {
        return (nil, iterator.currentBucket)
      }
      if elements[_offset: offset] == item {
        return (offset, iterator.currentBucket)
      }
      iterator.advance()
    } while iterator.currentBucket.offset != start.offset
    fatalError("Hash table has no unoccupied buckets")
  }
}

extension _UnsafeHashTable {
  internal func firstUnoccupiedBucket(before bucket: _Bucket) -> _Bucket {
    var bucket = bucket
    repeat {
      bucket = self.bucket(before: bucket)
    } while isOccupied(bucket)
    return bucket
  }

  internal func delete(
    bucket: _Bucket,
    hashValueGenerator: (Int, Int) -> Int // (offset, seed) -> hashValue
  ) {
    assertMutable()
    var it = bucketIterator(startingAt: bucket)
    assert(it.isOccupied)
    it.advance()
    guard it.isOccupied else {
      // Fast path: Don't get the start bucket when there's nothing to do.
      self[bucket] = nil
      return
    }
    // If we've put a hole in the middle of a collision chain, some element after
    // the hole may belong where the new hole is.

    // Find the first bucket in the collision chain that contains the entry we've just deleted.
    let start = self.bucket(after: firstUnoccupiedBucket(before: bucket))
    var hole = bucket

    while it.isOccupied {
      let hash = hashValueGenerator(it.currentValue!, seed)
      let candidate = idealBucket(forHashValue: hash)

      // Does this element belong between start and hole?  We need two
      // separate tests depending on whether [start, hole] wraps around the
      // end of the storage.
      let c0 = candidate.offset >= start.offset
      let c1 = candidate.offset <= hole.offset
      if start.offset <= hole.offset ? (c0 && c1) : (c0 || c1) {
        // Fill the hole. Here we are mutating table contents behind the back of
        // the iterator; this is okay since we know we are never going to revisit
        // `hole` with it.
        self[hole] = it.currentValue
        hole = it.currentBucket
      }
      it.advance()
    }
    self[hole] = nil
  }
}

extension _UnsafeHashTable {
  internal func adjustContents<Base: RandomAccessCollection>(
    preparingForInsertionOfElementAtOffset offset: Int,
    in elements: Base
  ) where Base.Element: Hashable {
    assertMutable()
    let index = elements._index(at: offset)
    if offset < elements.count / 2 {
      self.bias += 1
      if offset <= capacity / 8 {
        var i = 1
        for item in elements[..<index] {
          var it = bucketIterator(for: item)
          it.advance(until: i)
          it.currentValue! -= 1
          i += 1
        }
      } else {
        var it = bucketIterator(startingAt: _Bucket(offset: 0))
        repeat {
          guard let value = it.currentValue, value <= offset else { continue }
          it.currentValue = value - 1
        } while it.currentBucket.offset != 0
      }
    } else {
      if elements.count - offset - 1 <= capacity / 8 {
        var i = offset
        for item in elements[index...] {
          var it = bucketIterator(for: item)
          it.advance(until: i)
          it.currentValue! += 1
          i += 1
        }
      } else {
        var it = bucketIterator(startingAt: _Bucket(offset: 0))
        repeat {
          guard let value = it.currentValue, value >= offset else { continue }
          it.currentValue = value + 1
        } while it.currentBucket.offset != 0
      }
    }
  }
}

extension _UnsafeHashTable {
  @inline(__always)
  internal func adjustContents<Base: RandomAccessCollection>(
    preparingForRemovalOf index: Base.Index,
    in elements: Base
  ) where Base.Element: Hashable {
    let next = elements.index(after: index)
    adjustContents(preparingForRemovalOf: index ..< next, in: elements)
  }

  internal func adjustContents<Base: RandomAccessCollection>(
    preparingForRemovalOf bounds: Range<Base.Index>,
    in elements: Base
  ) where Base.Element: Hashable {
    assertMutable()
    let startOffset = elements._offset(of: bounds.lowerBound)
    let endOffset = elements._offset(of: bounds.upperBound)
    let c = endOffset - startOffset
    guard c > 0 else { return }
    let remainingCount = elements.count - c

    if startOffset >= remainingCount / 2 {
      var i = endOffset
      for item in elements[bounds.upperBound...] {
        var it = self.bucketIterator(for: item)
        it.advance(until: i)
        it.currentValue = i - c
        i += 1
      }
    } else {
      var i = 0
      for item in elements[..<bounds.lowerBound] {
        var it = self.bucketIterator(for: item)
        it.advance(until: i)
        it.currentValue = i + c
        i += 1
      }
      self.bias -= c
    }
  }
}

extension _UnsafeHashTable {
  func clear() {
    assertMutable()
    _buckets.assign(repeating: 0, count: wordCount)
  }
}

extension _UnsafeHashTable {
  /// Fill an empty hash table by populating it with data from `elements`.
  ///
  /// - Parameter elements: A random-access collection for which this table is being generated.
  /// - Parameter stoppingOnFirstDuplicateValue: If true, check for duplicate values and stop inserting items when one is found.
  /// - Returns: `(success, index)` where `success` is a boolean value indicating that every value in `elements` was successfully inserted. A false success indicates that duplicate elements have been found; in this case `index` points to the first duplicate value; otherwise `index` is set to `elements.endIndex`.
  @discardableResult
  func fill<C: RandomAccessCollection>(
    from elements: C,
    stoppingOnFirstDuplicateValue: Bool = true
  ) -> (success: Bool, end: C.Index)
  where C.Element: Hashable {
    assertMutable()
    assert(elements.count <= capacity)
    // Iterate over elements and insert their offset into the hash table.
    var offset = 0
    loop: for index in elements.indices {
      // Find the insertion position. We know that we're inserting a new item,
      // so there is no need to compare it with any of the existing ones.
      var it = bucketIterator(for: elements[index])
      if stoppingOnFirstDuplicateValue {
        while let offset = it.currentValue {
          guard elements[_offset: offset] != elements[index] else {
            return (false, index)
          }
          it.advance()
        }
      } else {
        it.advanceToNextUnoccupiedBucket()
      }
      it.currentValue = offset
      offset += 1
    }
    return (true, elements.endIndex)
  }
}
