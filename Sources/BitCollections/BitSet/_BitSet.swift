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

public struct _BitSet {
  @usableFromInline
  internal var _storage: [_Word]

  @usableFromInline
  internal var _count: Int

  @usableFromInline
  init() {
    _storage = []
    _count = 0
  }

  @usableFromInline
  init(storage: [_Word], count: Int) {
    self._storage = storage
    self._count = count
  }
}

extension _BitSet {
  @inline(__always)
  internal func _read<R>(
    _ body: (UnsafeHandle) throws -> R
  ) rethrows -> R {
    try _storage.withUnsafeBufferPointer { words in
      let handle = UnsafeHandle(words: words, count: _count, mutable: false)
      return try body(handle)
    }
  }

  @usableFromInline
  internal var _capacity: UInt {
    UInt(_storage.count) &* UInt(_Word.capacity)
  }

  internal mutating func _ensureCapacity(limit capacity: UInt) {
    let desired = UnsafeHandle.wordCount(forCapacity: capacity)
    guard _storage.count < desired else { return }
    _storage.append(
      contentsOf: repeatElement(.empty, count: desired - _storage.count))
  }

  internal mutating func _ensureCapacity(forValue value: UInt) {
    let desiredWord = UnsafeHandle.Index(value).word
    guard desiredWord >= _storage.count else { return }
    _storage.append(
      contentsOf:
        repeatElement(.empty, count: desiredWord - _storage.count + 1))
  }

  internal mutating func _shrink() {
    let suffix = _read { $0.emptySuffix() }
    if suffix > 0 { _storage.removeLast(suffix) }
  }

  @inline(__always)
  internal mutating func _update<R>(
    _ body: (inout UnsafeHandle) throws -> R
  ) rethrows -> R {
    var c = _count
    defer {
      _count = c
      _checkInvariants()
    }
    return try _storage.withUnsafeMutableBufferPointer { words in
      var handle = UnsafeHandle(words: words, count: c, mutable: true)
      defer {
        assert(c <= words.count * _Word.capacity)
        c = handle.count
      }
      return try body(&handle)
    }
  }

  @inline(__always)
  internal mutating func _updateThenShrink<R>(
    _ body: (_ handle: inout UnsafeHandle, _ shrink: inout Bool) throws -> R
  ) rethrows -> R {
    var shrink = true
    defer {
      if shrink { _shrink() }
      _checkInvariants()
    }
    return try _storage.withUnsafeMutableBufferPointer { words in
      var handle = UnsafeHandle(
        words: words, count: _count, mutable: true)
      defer {
        _count = handle.count
      }
      return try body(&handle, &shrink)
    }
  }
}
