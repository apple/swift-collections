//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension _RawHashNode {
  /// An unsafe, non-generic view of the data stored inside a node in the
  /// hash tree, hiding the mechanics of accessing storage from the code that
  /// uses it.
  ///
  /// This is the non-generic equivalent of `_HashNode.UnsafeHandle`, sharing some
  /// of its functionality, but it only provides read-only access to the tree
  /// structure (incl. subtree counts) -- it doesn't provide any ways to mutate
  /// the underlying data or to access user payload.
  ///
  /// Handles do not own the storage they access -- it is the client's
  /// responsibility to ensure that handles (and any pointer values generated
  /// by them) do not escape the closure call that received them.
  @usableFromInline
  @frozen
  @unsafe
  internal struct UnsafeHandle {
    @usableFromInline
    internal let _header: UnsafePointer<_HashNodeHeader>

    @usableFromInline
    internal let _memory: UnsafeRawPointer

    @inlinable
    internal init(
      _ header: UnsafePointer<_HashNodeHeader>,
      _ memory: UnsafeRawPointer
    ) {
      unsafe self._header = header
      unsafe self._memory = memory
    }
  }
}

extension _RawHashNode.UnsafeHandle {
  @inlinable @inline(__always)
  static func read<R>(
    _ node: _UnmanagedHashNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    unsafe try node.ref._withUnsafeGuaranteedRef { storage in
      unsafe try storage.withUnsafeMutablePointers { header, elements in
        unsafe try body(Self(header, UnsafeRawPointer(elements)))
      }
    }
  }
}

extension _RawHashNode.UnsafeHandle {
  @inline(__always)
  internal var isCollisionNode: Bool {
    unsafe _header.pointee.isCollisionNode
  }

  @inline(__always)
  internal var collisionHash: _Hash {
    assert(unsafe isCollisionNode)
    return unsafe _memory.load(as: _Hash.self)
  }

  @inline(__always)
  internal var hasChildren: Bool {
    unsafe _header.pointee.hasChildren
  }

  @inline(__always)
  internal var childCount: Int {
    unsafe _header.pointee.childCount
  }

  @inline(__always)
  internal var childrenEndSlot: _HashSlot {
    unsafe _header.pointee.childrenEndSlot
  }

  @inline(__always)
  internal var hasItems: Bool {
    unsafe _header.pointee.hasItems
  }

  @inline(__always)
  internal var itemCount: Int {
    unsafe _header.pointee.itemCount
  }

  @inline(__always)
  internal var itemsEndSlot: _HashSlot {
    unsafe _header.pointee.itemsEndSlot
  }

  @inline(__always)
  internal var _childrenStart: UnsafePointer<_RawHashNode> {
    unsafe _memory.assumingMemoryBound(to: _RawHashNode.self)
  }

  internal subscript(child slot: _HashSlot) -> _RawHashNode {
    unsafeAddress {
      assert(unsafe slot < childrenEndSlot)
      return unsafe _childrenStart + slot.value
    }
  }

  internal var children: UnsafeBufferPointer<_RawHashNode> {
    unsafe UnsafeBufferPointer(start: _childrenStart, count: childCount)
  }
}
