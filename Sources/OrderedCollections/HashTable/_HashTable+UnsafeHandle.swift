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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@usableFromInline
package typealias _UnsafeHashTable = _HashTable.UnsafeHandle

extension _HashTable {
  /// A non-owning handle to hash table storage, implementing higher-level
  /// table operations.
  ///
  /// - Warning: `_UnsafeHashTable` values do not have ownership of their
  ///    underlying storage buffer. You must not escape these handles outside
  ///    the closure call that produced them.
  @usableFromInline
  @frozen
  @unsafe
  package struct UnsafeHandle {
    @usableFromInline
    package typealias Bucket = _HashTable.Bucket

    /// A pointer to the table header.
    @usableFromInline
    package var _header: UnsafeMutablePointer<Header>

    /// A pointer to bucket storage.
    @usableFromInline
    package var _buckets: UnsafeMutablePointer<UInt64>

    #if DEBUG
    /// True when this handle does not support table mutations.
    /// (This is only checked in debug builds.)
    @usableFromInline
    @safe
    package let _readonly: Bool
    #endif

    /// Initialize a new hash table handle for storage at the supplied locations.
    @inlinable
    @inline(__always)
    package init(
      header: UnsafeMutablePointer<Header>,
      buckets: UnsafeMutablePointer<UInt64>,
      readonly: Bool
    ) {
      unsafe self._header = header
      unsafe self._buckets = buckets
      #if DEBUG
      self._readonly = readonly
      #endif
    }

    /// Check that this handle supports mutating operations.
    /// Every member that mutates table data must start by calling this function.
    /// This helps preventing COW violations.
    ///
    /// Note that this is a noop in release builds.
    @inlinable
    @inline(__always)
    @safe
    package func assertMutable() {
      #if DEBUG
      assert(!_readonly, "Attempt to mutate a hash table through a read-only handle")
      #endif
    }
  }
}

extension _HashTable.UnsafeHandle {
  @inlinable
  package func isIdentical(to other: Self) -> Bool {
    guard
      unsafe self._header == other._header,
      unsafe self._buckets == other._buckets
    else { return false }
#if DEBUG
    guard self._readonly == other._readonly else { return false }
#endif
    return true
  }

  /// The scale of the hash table. A table of scale *n* holds 2^*n* buckets,
  /// each of which contain an *n*-bit value.
  @inlinable
  @inline(__always)
  package var scale: Int { unsafe _header.pointee.scale }

  /// The scale corresponding to the last call to `reserveCapacity`.
  /// We store this to make sure we don't shrink the table below its reserved size.
  @inlinable
  @inline(__always)
  package var reservedScale: Int { unsafe _header.pointee.reservedScale }

  /// The hasher seed to use within this hash table.
  @inlinable
  @inline(__always)
  package var seed: Int { unsafe _header.pointee.seed }

  /// A bias value that needs to be added to buckets to convert them into offsets
  /// into element storage. (This allows O(1) insertions at the front when the
  /// underlying storage supports it.)
  @inlinable
  @inline(__always)
  package var bias: Int {
    get { unsafe _header.pointee.bias }
    nonmutating set { unsafe _header.pointee.bias = newValue }
  }

  /// The number of buckets within this hash table. This is always a power of two.
  @inlinable
  @inline(__always)
  package var bucketCount: Int { unsafe 1 &<< scale }

  @inlinable
  @inline(__always)
  package var bucketMask: UInt64 { unsafe UInt64(truncatingIfNeeded: bucketCount) - 1 }

  /// The number of bits used to store all the buckets in this hash table.
  /// Each bucket holds a value that is `scale` bits wide.
  @inlinable
  @inline(__always)
  package var bitCount: Int { unsafe scale &<< scale }

  /// The number of 64-bit words that are available in the storage buffer,
  /// rounded up to the nearest whole number if necessary.
  @inlinable
  @inline(__always)
  package var wordCount: Int { unsafe (bitCount + UInt64.bitWidth - 1) / UInt64.bitWidth }

