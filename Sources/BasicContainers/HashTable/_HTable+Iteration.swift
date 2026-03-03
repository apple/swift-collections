//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2)
extension _HTable {
  @usableFromInline
  @_lifetime(borrow self)
  package func makeBucketIterator(
    from start: Bucket = Bucket(offset: 0)
  ) -> BucketIterator {
    BucketIterator(table: self, startingAt: start)
  }

  /// An iterator construct for visiting a chain of buckets within the hash
  /// table. This is a convenient tool for implementing linear probing.
  ///
  /// Beyond merely providing bucket values, bucket iterators can also tell
  /// you their current opposition within the hash table, and (for mutable hash
  /// tables) they allow you update the value of the currently visited bucket.
  /// (This is useful when implementing simple insertions, for example.)
  ///
  /// - Warning: Like `UnsafeHandle`, `BucketIterator` does not have
  ///     ownership of its underlying storage buffer. You must not escape
  ///     iterator values outside the closure call that produced the original
  ///     hash table.
  @usableFromInline
  package struct BucketIterator: ~Escapable {
    @usableFromInline
    package typealias Bucket = _HTable.Bucket
    @usableFromInline
    package typealias Word = _HTable.Word

    /// The bitmap we are iterating over.
    @_alwaysEmitIntoClient
    package let _words: UnsafePointer<Word>?

    @_alwaysEmitIntoClient
    package let _endBucket: Bucket

    @_alwaysEmitIntoClient
    package var _bucket: Bucket
    
    /// Remaining bits not yet processed from the last word read.
    @_alwaysEmitIntoClient
    package var _nextBits: Word

    /// Number of remaining bits not yet processed from the last word read.
    @_alwaysEmitIntoClient
    package var _nextBitCount: UInt8

    @_alwaysEmitIntoClient
    package var _wrapped = false

    /// Create a new iterator starting at the specified bucket.
    @_effects(releasenone)
    @usableFromInline
    @_lifetime(borrow table)
    package init(table: borrowing _HTable, startingAt bucket: Bucket) {
      assert(table.isValid(bucket) || bucket == table.endBucket)
      assert(table.endBucket.bit == 0 || table.endBucket.word == 0) // We rely on this throughout the code below
      self._bucket = bucket
      if let bitmap = table._bitmap {
        self._words = .init(bitmap)
        self._endBucket = table.endBucket
        self._nextBits = bitmap[_bucket.word].shiftedDown(by: _bucket.bit)
        if table.endBucket._offset < Word.capacity {
          self._nextBitCount = UInt8(table.endBucket.bit &- _bucket.bit)
        } else {
          self._nextBitCount = UInt8(Word._capacity &- _bucket.bit)
        }
      } else {
        self._words = nil
        self._endBucket = Bucket(offset: table.count) // Note: not capacity!
        self._nextBits = .empty
        self._nextBitCount = 0
      }
    }
  }
}

extension _HTable.BucketIterator {
  @usableFromInline
  @_transparent
  package var currentBucket: Bucket {
    _bucket
  }
  
  @usableFromInline
  @_transparent
  package var isAtEnd: Bool {
    _bucket >= _endBucket
  }
  
  @usableFromInline
  @_transparent
  package var isOccupied: Bool {
    assert(!isAtEnd)
    if _words == nil { return true }
    return _nextBits.contains(0)
  }
  
  @_transparent
  @_lifetime(self: copy self)
  package mutating func restart() {
    _wrapped = true
    _bucket._offset = 0
    if let words = _words {
      _nextBits = words[_bucket.word]
      _nextBitCount = UInt8(Swift.min(Word._capacity, _endBucket._offset))
    }
  }
  
  @_transparent
  @_lifetime(self: copy self)
  package mutating func _wrap() {
    precondition(!_wrapped, "Corrupt hash table")
    restart()
  }

  
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func _advanceToNextWord() -> Bool {
    assert(!isAtEnd)
    _bucket.advanceToNextWord()
    if isAtEnd {
      _bucket = _endBucket
      _nextBits = .empty
      _nextBitCount = 0
      return false
    }
    if let words = _words{
      _nextBits = words[_bucket.word]
      _nextBitCount = UInt8(Word._capacity)
    }
    return true
  }

  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func _wrapToNextWord() {
    _bucket.advanceToNextWord()
    if isAtEnd {
      _wrap()
    } else if let words = _words {
      _nextBits = words[_bucket.word]
      _nextBitCount = UInt8(Word._capacity)
    }
  }

  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func advanceToNextBit() -> Bool {
    assert(!isAtEnd)
    _bucket._offset &+= 1
    if isAtEnd {
      _nextBits = .empty
      _nextBitCount = 0
      return false
    }
    guard let words = _words else { return true }
    assert(_nextBitCount > 0)
    _nextBitCount &-= 1
    if _nextBitCount > 0 {
      _nextBits = _nextBits.shiftedDown(by: 1)
    } else {
      assert(_bucket.bit == 0)
      _nextBits = words[_bucket.word]
      _nextBitCount = UInt8(Word._capacity)
    }
    return true
  }

  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func wrapToNextBit() {
    _bucket._offset &+= 1
    if isAtEnd {
      _wrap()
      return
    }
    guard let words = _words else { return }
    assert(_nextBitCount > 0)
    _nextBitCount &-= 1
    if _nextBitCount > 0 {
      _nextBits = _nextBits.shiftedDown(by: 1)
    } else {
      _nextBits = words[_bucket.word]
      _nextBitCount = UInt8(Word._capacity)
    }
  }

