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

/// A base representation of a hash tree node, capturing functionality
/// independent of the `Key` and `Value` types.
@usableFromInline
internal typealias _RawStorage = ManagedBuffer<_StorageHeader, _RawNode>

/// Type-punned storage for the singleton root node used in empty hash trees
/// (of all `Key` and `Value` types).
///
/// `_Node` is carefully defined to use a `_RawStorage` reference as its
/// storage variable, so that this can work. (The only reason we need the
/// `_Node.Storage` subclass is to allow storage instances to properly clean up
/// after themselves in their `deinit` method.)
@usableFromInline
internal let _emptySingleton: _RawStorage = _RawStorage.create(
  minimumCapacity: 0,
  makingHeaderWith: { _ in _StorageHeader(byteCapacity: 0) })

extension _Node {
  /// Instances of this class hold (tail-allocated) storage for individual
  /// nodes in a hash tree.
  @usableFromInline
  internal final class Storage: _RawStorage {
    @usableFromInline
    internal typealias Element = (key: Key, value: Value)

    @usableFromInline
    internal typealias UnsafeHandle = _Node<Key, Value>.UnsafeHandle

    deinit {
      UnsafeHandle.update(self) { handle in
        handle._children.deinitialize()
        handle.reverseItems.deinitialize()
      }
    }
  }
}

extension _Node.Storage {
  @inlinable
  internal static func allocate(byteCapacity: Int) -> _Node.Storage {
    assert(byteCapacity >= 0)

    let itemStride = MemoryLayout<Element>.stride
    let childStride = MemoryLayout<_Node>.stride
    let unit = Swift.max(itemStride, childStride)

    // Round up request to nearest power-of-two number of units.
    // We'll allow allocations of space that fits 0, 1, 2, 4, 8, 16 or 32
    // units.
    var bytes = unit * ((byteCapacity &+ unit &- 1) / unit)._roundUpToPowerOfTwo()

    let itemAlignment = MemoryLayout<Element>.alignment
    let childAlignment = MemoryLayout<_Node>.alignment
    if itemAlignment > childAlignment {
      // Make sure we always have enough room to properly align trailing items.
      bytes += itemAlignment - childAlignment
    }

    let object = _Node.Storage.create(
      minimumCapacity: (bytes &+ childStride &- 1) / childStride
    ) { buffer in
      _StorageHeader(byteCapacity: buffer.capacity * childStride)
    }

    object.withUnsafeMutablePointers { header, elements in
      let start = UnsafeRawPointer(elements)
      let end = start
        .advanced(by: Int(header.pointee.byteCapacity))
        .alignedDown(for: Element.self)
      header.pointee._byteCapacity = UInt32(start.distance(to: end))
      header.pointee._bytesFree = header.pointee._byteCapacity
      assert(byteCapacity <= header.pointee.byteCapacity)
    }
    return unsafeDowncast(object, to: _Node.Storage.self)
  }

  @inlinable @inline(__always)
  internal static func allocate(
    itemCapacity: Int = 0, childCapacity: Int = 0
  ) -> _Node.Storage {
    assert(itemCapacity >= 0 && childCapacity >= 0)
    let itemBytes = itemCapacity * MemoryLayout<Element>.stride
    let childBytes = childCapacity * MemoryLayout<_Node>.stride
    return allocate(byteCapacity: itemBytes &+ childBytes)
  }
}

extension _Node {
  @inlinable @inline(__always)
  internal static var spaceForNewItem: Int {
    MemoryLayout<Element>.stride
  }

  @inlinable @inline(__always)
  internal static var spaceForNewChild: Int {
    MemoryLayout<_Node>.stride
  }

  @inlinable @inline(__always)
  internal static var spaceForNewCollision: Int {
    Swift.max(0, MemoryLayout<_Node>.stride - MemoryLayout<Element>.stride)
  }

  @inlinable @inline(__always)
  internal static var spaceForInlinedChild: Int {
    Swift.max(0, MemoryLayout<Element>.stride - MemoryLayout<_Node>.stride)
  }

  @inlinable
  internal mutating func isUnique() -> Bool {
    isKnownUniquelyReferenced(&self.raw.storage)
  }

  @inlinable
  internal mutating func hasFreeSpace(_ bytes: Int) -> Bool {
    bytes <= self.raw.storage.header.bytesFree
  }

  @inlinable
  internal mutating func ensureUnique(isUnique: Bool) {
    if !isUnique {
      self = copy()
    }
  }

