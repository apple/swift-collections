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

extension BitArray {
  /// An unsafe-unowned bitarray view over `UInt` storage, providing bit array
  /// primitives.
  @usableFromInline
  @frozen
  @unsafe
  internal struct _UnsafeHandle {
    @usableFromInline
    internal typealias _BitPosition = _UnsafeBitSet.Index

    @usableFromInline
    @unsafe
    internal let _words: UnsafeBufferPointer<_Word>

    @usableFromInline
    @unsafe // Setter
    internal var _count: UInt

#if DEBUG
    /// True when this handle does not support table mutations.
    /// (This is only checked in debug builds.)
    @usableFromInline
    @safe
    internal let _mutable: Bool
#endif

    @inline(__always)
    @safe
    internal func ensureMutable() {
#if DEBUG
      assert(_mutable)
#endif
    }

    internal var _mutableWords: UnsafeMutableBufferPointer<_Word> {
      ensureMutable()
      return unsafe UnsafeMutableBufferPointer(mutating: _words)
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafeBufferPointer<_Word>,
      count: UInt,
      mutable: Bool
    ) {
      assert(count <= words.count * _Word.capacity)
      assert(count > (words.count - 1) * _Word.capacity)
      unsafe self._words = words
      unsafe self._count = count
#if DEBUG
      self._mutable = mutable
#endif
    }

    @inlinable
    @inline(__always)
    internal init(
      words: UnsafeMutableBufferPointer<_Word>,
      count: UInt,
      mutable: Bool
    ) {
      unsafe self.init(
        words: UnsafeBufferPointer(words),
        count: count,
        mutable: mutable)
    }
  }
}

extension BitArray._UnsafeHandle {
  @safe
  @_transparent
  internal var count: Int {
    unsafe Int(_count)
  }

  @safe
  internal var end: _BitPosition {
    unsafe _BitPosition(_count)
  }

  internal func set(at position: Int) {
    ensureMutable()
    assert(position >= 0 && position < count)
    let (word, bit) = _BitPosition(UInt(position)).split
    unsafe _mutableWords[word].insert(bit)
  }

  internal func clear(at position: Int) {
    ensureMutable()
    assert(position >= 0 && position < count)
    let (word, bit) = _BitPosition(UInt(position)).split
    unsafe _mutableWords[word].remove(bit)
  }

  internal subscript(position: Int) -> Bool {
    get {
      assert(position >= 0 && position < count)
      let (word, bit) = _BitPosition(UInt(position)).split
      return unsafe _words[word].contains(bit)
    }
    set {
      ensureMutable()
      assert(position >= 0 && position < count)
      let (word, bit) = _BitPosition(UInt(position)).split
      if newValue {
        unsafe _mutableWords[word].insert(bit)
      } else {
        unsafe _mutableWords[word].remove(bit)
      }
    }
  }
}

extension BitArray._UnsafeHandle {
  internal mutating func fill(in range: Range<Int>) {
    ensureMutable()
    precondition(
      range.lowerBound >= 0 && range.upperBound <= count,
      "Range out of bounds")
    guard range.count > 0 else { return }
    let (lw, lb) = _BitPosition(range.lowerBound).split
    let (uw, ub) = _BitPosition(range.upperBound).endSplit
    let words = unsafe _mutableWords
    guard lw != uw else {
      unsafe words[lw].formUnion(_Word(from: lb, to: ub))
      return
    }
    unsafe words[lw].formUnion(_Word(upTo: lb).complement())
    for w in lw + 1 ..< uw {
      unsafe words[w] = _Word.allBits
    }
    unsafe words[uw].formUnion(_Word(upTo: ub))
  }

  internal mutating func clear(in range: Range<Int>) {
    ensureMutable()
    precondition(
      range.lowerBound >= 0 && range.upperBound <= count,
      "Range out of bounds")
    guard range.count > 0 else { return }
    let (lw, lb) = _BitPosition(range.lowerBound).split
    let (uw, ub) = _BitPosition(range.upperBound).endSplit
    let words = unsafe _mutableWords
    guard lw != uw else {
      unsafe words[lw].subtract(_Word(from: lb, to: ub))
      return
    }
    unsafe words[lw].subtract(_Word(upTo: lb).complement())
    for w in lw + 1 ..< uw {
      unsafe words[w] = _Word.empty
    }
    unsafe words[uw].subtract(_Word(upTo: ub))
  }
}