  /// The maximum number of items that can fit into this table.
  @inlinable
  @inline(__always)
  package var capacity: Int { unsafe _HashTable.maximumCapacity(forScale: scale) }

  /// Return the bucket logically following `bucket` in this hash table.
  /// The buckets form a cycle, so the last bucket is logically followed by the first.
  @inlinable
  @inline(__always)
  package func bucket(after bucket: Bucket) -> Bucket {
    var offset = bucket.offset + 1
    if unsafe offset == bucketCount {
      offset = 0
    }
    return Bucket(offset: offset)
  }

  /// Return the bucket logically preceding `bucket` in this hash table.
  /// The buckets form a cycle, so the first bucket is logically preceded by the last.
  @inlinable
  @inline(__always)
  package func bucket(before bucket: Bucket) -> Bucket {
    let offset = (bucket.offset == 0 ? unsafe bucketCount : bucket.offset) - 1
    return Bucket(offset: offset)
  }

  /// Return the index of the word logically following `word` in this hash table.
  /// The buckets form a cycle, so the last word is logically followed by the first.
  ///
  /// Note that the last word may be only partially filled if `scale` is less than 6.
  @inlinable
  @inline(__always)
  package func word(after word: Int) -> Int {
    var result = word + 1
    if unsafe result == wordCount {
      result = 0
    }
    return result
  }

  /// Return the index of the word logically preceding `word` in this hash table.
  /// The buckets form a cycle, so the first word is logically preceded by the last.
  ///
  /// Note that the last word may be only partially filled if `scale` is less than 6.
  @inlinable
  @inline(__always)
  package func word(before word: Int) -> Int {
    if word == 0 {
      return unsafe wordCount - 1
    }
    return word - 1
  }

  /// Return the index of the 64-bit storage word that holds the first bit
  /// corresponding to `bucket`, along with its bit position within the word.
  @inlinable
  package func position(of bucket: Bucket) -> (word: Int, bit: Int) {
    let start = unsafe bucket.offset &* scale
    return (start &>> 6, start & 0x3F)
  }
}

