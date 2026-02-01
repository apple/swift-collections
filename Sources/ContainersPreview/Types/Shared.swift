//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if false // TODO
import Builtin // For Shared.isIdentical

/// A utility adapter that wraps a noncopyable storage type in a copy-on-write
/// struct, enabling efficient implementation of value semantics. The type
/// allows safe borrowing and mutating access to its storage, with minimal fuss.
///
/// Like `ManagedBufferPointer`, this type is intended to be used within the
/// internal implementation of public types. Instances of it aren't designed
/// to be exposed as public.
@safe
@frozen
public struct Shared<Storage: ~Copyable> {
  @usableFromInline
  internal var _box: _Box

  @inlinable
  public init(_ storage: consuming Storage) {
    unsafe self._box = _Box(storage)
  }
}

extension Shared: @unchecked Sendable where Storage: Sendable & ~Copyable {}

extension Shared where Storage: ~Copyable {
  @unsafe
  @usableFromInline
  internal final class _Box {
    @exclusivity(unchecked)
    @usableFromInline
    internal var storage: Storage

    @inlinable
    internal init(_ storage: consuming Storage) {
      unsafe self.storage = storage
    }
  }
}

extension Shared where Storage: ~Copyable {
  @inlinable
  @inline(__always)
  public mutating func isUnique() -> Bool {
    unsafe isKnownUniquelyReferenced(&_box)
  }

  /// - Returns true if this instance was already uniquely referenced.
  @discardableResult
  @inlinable
  public mutating func ensureUnique(
    cloner: (borrowing Storage) -> Storage
  ) -> Bool {
    if isUnique() { return true }
    replace(using: cloner)
    return false
  }

  @inlinable
  public mutating func replace(
    using body: (borrowing Storage) -> Storage
  ) {
    unsafe _box = _Box(body(_box.storage))
  }

  @inlinable
  public mutating func edit(
    shared cloner: (borrowing Storage) -> Storage,
    unique updater: (inout Storage) -> Void
  ) {
    if isUnique() {
      unsafe updater(&_box.storage)
    } else {
      unsafe _box = _Box(cloner(_box.storage))
    }
  }
}

import struct SwiftShims.HeapObject

extension Shared where Storage: ~Copyable {
  // FIXME: Can we avoid hacks like this? If not, perhaps `_Box.storage` should be tail-allocated.
  @inlinable
  internal var _address: UnsafePointer<Storage> {
    // Adapted from _getUnsafePointerToStoredProperties
    let p = unsafe (
      UnsafeRawPointer(Builtin.bridgeToRawPointer(_box))
      + MemoryLayout<HeapObject>.size)
    return unsafe p.alignedUp(for: Storage.self).assumingMemoryBound(to: Storage.self)
  }

  @inlinable
  internal var _mutableAddress: UnsafeMutablePointer<Storage> {
    // Adapted from _getUnsafePointerToStoredProperties
    let p = unsafe (
      UnsafeMutableRawPointer(Builtin.bridgeToRawPointer(_box))
      + MemoryLayout<HeapObject>.size)
    return unsafe p.alignedUp(for: Storage.self).assumingMemoryBound(to: Storage.self)
  }
}

extension Shared where Storage: ~Copyable {
  @inlinable
  @inline(__always)
  public var value: Storage {
    unsafeAddress {
      unsafe _address
    }
    unsafeMutableAddress {
      precondition(isUnique())
      return unsafe _mutableAddress
    }
  }
}

extension Shared where Storage: ~Copyable {
  @inlinable
  @_lifetime(borrow self)
  public borrowing func borrow() -> Ref<Storage> {
    // This is gloriously (and very explicitly) unsafe, as it should be.
    // `Shared` is carefully constructed to guarantee that
    // lifetime(self) == lifetime(_box.storage).
    unsafe Ref(unsafeAddress: _address, borrowing: self)
  }


  @inlinable
  @_lifetime(&self)
  public mutating func mutate() -> Mut<Storage> {
    // This is gloriously (and very explicitly) unsafe, as it should be.
    // `Shared` is carefully constructed to guarantee that
    // lifetime(self) == lifetime(_box.storage).
    unsafe Mut(unsafeAddress: _mutableAddress, mutating: &self)
  }
}

extension Shared where Storage: ~Copyable {
  @inlinable
  public func isIdentical(to other: Self) -> Bool {
    if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
      return unsafe self._box === other._box
    } else {
      // To call the standard `===`, we need to do `_SharedBox` -> AnyObject conversions
      // that are only supported in the Swift 6+ runtime.
      let a = unsafe Builtin.bridgeToRawPointer(self._box)
      let b = unsafe Builtin.bridgeToRawPointer(other._box)
      return Bool(Builtin.cmp_eq_RawPointer(a, b))
    }
  }
}
#endif
#endif
