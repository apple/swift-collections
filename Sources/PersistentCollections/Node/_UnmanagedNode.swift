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

import _CollectionsUtilities

/// An unsafe, unowned, type-erased reference to a hash tree node; essentially
/// just a lightweight wrapper around `Unmanaged<_RawStorage>`.
///
/// Because such a reference may outlive the underlying object, use sites must
/// be extraordinarily careful to never dereference an invalid `_UnmanagedNode`.
/// Doing so results in undefined behavior.
@usableFromInline
@frozen
internal struct _UnmanagedNode {
  @usableFromInline
  internal var ref: Unmanaged<_RawStorage>

  @inlinable @inline(__always)
  internal init(_ storage: _RawStorage) {
    self.ref = .passUnretained(storage)
  }
}

extension _UnmanagedNode: Equatable {
  /// Indicates whether two unmanaged node references are equal.
  ///
  /// This function is safe to call even if one or both of its arguments are
  /// invalid -- however, it may incorrectly return true in this case.
  /// (This can happen when a destroyed node's memory region is later reused for
  /// a newly created node.)
  @inlinable
  internal static func ==(left: Self, right: Self) -> Bool {
    left.ref.toOpaque() == right.ref.toOpaque()
  }
}

extension _UnmanagedNode: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    _addressString(for: ref.toOpaque())
  }
}

extension _UnmanagedNode {
  @inlinable @inline(__always)
  internal func withRaw<R>(_ body: (_RawStorage) -> R) -> R {
    ref._withUnsafeGuaranteedRef(body)
  }

  @inline(__always)
  internal func read<R>(_ body: (_RawNode.UnsafeHandle) -> R) -> R {
    ref._withUnsafeGuaranteedRef { storage in
      storage.withUnsafeMutablePointers { header, elements in
        body(_RawNode.UnsafeHandle(header, UnsafeRawPointer(elements)))
      }
    }
  }

  @inlinable
  internal var hasItems: Bool {
    withRaw { $0.header.hasItems }
  }

  @inlinable
  internal var hasChildren: Bool {
    withRaw { $0.header.hasChildren }
  }

  @inlinable
  internal var itemCount: Int {
    withRaw { $0.header.itemCount }
  }

  @inlinable
  internal var childCount: Int {
    withRaw { $0.header.childCount }
  }

  @inlinable
  internal var itemEnd: _Slot {
    withRaw { _Slot($0.header.itemCount) }
  }

  @inlinable
  internal var childEnd: _Slot {
    withRaw { _Slot($0.header.childCount) }
  }

  @inlinable
  internal func unmanagedChild(at slot: _Slot) -> Self {
    withRaw { raw in
      assert(slot.value < raw.header.childCount)
      return raw.withUnsafeMutablePointerToElements { p in
        Self(p[slot.value].storage)
      }
    }
  }
}

