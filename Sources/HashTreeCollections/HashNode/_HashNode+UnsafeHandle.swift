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

extension _HashNode {
  /// An unsafe view of the data stored inside a node in the hash tree, hiding
  /// the mechanics of accessing storage from the code that uses it.
  ///
  /// Handles do not own the storage they access -- it is the client's
  /// responsibility to ensure that handles (and any pointer values generated
  /// by them) do not escape the closure call that received them.
  ///
  /// A handle can be either read-only or mutable, depending on the method used
  /// to access it. In debug builds, methods that modify data trap at runtime if
  /// they're called on a read-only view.
  @usableFromInline
  @frozen
  @unsafe
  internal struct UnsafeHandle {
    @usableFromInline
    internal typealias Element = (key: Key, value: Value)

    @usableFromInline
    internal let _header: UnsafeMutablePointer<_HashNodeHeader>

    @usableFromInline
    internal let _memory: UnsafeMutableRawPointer

    #if DEBUG
    @usableFromInline
    @safe
    internal let _isMutable: Bool
    #endif

    @inlinable
    internal init(
      _ header: UnsafeMutablePointer<_HashNodeHeader>,
      _ memory: UnsafeMutableRawPointer,
      isMutable: Bool
    ) {
      unsafe self._header = header
      unsafe self._memory = memory
      #if DEBUG
      self._isMutable = isMutable
      #endif
    }
  }
}

extension _HashNode.UnsafeHandle {
  @inlinable
  @inline(__always)
  @safe
  func assertMutable() {
#if DEBUG
    assert(_isMutable)
#endif
  }
}

extension _HashNode.UnsafeHandle {
  @inlinable @inline(__always)
  static func read<R>(
    _ node: _UnmanagedHashNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    unsafe try node.ref._withUnsafeGuaranteedRef { storage in
      unsafe try storage.withUnsafeMutablePointers { header, elements in
        unsafe try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
      }
    }
  }

  @inlinable @inline(__always)
  static func read<R>(
    _ storage: _RawHashStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    unsafe try storage.withUnsafeMutablePointers { header, elements in
      unsafe try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
    }
  }

  @inlinable @inline(__always)
  static func update<R>(
    _ node: _UnmanagedHashNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    unsafe try node.ref._withUnsafeGuaranteedRef { storage in
      unsafe try storage.withUnsafeMutablePointers { header, elements in
        unsafe try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: true))
      }
    }
  }

  @inlinable @inline(__always)
  static func update<R>(
    _ storage: _RawHashStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    unsafe try storage.withUnsafeMutablePointers { header, elements in
      unsafe try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: true))
    }
  }
}

extension _HashNode.UnsafeHandle {
  @inlinable @inline(__always)
  internal var itemMap: _Bitmap {
    get {
      unsafe _header.pointee.itemMap
    }
    nonmutating set {
      assertMutable()
      unsafe _header.pointee.itemMap = newValue
    }
  }

  @inlinable @inline(__always)
  internal var childMap: _Bitmap {
    get {
      unsafe _header.pointee.childMap
    }
    nonmutating set {
      assertMutable()
      unsafe _header.pointee.childMap = newValue
    }
  }

  @inlinable @inline(__always)
  internal var byteCapacity: Int {
    unsafe _header.pointee.byteCapacity
  }

  @inlinable @inline(__always)
  internal var bytesFree: Int {
    get {
      unsafe _header.pointee.bytesFree
    }
    nonmutating set {
      assertMutable()
      unsafe _header.pointee.bytesFree = newValue
    }
  }

  @inlinable @inline(__always)
  internal var isCollisionNode: Bool {
    unsafe _header.pointee.isCollisionNode
  }

  @inlinable @inline(__always)
  internal var collisionCount: Int {
    get {
      unsafe _header.pointee.collisionCount
    }
    nonmutating set {
      assertMutable()
      unsafe _header.pointee.collisionCount = newValue
    }
  }

