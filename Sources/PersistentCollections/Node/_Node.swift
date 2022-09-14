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

@usableFromInline
@frozen
internal struct _RawNode {
  @usableFromInline
  internal var storage: _RawStorage

  @usableFromInline
  internal var count: Int

  @inlinable
  internal init(storage: _RawStorage, count: Int) {
    self.storage = storage
    self.count = count
  }
}

/// A node in the hash tree, logically representing a hash table with
/// 32 buckets, corresponding to a 5-bit slice of a full hash value.
///
/// Each bucket may store either a single key-value pair or a reference
/// to a child node that contains additional items.
///
/// To save space, children and items are stored compressed into the two
/// ends of a single raw storage buffer, with the free space in between
/// available for use by either side.
///
/// The storage is arranged as shown below.
///
///     ┌───┬───┬───┬───┬───┬──────────────────┬───┬───┬───┬───┐
///     │ 0 │ 1 │ 2 │ 3 │ 4 │→   free space   ←│ 0 │ 1 │ 2 │ 3 │
///     └───┴───┴───┴───┴───┴──────────────────┴───┴───┴───┴───┘
///      children                                         items
///
/// Two 32-bit bitmaps are used to associate each child and item with their
/// position in the hash table. The bucket occupied by the *n*th child in the
/// buffer above is identified by position of the *n*th true bit in the child
/// map, and the *n*th item's bucket corresponds to the *n*th true bit in the
/// items map.
@usableFromInline
@frozen
internal struct _Node<Key: Hashable, Value> {
  @usableFromInline
  internal typealias Element = (key: Key, value: Value)

  @usableFromInline
  internal var storage: _RawStorage

  @usableFromInline
  internal var count: Int

  @inlinable
  internal init(_storage: _RawStorage, count: Int) {
    self.storage = _storage
    self.count = count
  }
}

extension _Node {
  @inlinable @inline(__always)
  internal func read<R>(_ body: (UnsafeHandle) -> R) -> R {
    UnsafeHandle.read(storage, body)
  }

  @inlinable @inline(__always)
  internal mutating func update<R>(_ body: (UnsafeHandle) -> R) -> R {
    UnsafeHandle.update(storage, body)
  }
}

// MARK: Shortcuts to reading header data

extension _Node {
  @inlinable
  internal var isCollisionNode: Bool {
    read { $0.isCollisionNode }
  }

  @inlinable
  internal var hasSingletonItem: Bool {
    read { $0.hasSingletonItem }
  }

  @inlinable
  internal var hasSingletonChild: Bool {
    read { $0.hasSingletonChild }
  }

  @inlinable
  internal var isAtrophied: Bool {
    read { $0.isAtrophiedNode }
  }
}
