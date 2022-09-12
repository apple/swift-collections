//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A structure for slicing up a hash value into a series of bucket values,
/// representing a path inside the prefix tree.
@usableFromInline
@frozen
internal struct _HashPath {
  @usableFromInline
  internal var _hash: _HashValue

  @usableFromInline
  internal var _shift: UInt

  @inlinable
  internal init(_hash: _HashValue, shift: UInt) {
    self._hash = _hash
    self._shift = shift
  }

  internal init<Key: Hashable>(_ key: Key) {
    _hash = _HashValue(key)
    _shift = 0
  }

  @inlinable
  internal var isAtRoot: Bool { _shift == 0 }

  @inlinable
  internal var currentBucket: _Bucket {
    precondition(_shift < UInt.bitWidth, "Ran out of hash bits")
    return _Bucket((_hash.value &>> _shift) & _Bucket.bitMask)
  }

  @inlinable
  internal func descend() -> _HashPath {
    // FIXME: Consider returning nil when we run out of bits
    let s = _shift &+ UInt(bitPattern: _Bucket.bitWidth)
    return _HashPath(_hash: _hash, shift: s)
  }

  @inlinable
  internal func ascend() -> _HashPath {
    precondition(_shift >= _Bucket.bitWidth)
    let s = _shift &- UInt(bitPattern: _Bucket.bitWidth)
    return _HashPath(_hash: _hash, shift: s)
  }

  @inlinable
  internal func top() -> _HashPath {
    var result = self
    result._shift = 0
    return result
  }
}