  /// If the current bucket is already occupied, this does nothing.
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func advanceToOccupied() -> Bool {
    if isAtEnd { return false }
    if _words == nil {
      return true
    }
    while true {
      if let first = _nextBits.firstMember {
        _nextBits = _nextBits.shiftedDown(by: first)
        _nextBitCount &-= UInt8(first)
        _bucket._offset &+= first
        break
      }
      guard _advanceToNextWord() else { return false }
    }
    return true
  }

  /// If the current bucket is already occupied, this does nothing.
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func advanceToOccupied(
    maximumCount: Int
  ) -> Bool {
    var remainder = UInt(bitPattern: maximumCount)
    if isAtEnd { return false }
    if _words == nil {
      let delta = Swift.min(_endBucket._offset &- _bucket._offset, remainder)
      _bucket._offset &+= delta
      return true
    }
    while true {
      if let first = _nextBits.firstMember {
        let c = Swift.min(remainder, first)
        _nextBits = _nextBits.shiftedDown(by: c)
        _nextBitCount &-= UInt8(c)
        _bucket._offset &+= c
        remainder &-= c
        break
      }
      if remainder < _nextBitCount {
        _nextBits = _nextBits.shiftedDown(by: remainder)
        _nextBitCount &-= UInt8(remainder)
        _bucket._offset &+= remainder
        remainder = 0
        break
      }
      remainder &-= UInt(_nextBitCount)
      guard _advanceToNextWord() else { return false }
    }
    return true
  }
  
  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func wrapToOccupied() {
    if _words == nil {
      wrapToNextBit()
      return
    }
    while true {
      if let first = _nextBits.firstMember {
        _nextBits = _nextBits.shiftedDown(by: first)
        _nextBitCount &-= UInt8(first)
        _bucket._offset &+= first
        break
      }
      _wrapToNextWord()
    }
  }

  /// If the current bucket is already unoccupied, this does nothing.
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func advanceToUnoccupied() -> Bool {
    assert(!isAtEnd)
    if _words == nil {
      _bucket = _endBucket
      return false
    }
    while true {
      let emptyBits = Word(upTo: UInt(_nextBitCount)).subtracting(_nextBits)
      if let first = emptyBits.firstMember {
        _nextBits = _nextBits.shiftedDown(by: first)
        _nextBitCount &-= UInt8(first)
        _bucket._offset &+= first
        break
      }
      guard _advanceToNextWord() else { return false }
    }
    return true
  }

  /// If the current bucket is already unoccupied, this does nothing.
  @usableFromInline
  @discardableResult
  @_lifetime(self: copy self)
  package mutating func advanceToUnoccupied(
    maximumCount: Int
  ) -> Bool {
    assert(maximumCount > 0)
    assert(!isAtEnd)
    var remainder = UInt(bitPattern: maximumCount)
    if _words == nil {
      let delta = Swift.min(_endBucket._offset &- _bucket._offset, remainder)
      _bucket._offset &+= delta
      return false
    }
    while remainder > 0 {
      let emptyBits = Word(upTo: UInt(_nextBitCount)).subtracting(_nextBits)
      if let first = emptyBits.firstMember {
        let c = Swift.min(remainder, first)
        _nextBits = _nextBits.shiftedDown(by: c)
        _nextBitCount &-= UInt8(c)
        _bucket._offset &+= c
        remainder &-= c
        break
      }
      if remainder < _nextBitCount {
        _nextBits = _nextBits.shiftedDown(by: remainder)
        _nextBitCount &-= UInt8(remainder)
        _bucket._offset &+= remainder
        remainder = 0
        break
      }
      remainder &-= UInt(_nextBitCount)
      guard _advanceToNextWord() else { return false }
    }
    return true
  }

  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func wrapToUnoccupied() {
    if _words == nil {
      _bucket = _endBucket
      return
    }
    while true {
      if let first = _nextBits.complement().firstMember {
        _nextBits = _nextBits.shiftedDown(by: first)
        _nextBitCount &-= UInt8(first)
        _bucket._offset &+= first
        break
      }
      _wrapToNextWord()
    }
  }

  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func nextOccupiedRegion(
    maximumCount: Int = .max
  ) -> Range<Bucket>? {
    assert(maximumCount > 0)
    guard self.advanceToOccupied() else { return nil }
    assert(self.isOccupied)
    let start = self.currentBucket
    self.advanceToUnoccupied(maximumCount: maximumCount)
    let end = self.currentBucket
    return Range(uncheckedBounds: (start, end))
  }
  
  @usableFromInline
  @_lifetime(self: copy self)
  package mutating func nextUnoccupiedRegion(
    maximumCount: Int = .max
  ) -> Range<Bucket>? {
    assert(maximumCount > 0)
    guard self.advanceToUnoccupied() else { return nil }
    assert(!self.isOccupied)
    let start = self.currentBucket
    self.advanceToOccupied(maximumCount: maximumCount)
    let end = self.currentBucket
    return Range(uncheckedBounds: (start, end))
  }
}
#endif
