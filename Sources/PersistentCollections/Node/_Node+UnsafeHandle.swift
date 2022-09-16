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

extension _Node {
  @usableFromInline
  @frozen
  internal struct UnsafeHandle {
    @usableFromInline
    internal typealias Element = (key: Key, value: Value)

    @usableFromInline
    internal let _header: UnsafeMutablePointer<_StorageHeader>

    @usableFromInline
    internal let _memory: UnsafeMutableRawPointer

    #if DEBUG
    @usableFromInline
    internal let _isMutable: Bool
    #endif

    @inlinable
    internal init(
      _ header: UnsafeMutablePointer<_StorageHeader>,
      _ memory: UnsafeMutableRawPointer,
      isMutable: Bool
    ) {
      self._header = header
      self._memory = memory
      #if DEBUG
      self._isMutable = isMutable
      #endif
    }
  }
}

extension _Node.UnsafeHandle {
  @inlinable
  @inline(__always)
  func assertMutable() {
#if DEBUG
    assert(_isMutable)
#endif
  }
}

extension _Node.UnsafeHandle {
  @inlinable @inline(__always)
  static func read<R>(
    _ node: _UnmanagedNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try node.ref._withUnsafeGuaranteedRef { storage in
      try storage.withUnsafeMutablePointers { header, elements in
        try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
      }
    }
  }

  @inlinable @inline(__always)
  static func read<R>(
    _ storage: _RawStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try storage.withUnsafeMutablePointers { header, elements in
      try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
    }
  }

  @inlinable @inline(__always)
  static func update<R>(
    _ storage: _RawStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try storage.withUnsafeMutablePointers { header, elements in
      try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: true))
    }
  }
}

extension _Node.UnsafeHandle {
  @inlinable @inline(__always)
  internal var itemMap: _Bitmap {
    get {
      _header.pointee.itemMap
    }
    nonmutating set {
      assertMutable()
      _header.pointee.itemMap = newValue
    }
  }

  @inlinable @inline(__always)
  internal var childMap: _Bitmap {
    get {
      _header.pointee.childMap
    }
    nonmutating set {
      assertMutable()
      _header.pointee.childMap = newValue
    }
  }

  @inlinable @inline(__always)
  internal var byteCapacity: Int {
    _header.pointee.byteCapacity
  }

  @inlinable @inline(__always)
  internal var bytesFree: Int {
    get { _header.pointee.bytesFree }
    nonmutating set {
      assertMutable()
      _header.pointee.bytesFree = newValue
    }
  }

  @inlinable @inline(__always)
  internal var isCollisionNode: Bool {
    _header.pointee.isCollisionNode
  }

  @inlinable @inline(__always)
  internal var collisionCount: Int {
    get { _header.pointee.collisionCount }
    nonmutating set { _header.pointee.collisionCount = newValue }
  }

  @inlinable @inline(__always)
  internal var _childrenStart: UnsafeMutablePointer<_Node> {
    _memory.assumingMemoryBound(to: _Node.self)
  }

  @inlinable @inline(__always)
  internal var hasChildren: Bool {
    _header.pointee.hasChildren
  }

  @inlinable @inline(__always)
  internal var childCount: Int {
    _header.pointee.childCount
  }

  @inlinable
  internal var _children: UnsafeMutableBufferPointer<_Node> {
    UnsafeMutableBufferPointer(start: _childrenStart, count: childCount)
  }

  @inlinable
  internal func childPtr(at offset: Int) -> UnsafeMutablePointer<_Node> {
    assert(offset >= 0 && offset < childCount)
    return _childrenStart + offset
  }

  @inlinable
  internal subscript(child offset: Int) -> _Node {
    unsafeAddress { UnsafePointer(childPtr(at: offset)) }
    nonmutating unsafeMutableAddress { childPtr(at: offset) }
  }

  @inlinable
  internal var _itemsEnd: UnsafeMutablePointer<Element> {
    (_memory + _header.pointee.byteCapacity)
      .assumingMemoryBound(to: Element.self)
  }

  @inlinable @inline(__always)
  internal var hasItems: Bool {
    _header.pointee.hasItems
  }

  @inlinable @inline(__always)
  internal var itemCount: Int {
    _header.pointee.itemCount
  }

  @inlinable
  internal var reverseItems: UnsafeMutableBufferPointer<Element> {
    let c = itemCount
    return UnsafeMutableBufferPointer(start: _itemsEnd - c, count: c)
  }

  @inlinable
  internal func itemPtr(at offset: Int) -> UnsafeMutablePointer<Element> {
    assert(offset >= 0 && offset < itemCount)
    return _itemsEnd.advanced(by: -1 &- offset)
  }

  @inlinable
  internal subscript(item offset: Int) -> Element {
    unsafeAddress { UnsafePointer(itemPtr(at: offset)) }
    unsafeMutableAddress { itemPtr(at: offset) }
  }
}

extension _Node.UnsafeHandle {
  @inlinable
  internal var hasSingletonItem: Bool {
    itemCount == 1 && childCount == 0
  }

  @inlinable
  internal var hasSingletonChild: Bool {
    itemMap.isEmpty && childCount == 1
  }

  @inlinable
  internal var isAtrophiedNode: Bool {
    hasSingletonChild && self[child: 0].isCollisionNode
  }
}