extension _HashTable.UnsafeHandle {
  /// Decode and return the logical value corresponding to the specified bucket value.
  ///
  /// The nil value is represented by an all-zero bit pattern.
  /// Other values are stored as the complement of the lowest `scale` bits
  /// after taking `bias` into account.
  /// The range of representable values is `0 ..< bucketCount - 1`.
  /// (Note that the value `bucketCount - 1` is missing from this range, as its
  /// encoding is used for `nil`. This isn't an issue, because the maximum load
  /// factor guarantees that the hash table will never be completely full.)
  @inlinable
  package func _value(forBucketContents bucketContents: UInt64) -> Int? {
    let mask = unsafe bucketMask
    assert(bucketContents <= mask)
    guard bucketContents != 0 else { return nil }
    let v = (bucketContents ^ mask) &+ UInt64(truncatingIfNeeded: unsafe bias)
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
  @inlinable
  package func _bucketContents(for value: Int?) -> UInt64 {
    guard var value = value else { return 0 }
    let mask = Int(truncatingIfNeeded: unsafe bucketMask)
    assert(value >= 0 && value < mask)
    value &-= unsafe bias
    if value < 0 { value += mask }
    assert(value >= 0 && value < mask)
    return UInt64(truncatingIfNeeded: value ^ mask)
  }

  @inlinable
  package subscript(word word: Int) -> UInt64 {
    @inline(__always) get {
      assert(unsafe word >= 0 && word < wordCount)
      return unsafe _buckets[word]
    }
    @inline(__always) nonmutating set {
      assert(unsafe word >= 0 && word < wordCount)
      assertMutable()
      unsafe _buckets[word] = newValue
    }
  }

  @inlinable
  package subscript(raw bucket: Bucket) -> UInt64 {
    get {
      assert(unsafe bucket.offset < bucketCount)
      let (word, bit) = unsafe position(of: bucket)
      var value = unsafe self[word: word] &>> bit
      let extractedBits = 64 - bit
      if unsafe extractedBits < scale {
        let word2 = unsafe self.word(after: word)
        value &= (1 &<< extractedBits) - 1
        unsafe value |= self[word: word2] &<< extractedBits
      }
      return unsafe value & bucketMask
    }
    nonmutating set {
      assertMutable()
      assert(unsafe bucket.offset < bucketCount)
      let mask = unsafe bucketMask
      assert(newValue <= mask)
      let (word, bit) = unsafe position(of: bucket)
      unsafe self[word: word] &= ~(mask &<< bit)
      unsafe self[word: word] |= newValue &<< bit
      let extractedBits = 64 - bit
      if unsafe extractedBits < scale {
        let word2 = unsafe self.word(after: word)
        unsafe self[word: word2] &= ~((1 &<< (scale - extractedBits)) - 1)
        unsafe self[word: word2] |= newValue &>> extractedBits
      }
    }
  }

  @inlinable
  @inline(__always)
  package func isOccupied(_ bucket: Bucket) -> Bool {
    unsafe self[raw: bucket] != 0
  }

  /// Return or update the current value stored in the specified bucket.
  /// A nil value indicates that the bucket is empty.
  @inlinable
  package subscript(bucket: Bucket) -> Int? {
    get {
      let contents = unsafe self[raw: bucket]
      return unsafe _value(forBucketContents: contents)
    }
    nonmutating set {
      assertMutable()
      let v = unsafe _bucketContents(for: newValue)
      unsafe self[raw: bucket] = v
    }
  }
}

extension _UnsafeHashTable {
  @inlinable
  package func _find<Element: Hashable>(
    _ item: Element,
    in elements: ContiguousArray<Element>
  ) -> (index: Int?, bucket: Bucket) {
    elements.withUnsafeBufferPointer { buffer in
      unsafe _find(item, in: buffer)
    }
  }

  @inlinable
  package func _find<Element: Hashable>(
    _ item: Element,
    in elements: UnsafeBufferPointer<Element>
  ) -> (index: Int?, bucket: Bucket) {
    let start = unsafe idealBucket(for: item)
    var (iterator, value) = unsafe startFind(start)
    while let index = value {
      if unsafe elements[_offset: index] == item {
        return (index, iterator.currentBucket)
      }
      value = unsafe iterator.findNext()
    }
    return (nil, iterator.currentBucket)
  }
}

extension _UnsafeHashTable {
  @usableFromInline
  package func firstOccupiedBucketInChain(with bucket: Bucket) -> Bucket {
    var bucket = bucket
    repeat {
      bucket = unsafe self.bucket(before: bucket)
    } while unsafe isOccupied(bucket)
    return unsafe self.bucket(after: bucket)
  }

