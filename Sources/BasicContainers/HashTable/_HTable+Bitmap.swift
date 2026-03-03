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

  @inlinable
  package func firstUnoccupiedBucket(wrappingFrom start: Bucket) -> Bucket {
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
