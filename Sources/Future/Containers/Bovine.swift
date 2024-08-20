//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Builtin // For Bovine.isIdentical

/// A utility adapter that wraps a noncopyable storage type in a copy-on-write
/// struct, enabling efficient implementation of value semantics. The type
/// allows safe borrowing and mutating access to its storage, with minimal fuss.
///
/// Like `ManagedBufferPointer`, this type is intended to be used within the
/// internal implementation of public types. Instances of it aren't designed
/// to be exposed as public.
///
/// (The placeholder name `Bovine` is hinting at the common abbreviation of the
/// copy-on-write optimization.)
@frozen
public struct Bovine<Storage: ~Copyable> {
  @usableFromInline
  internal var _box: _Box

  @inlinable
  public init(_ storage: consuming Storage) {
    self._box = _Box(storage)
  }
}

extension Bovine: @unchecked Sendable where Storage: Sendable & ~Copyable {}

#if true // FIXME: Silent error on class definition nested in noncopyable struct
@usableFromInline
internal final class _BovineBox<Storage: ~Copyable> {
  @exclusivity(unchecked)
  @usableFromInline
  internal var storage: Storage

  @inlinable
  internal init(_ storage: consuming Storage) {
    self.storage = storage
  }
}

extension Bovine where Storage: ~Copyable {
  @usableFromInline
  internal typealias _Box = _BovineBox<Storage>
}
#else
extension Bovine where Storage: ~Copyable {
  @usableFromInline
  internal final class _Box {
    @exclusivity(unchecked)
    @usableFromInline
    internal var storage: Storage

    @inlinable
    internal init(_ storage: consuming Storage) {
      self.storage = storage
    }
  }
}
#endif

extension Bovine where Storage: ~Copyable {
  @inlinable
  @inline(__always)
  public mutating func isUnique() -> Bool {
    isKnownUniquelyReferenced(&_box)
  }

  @inlinable
  public mutating func ensureUnique(
    cloner: (borrowing Storage) -> Storage
  ) {
    if isUnique() { return }
    _box = _Box(cloner(_box.storage))
  }
}

extension Bovine where Storage: ~Copyable {
  @inlinable
  @inline(__always)
  public var value: Storage {
    _read {
      yield _box.storage
    }
    _modify {
      precondition(isUnique())
      yield &_box.storage
    }
  }

  @inlinable
  @inline(__always)
  public func read<E: Error, R: ~Copyable>(
    _ body: (borrowing Storage) throws(E) -> R
  ) throws(E) -> R {
    try body(_box.storage)
  }

  @inlinable
  @inline(__always)
  public mutating func update<E: Error, R: ~Copyable>(
    _ body: (inout Storage) throws(E) -> R
  ) throws(E) -> R {
    precondition(isUnique())
    return try body(&_box.storage)
  }
}

extension Bovine where Storage: ~Copyable {
  @inlinable
  public func isIdentical(to other: Self) -> Bool {
    if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
      return self._box === other._box
    } else {
      let a = Builtin.bridgeToRawPointer(self._box)
      let b = Builtin.bridgeToRawPointer(other._box)
      return Bool(Builtin.cmp_eq_RawPointer(a, b))
    }
  }
}