  @inlinable
  package func delete(
    bucket: Bucket,
    hashValueGenerator: (Int, Int) -> Int // (offset, seed) -> hashValue
  ) {
    assertMutable()
    var it = unsafe bucketIterator(startingAt: bucket)
    assert(it.isOccupied)
    unsafe it.advance()
    guard it.isOccupied else {
      // Fast path: Don't get the start bucket when there's nothing to do.
      unsafe self[bucket] = nil
      return
    }
    // If we've put a hole in the middle of a collision chain, some element after
    // the hole may belong where the new hole is.

    // Find the first bucket in the collision chain that contains the entry we've just deleted.
    let start = unsafe firstOccupiedBucketInChain(with: bucket)
    var hole = bucket

    while it.isOccupied {
      let hash = unsafe hashValueGenerator(it.currentValue!, seed)
      let candidate = unsafe idealBucket(forHashValue: hash)

      // Does this element belong between start and hole?  We need two
      // separate tests depending on whether [start, hole] wraps around the
      // end of the storage.
      let c0 = candidate.offset >= start.offset
      let c1 = candidate.offset <= hole.offset
      if start.offset <= hole.offset ? (c0 && c1) : (c0 || c1) {
        // Fill the hole. Here we are mutating table contents behind the back of
        // the iterator; this is okay since we know we are never going to revisit
        // `hole` with it.
        unsafe self[hole] = it.currentValue
        hole = it.currentBucket
      }
      unsafe it.advance()
    }
    unsafe self[hole] = nil
  }
}

extension _UnsafeHashTable {
  @inlinable
  package func adjustContents<Base: RandomAccessCollection>(
    preparingForInsertionOfElementAtOffset offset: Int,
    in elements: Base
  ) where Base.Element: Hashable {
    assertMutable()
    let index = elements._index(at: offset)
    if offset < elements.count / 2 {
      unsafe self.bias += 1
      if unsafe offset <= capacity / 3 {
        var i = 1
        for item in elements[..<index] {
          var it = unsafe bucketIterator(for: item)
          unsafe it.advance(until: i)
          unsafe it.currentValue! -= 1
          i += 1
        }
      } else {
        var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
        repeat {
          if let value = unsafe it.currentValue, value <= offset {
            unsafe it.currentValue = value - 1
          }
          unsafe it.advance()
        } while it.currentBucket.offset != 0
      }
    } else {
      if unsafe elements.count - offset - 1 <= capacity / 3 {
        var i = offset
        for item in elements[index...] {
          var it = unsafe bucketIterator(for: item)
          unsafe it.advance(until: i)
          unsafe it.currentValue! += 1
          i += 1
        }
      } else {
        var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
        repeat {
          if let value = unsafe it.currentValue, value >= offset {
            unsafe it.currentValue = value + 1
          }
          unsafe it.advance()
        } while it.currentBucket.offset != 0
      }
    }
  }
}

extension _UnsafeHashTable {
  @inlinable
  @inline(__always)
  package func adjustContents<Base: RandomAccessCollection>(
    preparingForRemovalOf index: Base.Index,
    in elements: Base
  ) where Base.Element: Hashable {
    let next = elements.index(after: index)
    unsafe adjustContents(preparingForRemovalOf: index ..< next, in: elements)
  }

  @inlinable
  package func adjustContents<Base: RandomAccessCollection>(
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
      let tailCount = elements.count - endOffset
      if unsafe tailCount < capacity / 3 {
        var i = endOffset
        for item in elements[bounds.upperBound...] {
          var it = unsafe self.bucketIterator(for: item)
          unsafe it.advance(until: i)
          unsafe it.currentValue = i - c
          i += 1
        }
      } else {
        var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
        repeat {
          if let value = unsafe it.currentValue {
            if value >= endOffset {
              unsafe it.currentValue = value - c
            } else {
              assert(value < startOffset)
            }
          }
          unsafe it.advance()
        } while it.currentBucket.offset != 0
      }
    } else {
      if unsafe startOffset < capacity / 3 {
        var i = 0
        for item in elements[..<bounds.lowerBound] {
          var it = unsafe self.bucketIterator(for: item)
          unsafe it.advance(until: i)
          unsafe it.currentValue = i + c
          i += 1
        }
      } else {
        var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
        repeat {
          if let value = unsafe it.currentValue {
            if value < startOffset {
              unsafe it.currentValue = value + c
            } else {
              assert(value >= endOffset)
            }
          }
          unsafe it.advance()
        } while it.currentBucket.offset != 0
      }
      unsafe self.bias -= c
    }
  }
}

extension _UnsafeHashTable {
  @inlinable
  package func reverse(count: Int) {
    assertMutable()
    var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
    repeat {
      if let value = unsafe it.currentValue {
        unsafe it.currentValue = count - 1 - value
      }
      unsafe it.advance()
    } while it.currentBucket.offset != 0
  }
}

