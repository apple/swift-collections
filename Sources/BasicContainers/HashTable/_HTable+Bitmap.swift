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

#if compiler(>=6.2)
extension _HTable {
  @usableFromInline
  @frozen
  package struct Bitmap: ~Copyable, ~Escapable {
    @usableFromInline
    package typealias Bucket = _HTable.Bucket

    @_alwaysEmitIntoClient
    package let _words: UnsafeMutableBufferPointer<Word>

    @_alwaysEmitIntoClient
    @_lifetime(borrow table)
    package init(table: borrowing _HTable) {
      self._words = .init(start: table._bitmap, count: table.wordCount)
    }
  }
}

extension _HTable.Bitmap {
  @_transparent
  @inlinable
  package func isValid(_ bucket: Bucket) -> Bool {
    bucket.word < _words.count
  }

  @_transparent
  @inlinable
  package func isOccupied(_ bucket: Bucket) -> Bool {
    assert(isValid(bucket))
    return _words[bucket.word].contains(bucket.bit)
  }

  @_transparent
  @inlinable
  package func setOccupied(_ bucket: Bucket) {
    assert(isValid(bucket))
    _words[bucket.word].set(bucket.bit)
  }

  @_transparent
  @inlinable
  package func clearOccupied(_ bucket: Bucket) {
    assert(isValid(bucket))
    _words[bucket.word].clear(bucket.bit)
  }

  @_transparent
  @inlinable
  package func clearAll() {
    _words.update(repeating: .empty)
  }
  
  @_alwaysEmitIntoClient
  package func occupiedCount() -> Int {
    var c = 0
    for i in 0 ..< _words.count {
      c += _words[i].count
    }
    return c
  }

  @inlinable
  package func firstOccupiedBucket(from start: Bucket) -> Bucket? {
    assert(isValid(start))

    var word = start.word
    var bits = _words[word]
    bits.removeAll(upTo: start.bit)

    while true {
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: bit)
      }
      word &+= 1
      if word >= _words.count {
        return nil
      }
      bits = _words[word]
    }
  }

  /// Note: If the bitmap has fewer than Word.capacity bits, then this may
  /// report an unoccupied bit beyond the end of its actual size.
  @inlinable
  package func firstUnoccupiedBucket(from start: Bucket) -> Bucket {
    assert(isValid(start))
    var word = start.word
    var bits = _words[word]
    bits.insertAll(upTo: start.bit)
    var wrapped = false
    while true {
      bits.formComplement()
      if let bit = bits.firstMember {
        return Bucket(word: word, bit: bit)
      }
      word &+= 1
      if word >= _words.count {
        precondition(!wrapped, "Corrupt hash table")
        wrapped = true
        word = 0
      }
      bits = _words[word]
    }
  }
}
#endif
