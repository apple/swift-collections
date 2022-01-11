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
  public init() {
    self.init(_storage: [], count: 0)
  }

  @inlinable
  public init<S: Sequence>(
    _ elements: __owned S
  ) where S.Element: FixedWidthInteger {
    if S.self == BitSet.self {
      self = (elements as! BitSet)
      return
    }
    self.init()
    for value in elements {
      self.insert(value)
    }
  }

  @inlinable
  internal init<S: Sequence>(
    _validMembersOf elements: __owned S
  ) where S.Element: FixedWidthInteger {
    if S.self == BitSet.self {
      self = (elements as! BitSet)
      return
    }
    if S.self == Range<S.Element>.self {
      let r = (elements as! Range<S.Element>)
      self.init(r._clampedToUInt())
      return
    }
    self.init()
    for value in elements {
      guard let value = UInt(exactly: value) else { continue }
      _ = self._insert(value)
    }
  }
}

extension BitSet {
  @inlinable
  public init<I: FixedWidthInteger>(_ range: Range<I>) {
    guard
      let lower = UInt(exactly: range.lowerBound),
      let upper = UInt(exactly: range.upperBound)
    else {
      preconditionFailure("BitSet can only hold nonnegative integers")
    }
    let range = Range(uncheckedBounds: (lower, upper))
    self.init(_range: range)
  }

  @usableFromInline
  internal init(_range range: Range<UInt>) {
    _count = range.count
    _storage = []
    let lower = _UnsafeHandle.Index(range.lowerBound)
    let upper = _UnsafeHandle.Index(range.upperBound)
    if lower.word > 0 {
      _storage.append(contentsOf: repeatElement(.empty, count: lower.word))
    }
    if lower.word == upper.word {
      _storage.append(_Word(from: lower.bit, to: upper.bit))
    } else {
      _storage.append(_Word(upTo: lower.bit).complement())
      let filledWords = upper.word &- lower.word
      if filledWords > 0 {
        _storage.append(
          contentsOf: repeatElement(.allBits, count: filledWords &- 1))
      }
      _storage.append(_Word(upTo: upper.bit))
    }
    _shrink()
    _checkInvariants()
  }
}

extension BitSet {
  @inlinable
  public init<I: BinaryInteger>(bitPattern: I) {
    let words = bitPattern.words.map { _Word($0) }
    let count = words.reduce(into: 0) { $0 += $1.count }
    self.init(_storage: words, count: count)
  }
}

extension BitSet {
  internal init(
    _combining handles: (_UnsafeHandle, _UnsafeHandle),
    includingTail: Bool,
    using function: (_Word, _Word) -> _Word
  ) {
    let w1 = handles.0._words
    let w2 = handles.1._words
    let capacity = (
      includingTail
      ? Swift.max(w1.count, w2.count)
      : Swift.min(w1.count, w2.count))
    var c = 0
    _storage = Array(unsafeUninitializedCapacity: capacity) { buffer, count in
      let sharedCount = Swift.min(w1.count, w2.count)
      for w in 0 ..< sharedCount {
        buffer._initialize(at: w, to: function(w1[w], w2[w]))
      }
      if includingTail {
        if w1.count < w2.count {
          for w in w1.count ..< w2.count {
            buffer._initialize(at: w, to: function(_Word.empty, w2[w]))
          }
        } else {
          for w in w2.count ..< w1.count {
            buffer._initialize(at: w, to: function(w1[w], _Word.empty))
          }
        }
      }
      // Adjust the word count based on results.
      count = capacity
      while count > 0, buffer[count - 1].isEmpty {
        count -= 1
      }
      // Set the number of set bits.
      c = buffer.reduce(into: 0) { $0 += $1.count }
    }
    _count = c
    _checkInvariants()
  }
}
