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

import Builtin // For Shared.isIdentical

/// A utility adapter that wraps a noncopyable storage type in a copy-on-write
/// struct, enabling efficient implementation of value semantics. The type
/// allows safe borrowing and mutating access to its storage, with minimal fuss.
///
/// Like `ManagedBufferPointer`, this type is intended to be used within the
/// internal implementation of public types. Instances of it aren't designed
/// to be exposed as public.
@frozen
public struct Shared<Storage: ~Copyable> {
  @usableFromInline
  internal var _box: _Box

  @inlinable
  public init(_ storage: consuming Storage) {
    self._box = _Box(storage)
  }
}

extension Shared: @unchecked Sendable where Storage: Sendable & ~Copyable {}

#if true // FIXME: Silent error on class definition nested in noncopyable struct
@usableFromInline
internal final class _SharedBox<Storage: ~Copyable> {
  @exclusivity(unchecked)
  @usableFromInline
  internal var storage: Storage

  @inlinable
  internal init(_ storage: consuming Storage) {
    self.storage = storage
  }
}

extension Shared where Storage: ~Copyable {
  @usableFromInline
  internal typealias _Box = _SharedBox<Storage>
}
#else
extension Shared where Storage: ~Copyable {
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

extension Shared where Storage: ~Copyable {
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

import struct SwiftShims.HeapObject

extension Shared where Storage: ~Copyable {
  // FIXME: Can we avoid hacks like this? If not, perhaps `_Box.storage` should be tail-allocated.
  @inlinable
  internal var _address: UnsafePointer<Storage> {
    // Adapted from _getUnsafePointerToStoredProperties
    let p = (
      UnsafeRawPointer(Builtin.bridgeToRawPointer(_box))
      + MemoryLayout<HeapObject>.size)
    return p.alignedUp(for: Storage.self).assumingMemoryBound(to: Storage.self)
  }

  @inlinable
  internal var _mutableAddress: UnsafeMutablePointer<Storage> {
    // Adapted from _getUnsafePointerToStoredProperties
    let p = (
      UnsafeMutableRawPointer(Builtin.bridgeToRawPointer(_box))
      + MemoryLayout<HeapObject>.size)
    return p.alignedUp(for: Storage.self).assumingMemoryBound(to: Storage.self)
  }
}

extension Shared where Storage: ~Copyable {
  @inlinable
  @inline(__always)
  public var value: /*FIXME: dependsOn(self)*/ Storage {
    // FIXME: This implements the wrong shape.
    // FIXME: Semantically it yields a borrow scoped to an access of this `value` variable,
    // FIXME: not the much wider borrow of `self`, which we'd actually want.
    _read {
      yield _box.storage
    }
    _modify {
      precondition(isUnique())
      yield &_box.storage
    }
  }

  // FIXME: This builds, but attempts to use it don't: they fail with an unexpected exclusivity violation.
  @inlinable
  @lifetime(self)
  public subscript() -> Storage {
    //@_transparent
    unsafeAddress {
      _address
    }

    //@_transparent
    unsafeMutableAddress {
      precondition(isUnique())
      return _mutableAddress
    }
  }

  @inlinable
  @inline(__always)
  public func read<E: Error, R: ~Copyable>(
    _ body: (borrowing Storage) throws(E) -> R
  ) throws(E) -> R {
    // FIXME: This also implements the wrong shape.
    // FIXME: The borrow of `Storage` isn't tied to `self` at all, and
    // FIXME: it obviously cannot legally escape the `read` call.
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

#if false // FIXME: Use it or lose it
extension Shared where Storage: ~Copyable {
  // This is the actual shape we want. There is currently no way to express it.
  @inlinable
  @lifetime(borrow self)
  public borrowing func read() -> Borrow<Storage> {
    // This is gloriously (and very explicitly) unsafe, as it should be.
    // `Shared` is carefully constructed to guarantee that
    // lifetime(self) == lifetime(_box.storage); but we have not
    // (cannot) explain this to the compiler.
    Borrow(unsafeAddress: _address, owner: self)
  }
}
#endif

extension Shared where Storage: ~Copyable {
  @inlinable
  public func isIdentical(to other: Self) -> Bool {
    if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
      return self._box === other._box
    } else {
      // To call the standard `===`, we need to do `_SharedBox` -> AnyObject conversions
      // that are only supported in the Swift 6+ runtime.
      let a = Builtin.bridgeToRawPointer(self._box)
      let b = Builtin.bridgeToRawPointer(other._box)
      return Bool(Builtin.cmp_eq_RawPointer(a, b))
    }
  }
}