  @inlinable @inline(__always)
  internal var collisionHash: _Hash {
    get {
      assert(unsafe isCollisionNode)
      return unsafe _memory.load(as: _Hash.self)
    }
    nonmutating set {
      assertMutable()
      assert(unsafe isCollisionNode)
      unsafe _memory.storeBytes(of: newValue, as: _Hash.self)
    }
  }

  @inlinable @inline(__always)
  internal var _childrenStart: UnsafeMutablePointer<_HashNode> {
    unsafe _memory.assumingMemoryBound(to: _HashNode.self)
  }

  @inlinable @inline(__always)
  internal var hasChildren: Bool {
    unsafe _header.pointee.hasChildren
  }

  @inlinable @inline(__always)
  internal var childCount: Int {
    unsafe _header.pointee.childCount
  }

  @inlinable
  internal func childBucket(at slot: _HashSlot) -> _Bucket {
    guard unsafe !isCollisionNode else { return .invalid }
    return unsafe childMap.bucket(at: slot)
  }

  @inlinable @inline(__always)
  internal var childrenEndSlot: _HashSlot {
    unsafe _header.pointee.childrenEndSlot
  }

  @inlinable
  internal var children: UnsafeMutableBufferPointer<_HashNode> {
    unsafe UnsafeMutableBufferPointer(start: _childrenStart, count: childCount)
  }

  @inlinable
  internal func childPtr(at slot: _HashSlot) -> UnsafeMutablePointer<_HashNode> {
    assert(unsafe slot.value < childCount)
    return unsafe _childrenStart + slot.value
  }

  @inlinable
  internal subscript(child slot: _HashSlot) -> _HashNode {
    unsafeAddress {
      unsafe UnsafePointer(childPtr(at: slot))
    }
    nonmutating unsafeMutableAddress {
      assertMutable()
      return unsafe childPtr(at: slot)
    }
  }

  @inlinable
  internal var _itemsEnd: UnsafeMutablePointer<Element> {
    unsafe (_memory + _header.pointee.byteCapacity)
      .assumingMemoryBound(to: Element.self)
  }

  @inlinable @inline(__always)
  internal var hasItems: Bool {
    unsafe _header.pointee.hasItems
  }

  @inlinable @inline(__always)
  internal var itemCount: Int {
    unsafe _header.pointee.itemCount
  }

  @inlinable
  internal func itemBucket(at slot: _HashSlot) -> _Bucket {
    guard unsafe !isCollisionNode else { return .invalid }
    return unsafe itemMap.bucket(at: slot)
  }

  @inlinable @inline(__always)
  internal var itemsEndSlot: _HashSlot {
    unsafe _header.pointee.itemsEndSlot
  }

  @inlinable
  internal var reverseItems: UnsafeMutableBufferPointer<Element> {
    let c = unsafe itemCount
    return unsafe UnsafeMutableBufferPointer(start: _itemsEnd - c, count: c)
  }

  @inlinable
  internal func itemPtr(at slot: _HashSlot) -> UnsafeMutablePointer<Element> {
    assert(unsafe slot.value <= itemCount)
    return unsafe _itemsEnd.advanced(by: -1 &- slot.value)
  }

  @inlinable
  internal subscript(item slot: _HashSlot) -> Element {
    unsafeAddress {
      unsafe UnsafePointer(itemPtr(at: slot))
    }
    nonmutating unsafeMutableAddress {
      assertMutable()
      return unsafe itemPtr(at: slot)
    }
  }

  @inlinable
  internal func clear() {
    assertMutable()
    unsafe _header.pointee.clear()
  }
}

extension _HashNode.UnsafeHandle {
  @inlinable
  internal var hasSingletonItem: Bool {
    unsafe _header.pointee.hasSingletonItem
  }

  @inlinable
  internal var hasSingletonChild: Bool {
    unsafe _header.pointee.hasSingletonChild
  }

  @inlinable
  internal var isAtrophiedNode: Bool {
    unsafe hasSingletonChild && self[child: .zero].isCollisionNode
  }
}