extension _UnsafeHashTable {
  @usableFromInline
  package func clear() {
    assertMutable()
    unsafe _buckets.update(repeating: 0, count: wordCount)
  }
}

extension _UnsafeHashTable {
  /// Fill an empty hash table by populating it with data from `elements`.
  ///
  /// - Parameter elements: A random-access collection for which this table is being generated.
  @inlinable
  package func fill<C: RandomAccessCollection>(
    uncheckedUniqueElements elements: C
  ) where C.Element: Hashable {
    assertMutable()
    assert(unsafe elements.count <= capacity)
    // fast path that doesn't allocate per element if _read accessor can't
    // be inlined because this function doesn't get specialized e.g.
    // if `Element` isn't known at compile time.
    let fastPath: Void? = elements.withContiguousStorageIfAvailable { elements in
      // Iterate over elements and insert their offset into the hash table.
      var offset = 0
      for index in elements.indices {
        // Find the insertion position. We know that we're inserting a new item,
        // so there is no need to compare it with any of the existing ones.
        var it = unsafe bucketIterator(for: elements[index])
        unsafe it.advanceToNextUnoccupiedBucket()
        unsafe it.currentValue = offset
        offset += 1
      }
    }
    if fastPath != nil {
      return
    }
    // Iterate over elements and insert their offset into the hash table.
    var offset = 0
    for index in elements.indices {
      // Find the insertion position. We know that we're inserting a new item,
      // so there is no need to compare it with any of the existing ones.
      var it = unsafe bucketIterator(for: elements[index])
      unsafe it.advanceToNextUnoccupiedBucket()
      unsafe it.currentValue = offset
      offset += 1
    }
  }

  /// Fill an empty hash table by populating it with data from `elements`.
  ///
  /// - Parameter elements: A random-access collection for which this table is being generated.
  /// - Returns: `(success, index)` where `success` is a boolean value indicating that every value in `elements` was successfully inserted. A false success indicates that duplicate elements have been found; in this case `index` points to the first duplicate value; otherwise `index` is set to `elements.endIndex`.
  @inlinable
  package func fill<C: RandomAccessCollection>(
    untilFirstDuplicateIn elements: C
  ) -> (success: Bool, end: C.Index)
  where C.Element: Hashable {
    assertMutable()
    assert(unsafe elements.count <= capacity)
    // Iterate over elements and insert their offset into the hash table.
    
    // fast path that doesn't allocate per element if _read accessor can't
    // be inlined because this function doesn't get specialized e.g.
    // if `Element` isn't known at compile time.
    let fastPath: (success: Bool, end: Int)? = elements.withContiguousStorageIfAvailable { elements in
      var offset = 0
      for index in elements.indices {
        // Find the insertion position. We know that we're inserting a new item,
        // so there is no need to compare it with any of the existing ones.
        var it = unsafe bucketIterator(for: elements[index])
        while let offset = unsafe it.currentValue {
          guard unsafe elements[_offset: offset] != elements[index] else {
            return (false, index)
          }
          unsafe it.advance()
        }
        unsafe it.currentValue = offset
        offset += 1
      }
      return (true, elements.endIndex)
    }
    if let fastPath {
      return (fastPath.success, elements.index(elements.startIndex, offsetBy: fastPath.end))
    }
    var offset = 0
    for index in elements.indices {
      // Find the insertion position. We know that we're inserting a new item,
      // so there is no need to compare it with any of the existing ones.
      var it = unsafe bucketIterator(for: elements[index])
      while let offset = unsafe it.currentValue {
        guard elements[_offset: offset] != elements[index] else {
          return (false, index)
        }
        unsafe it.advance()
      }
      unsafe it.currentValue = offset
      offset += 1
    }
    return (true, elements.endIndex)
  }
}
