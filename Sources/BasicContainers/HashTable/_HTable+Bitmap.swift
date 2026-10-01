//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension _HTable {
  @usableFromInline
  @frozen
  @safe
  package struct Bitmap: ~Copyable, ~Escapable {
    @usableFromInline
    package typealias Bucket = _HTable.Bucket

    @_alwaysEmitIntoClient
    package let _words: UnsafeMutableBufferPointer<Word>

    @_alwaysEmitIntoClient
    @_lifetime(borrow table)
    package init(table: borrowing _HTable) {
      unsafe self._words = .init(start: table._bitmap, count: table.wordCount)
    }
  }
}

extension _HTable.Bitmap {
  @usableFromInline
  package typealias Word = _HTable.Word

  @_transparent
  @inlinable
  @safe
  package func isValid(_ bucket: Bucket) -> Bool {
    unsafe bucket.word < _words.count
  }

  @_transparent
  @inlinable
  package func isOccupied(_ bucket: Bucket) -> Bool {
    assert(isValid(bucket))
    return unsafe _words[bucket.word].contains(bucket.bit)
  }

  @_transparent
  @inlinable
  package func setOccupied(_ bucket: Bucket) {
    assert(isValid(bucket))
    unsafe _words[bucket.word].set(bucket.bit)
  }

  @_transparent
  @inlinable
  package func clearOccupied(_ bucket: Bucket) {
    assert(isValid(bucket))
    unsafe _words[bucket.word].clear(bucket.bit)
  }

  @_transparent
  @inlinable
  package func clearAll() {
    unsafe _words.update(repeating: .empty)
  }

  @_alwaysEmitIntoClient
  package func occupiedCount() -> Int {
    var c = 0
    for i in unsafe 0 ..< _words.count {
      unsafe c += _words[i].count
    }
    return c
  }

  @inlinable
  package func firstOccupiedBucket(from start: Bucket) -> Bucket? {
    guard isValid(start) else { return nil }

    var word = start.word
    var bits = unsafe _words[word]
    bits.removeAll(upTo: start.bit)

    while true {
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: bit)
      }
      word &+= 1
      if unsafe word >= _words.count {
        return nil
      }
      unsafe bits = _words[word]
    }
  }

  @inlinable
  package func firstOccupiedBucket(
    from start: Bucket, limit: Bucket
  ) -> Bucket {
    assert(unsafe isValid(start) && start <= limit && limit.word <= _words.count)
    var word = start.word
    var bits = unsafe _words[word]
    bits.removeAll(upTo: start.bit)
    while word < limit.word {
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: bit)
      }
      word &+= 1
      unsafe bits = word < _words.count ? _words[word] : .empty
    }
    bits.removeAll(from: limit.bit)
    if let bit = bits.firstMember {
      return Bucket(word: word, bit: bit)
    }
    return limit
  }

  /// Note: If the bitmap has fewer than Word.capacity bits, then this may
  /// report an unoccupied bit beyond the end of its actual size.
  @inlinable
  package func collisionChainEnd(from start: Bucket) -> Bucket {
    assert(isOccupied(start))
    var word = start.word
    var bits = unsafe _words[word]
    bits.insertAll(upTo: start.bit)
    var wrapped = false
    while true {
      bits.formComplement()
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: bit)
      }
      word &+= 1
      if unsafe word >= _words.count {
        precondition(!wrapped, "Corrupt hash table")
        wrapped = true
        word = 0
      }
      unsafe bits = _words[word]
    }
  }

  /// Note: If the bitmap has fewer than Word.capacity bits, then this may
  /// report an unoccupied bit beyond the end of its actual size.
  internal func _nextOccupiedChunkEnd(
    from start: Bucket,
    maxCount: Int
  ) -> Bucket {
    assert(isValid(start))
    var word = start.word
    var bits = unsafe _words[word]
    bits.insertAll(upTo: start.bit)
    var remainder = unsafe Swift.min(
      UInt(bitPattern: maxCount) &+ start.bit,
      UInt(bitPattern: (_words.count &- start.word) &* Word.capacity))
    while true {
      bits.formComplement()
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: Swift.min(bit, remainder))
      }
      if remainder < Word.capacity {
        break
      }
      word &+= 1
      remainder &-= Word._capacity
      guard remainder > 0 else { break }
      assert(unsafe word < _words.count)
      unsafe bits = _words[word]
    }
    return Bucket(word: word, bit: remainder)
  }

  @usableFromInline
  package func nextOccupiedRegion(
    from bucket: inout Bucket,
    maxCount: Int,
    limit: Bucket
  ) -> Range<Bucket> {
    assert(isOccupied(bucket))
    assert(bucket <= limit)
    assert(maxCount > 0)
    let end = self._nextOccupiedChunkEnd(
      from: bucket,
      maxCount: Swift.min(maxCount, limit.offset &- bucket.offset))
    let result = unsafe Range(uncheckedBounds: (bucket, end))
    if isValid(end), !isOccupied(end) {
      bucket = firstOccupiedBucket(from: end, limit: limit)
    } else {
      bucket = end
    }
    return result
  }
}
