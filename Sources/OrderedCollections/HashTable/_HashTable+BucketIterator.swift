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

extension _HashTable {
  /// An iterator construct for visiting a chain of buckets within the hash
  /// table. This is a convenient tool for implementing linear probing.
  ///
  /// Beyond merely providing bucket values, bucket iterators can also tell
  /// you their current opposition within the hash table, and (for mutable hash
  /// tables) they allow you update the value of the currently visited bucket.
  /// (This is useful when implementing simple insertions, for example.)
  ///
  /// The bucket iterator caches some bucket contents, so if you are looping
  /// over an iterator you must be careful to only modify hash table contents
  /// through the iterator itself.
  ///
  /// - Warning: Like `UnsafeHandle`, `BucketIterator` does not have
  ///     ownership of its underlying storage buffer. You must not escape
  ///     iterator values outside the closure call that produced the original
  ///     hash table.
  @usableFromInline
  @unsafe
  package struct BucketIterator {
    @usableFromInline
    package typealias Bucket = _HashTable.Bucket

    /// The hash table we are iterating over.
    internal let _hashTable: _UnsafeHashTable

    /// The current position within the hash table.
    @usableFromInline
    @safe
    package var _currentBucket: Bucket

    /// The raw bucket value corresponding to `_currentBucket`.
    @safe
    internal var _currentRawValue: UInt64

    /// Remaining bits not yet processed from the last word read.
    @safe
    internal var _nextBits: UInt64

    /// Count of usable bits in `_nextBits`. (They start at bit 0.)
    @safe
    internal var _remainingBitCount: Int

    @safe
    internal var _wrappedAround = false

    /// Create a new iterator starting at the specified bucket.
    @_effects(releasenone)
    @usableFromInline
    package init(hashTable: _UnsafeHashTable, startingAt bucket: Bucket) {
      assert(unsafe hashTable.scale >= _HashTable.minimumScale)
      assert(unsafe bucket.offset >= 0 && bucket.offset < hashTable.bucketCount)
      unsafe self._hashTable = hashTable
      self._currentBucket = bucket
      (self._currentRawValue, self._nextBits, self._remainingBitCount)
        = unsafe hashTable._startIterator(bucket: bucket)
    }
  }
}

extension _HashTable.UnsafeHandle {
  @usableFromInline
  package typealias BucketIterator = _HashTable.BucketIterator

  @_effects(releasenone)
  @inlinable
  @inline(__always)
  package func idealBucket(forHashValue hashValue: Int) -> Bucket {
    return Bucket(offset: unsafe hashValue & (bucketCount - 1))
  }

  @inlinable
  @inline(__always)
  package func idealBucket<Element: Hashable>(for element: Element) -> Bucket {
    let hashValue = element._rawHashValue(seed: unsafe seed)
    return unsafe idealBucket(forHashValue: hashValue)
  }

  /// Return a bucket iterator for the chain starting at the bucket corresponding
  /// to the specified value.
  @inlinable
  @inline(__always)
  package func bucketIterator<Element: Hashable>(for element: Element) -> BucketIterator {
    let bucket = unsafe idealBucket(for: element)
    return unsafe bucketIterator(startingAt: bucket)
  }

  /// Return a bucket iterator for the chain starting at the specified bucket.
  @inlinable
  @inline(__always)
  package func bucketIterator(startingAt bucket: Bucket) -> BucketIterator {
    unsafe BucketIterator(hashTable: self, startingAt: bucket)
  }

  @usableFromInline
  @_effects(releasenone)
  package func startFind(
    _ startBucket: Bucket
  ) -> (iterator: BucketIterator, currentValue: Int?) {
    let iterator = unsafe bucketIterator(startingAt: startBucket)
    return unsafe (iterator, iterator.currentValue)
  }

  @_effects(readonly)
  @usableFromInline
  package func _startIterator(
    bucket: Bucket
  ) -> (currentBits: UInt64, nextBits: UInt64, remainingBitCount: Int) {
    // The `scale == 5` case is special because the last word is only half filled there,
    // which is why the code below needs to special case it.
    // (For all scales > 5, the last bucket ends exactly on a word boundary.)

    var (word, bit) = unsafe self.position(of: bucket)
    if unsafe bit + scale <= 64 {
      // We're in luck, the current bucket is stored entirely within one word.
      let w = unsafe self[word: word]
      let currentRawValue = unsafe (w &>> bit) & bucketMask
      let c = unsafe (scale == 5 && word == wordCount - 1 ? 32 : 64)
      let remainingBitCount = unsafe c - (bit + scale)
      let nextBits = unsafe (remainingBitCount == 0 ? 0 : w &>> (bit + scale))
      assert(remainingBitCount >= 0)
      assert(bit < c)
      return (currentRawValue, nextBits, remainingBitCount)
    } else {
      // We need to read two words.
      assert(unsafe scale != 5 || word < wordCount - 1)
      assert(bit > 0)
      let w1 = unsafe self[word: word]
      word = unsafe self.word(after: word)
      let w2 = unsafe self[word: word]
      let currentRawValue = unsafe ((w1 &>> bit) | (w2 &<< (64 - bit))) & bucketMask
      let overhang = unsafe scale - (64 - bit)
      let nextBits = w2 &>> overhang
      let c = unsafe (scale == 5 && word == wordCount - 1 ? 32 : 64)
      let remainingBitCount = c - overhang
      return (currentRawValue, nextBits, remainingBitCount)
    }
  }
}

