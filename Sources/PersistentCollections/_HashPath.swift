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
  internal var hash: _HashValue

  @usableFromInline
  internal var level: _Level

  @inlinable
  internal init(hash: _HashValue, level: _Level) {
    self.hash = hash
    self.level = level
  }

  @inlinable
  internal init(hash: _HashValue, shift: UInt) {
    self.init(hash: hash, level: _Level(shift: shift))
  }

  @inlinable
  internal init<Key: Hashable>(_ key: Key, level: _Level = .top) {
  self.init(hash: _HashValue(key), level: level)
  }

  @inlinable
  internal init<Key: Hashable>(_ key: Key, shift: UInt) {
    self.init(hash: _HashValue(key), level: _Level(shift: shift))
  }

  @inlinable
  internal var isAtRoot: Bool { level.isAtRoot }

  @inlinable
  internal var currentBucket: _Bucket {
    hash[level]
  }

  @inlinable
  internal func descend() -> _HashPath {
    // FIXME: Consider returning nil when we run out of bits
    _HashPath(hash: hash, level: level.descend())
  }

  @inlinable
  internal func ascend() -> _HashPath {
    _HashPath(hash: hash, level: level.ascend())
  }

  @inlinable
  internal func top() -> _HashPath {
    var result = self
    result.level = .top
    return result
  }
}