  @inlinable
  internal mutating func ensureUnique(
    isUnique: Bool,
    withFreeSpace minimumFreeBytes: Int = 0
  ) {
    if !isUnique {
      self = copy(withFreeSpace: minimumFreeBytes)
    } else if !hasFreeSpace(minimumFreeBytes) {
      move(withFreeSpace: minimumFreeBytes)
    }
  }


  @inlinable
  internal static func allocate<R>(
    itemMap: _Bitmap, childMap: _Bitmap,
    count: Int,
    initializingWith initializer: (
      UnsafeMutableBufferPointer<_Node>, UnsafeMutableBufferPointer<Element>
    ) -> R
  ) -> (node: _Node, result: R) {
    let (itemCount, childCount) = _StorageHeader.counts(
      itemMap: itemMap, childMap: childMap)
    let storage = Storage.allocate(
      itemCapacity: itemCount, childCapacity: childCount)
    var node = _Node(storage: storage, count: count)
    let result = node.update {
      let (children, items) = $0._prepare(
        itemMap: itemMap,
        itemCount: itemCount,
        childMap: childMap,
        childCount: childCount
      )
      return initializer(children, items)
    }
    return (node, result)
  }

  @inlinable @inline(never)
  internal func copy(withFreeSpace space: Int = 0) -> _Node {
    assert(space >= 0)
    let capacity = read { $0.byteCapacity &- $0.bytesFree &+ space }
    var new = Self(
      storage: Storage.allocate(byteCapacity: capacity),
      count: count)
    read { src in
      new.update { dst in
        let (dstChildren, dstItems) = dst._prepare(
          itemMap: src.itemMap, childMap: src.childMap)

        dstChildren.initializeAll(fromContentsOf: src._children)
        dstItems.initializeAll(fromContentsOf: src.reverseItems)
      }
    }
    new._invariantCheck()
    return new
  }

  @inlinable @inline(never)
  internal mutating func move(withFreeSpace space: Int = 0) {
    assert(space >= 0)
    let capacity = read { $0.byteCapacity &- $0.bytesFree &+ space }
    var new = Self(
      storage: Storage.allocate(byteCapacity: capacity),
      count: self.count)
    self.update { src in
      new.update { dst in
        let (dstChildren, dstItems) = dst._prepare(
          itemMap: src.itemMap, childMap: src.childMap)

        dstChildren.moveInitializeAll(fromContentsOf: src._children)
        dstItems.moveInitializeAll(fromContentsOf: src.reverseItems)

        src.clear()
        assert(dst.bytesFree >= space)
      }
    }
    self.count = 0
    self._invariantCheck()
    new._invariantCheck()
    self = new
  }
}

extension _Node.UnsafeHandle {
  @inlinable
  internal func _prepare(
    itemMap: _Bitmap, childMap: _Bitmap
  ) -> (
    children: UnsafeMutableBufferPointer<_Node>,
    items: UnsafeMutableBufferPointer<Element>
  ) {
    let (itemCount, childCount) = _StorageHeader.counts(
      itemMap: itemMap, childMap: childMap)
    return self._prepare(
      itemMap: itemMap,
      itemCount: itemCount,
      childMap: childMap,
      childCount: childCount)
  }

  @inlinable
  internal func _prepare(
    itemMap: _Bitmap,
    itemCount: Int,
    childMap: _Bitmap,
    childCount: Int
  ) -> (
    children: UnsafeMutableBufferPointer<_Node>,
    items: UnsafeMutableBufferPointer<Element>
  ) {
    assert(self.itemMap.isEmpty && self.childMap.isEmpty)
    assert(self.byteCapacity == self.bytesFree)

    assert(
      itemMap == childMap
      || (itemMap.count == itemCount && childMap.count == childCount))

    assert(
      itemMap != childMap
      || (itemCount == itemMap._value && childCount == 0))

    self.itemMap = itemMap
    self.childMap = childMap

    let itemStride = MemoryLayout<Element>.stride
    let childStride = MemoryLayout<_Node>.stride

    let itemBytes = itemCount &* itemStride
    let childBytes = childCount &* childStride
    let occupiedBytes = itemBytes &+ childBytes
    assert(occupiedBytes <= byteCapacity)
    bytesFree = byteCapacity &- occupiedBytes

    let childStart = self._memory
      .bindMemory(to: _Node.self, capacity: childCount)
    let itemStart = (self._memory + (byteCapacity - itemBytes))
      .bindMemory(to: Element.self, capacity: itemCount)
    return (
      .init(start: childStart, count: childCount),
      .init(start: itemStart, count: itemCount))
  }
}