extension _HashTable.BucketIterator {
  /// The scale of the hash table. A table of scale *n* holds 2^*n* buckets,
  /// each of which contain an *n*-bit value.
  @inline(__always)
  internal var _scale: Int { unsafe _hashTable.scale }

  /// The current position within the hash table.
  @inlinable
  @inline(__always)
  @safe
  package var currentBucket: Bucket { _currentBucket }

  // For testing
  @usableFromInline
  package func isIdentical(to other: Self) -> Bool {
    unsafe self._hashTable.isIdentical(to: other._hashTable)
    && self.currentBucket == other.currentBucket
    && self._currentRawValue == other._currentRawValue
    && self.currentValue == other.currentValue
    && self._nextBits == other._nextBits
    && self._remainingBitCount == other._remainingBitCount
    && self._wrappedAround == other._wrappedAround
  }

  @usableFromInline
  @safe
  package var isOccupied: Bool {
    @_effects(readonly)
    @inline(__always)
    get {
      _currentRawValue != 0
    }
  }

  /// The value of the bucket at the current position in the hash table.
  /// Setting this property overwrites the bucket value.
  ///
  /// A nil value indicates an empty bucket.
  @usableFromInline
  package var currentValue: Int? {
    @inline(__always)
    @_effects(readonly)
    get {
      unsafe _hashTable._value(forBucketContents: _currentRawValue)
    }
    @_effects(releasenone)
    set {
      unsafe _hashTable.assertMutable()
      let v = unsafe _hashTable._bucketContents(for: newValue)
      let pattern = v ^ _currentRawValue

      assert(unsafe _currentBucket.offset < _hashTable.bucketCount)
      let (word, bit) = unsafe _hashTable.position(of: _currentBucket)
      unsafe _hashTable[word: word] ^= pattern &<< bit
      let extractedBits = 64 - bit
      if unsafe extractedBits < _scale {
        let word2 = unsafe _hashTable.word(after: word)
        unsafe _hashTable[word: word2] ^= pattern &>> extractedBits
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
  ///
  /// To catch mistakes (and corrupt tables), `advance` traps the second
  /// time it needs to wrap around to the beginning of the table.
  @usableFromInline
  @_effects(releasenone)
  package mutating func advance() {
    // Advance to next bucket, checking for wraparound condition.
    _currentBucket.offset &+= 1
    if unsafe _currentBucket.offset == _hashTable.bucketCount {
      guard !_wrappedAround else {
        // Prevent wasting battery in an infinite loop if a hash table
        // somehow becomes corrupt.
        fatalError("Hash table has no unoccupied buckets")
      }
      _wrappedAround = true
      _currentBucket.offset = 0
    }

    // If we have loaded enough bits, eat them and return.
    if unsafe _remainingBitCount >= _scale {
      unsafe _currentRawValue = _nextBits & _hashTable.bucketMask
      unsafe _nextBits &>>= _scale
      unsafe _remainingBitCount -= _scale
      return
    }

    // Load the next batch of bits.
    var word = unsafe _hashTable.position(of: _currentBucket).word
    if _remainingBitCount != 0 {
      word = unsafe _hashTable.word(after: word)
    }
    let c = unsafe (_hashTable.scale == 5 && word == _hashTable.wordCount - 1 ? 32 : 64)
    let w = unsafe _hashTable[word: word]
    _currentRawValue = unsafe (_nextBits | (w &<< _remainingBitCount)) & _hashTable.bucketMask
    _nextBits = unsafe w &>> (_scale - _remainingBitCount)
    _remainingBitCount = unsafe c - (_scale - _remainingBitCount)
  }

  @usableFromInline
  @_effects(releasenone)
  package mutating func findNext() -> Int? {
    unsafe advance()
    return unsafe currentValue
  }

  /// Advance this iterator until it points to an occupied bucket with the
  /// specified value, or an unoccupied bucket -- whichever comes first.
  @inlinable
  @_effects(releasenone)
  package mutating func advance(until expected: Int) {
    while unsafe isOccupied && currentValue != expected {
      unsafe advance()
    }
  }

  /// Advance this iterator until it points to an unoccupied bucket.
  /// Useful when inserting an element that we know isn't already in the table.
  @inlinable
  @_effects(releasenone)
  package mutating func advanceToNextUnoccupiedBucket() {
    while isOccupied {
      unsafe advance()
    }
  }
}
