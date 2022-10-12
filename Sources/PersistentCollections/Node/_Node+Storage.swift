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
        handle.children.deinitialize()
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
    var capacityInUnits = (byteCapacity &+ unit &- 1) / unit
#if false // Enable to set a larger minimum node size
    if capacityInUnits != 0 {
      capacityInUnits = Swift.max(capacityInUnits, 4)
    }
#endif
    var bytes = unit * capacityInUnits._roundUpToPowerOfTwo()

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
  internal static var spaceForSpawningChild: Int {
    Swift.max(0, spaceForNewChild - spaceForNewItem)
  }

  @inlinable @inline(__always)
  internal static var spaceForInlinedChild: Int {
    Swift.max(0, spaceForNewItem - spaceForNewChild)
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
    extraBytes: Int = 0,
    initializingWith initializer: (
      UnsafeMutableBufferPointer<_Node>, UnsafeMutableBufferPointer<Element>
    ) -> R
  ) -> (node: _Node, result: R) {
    assert(extraBytes >= 0)
    assert(itemMap.isDisjoint(with: childMap)) // No collisions
    let itemCount = itemMap.count
    let childCount = childMap.count

    let itemStride = MemoryLayout<Element>.stride
    let childStride = MemoryLayout<_Node>.stride

    let itemBytes = itemCount * itemStride
    let childBytes = childCount * childStride
    let occupiedBytes = itemBytes &+ childBytes
    let storage = Storage.allocate(
      byteCapacity: occupiedBytes &+ extraBytes)
    var node = _Node(storage: storage, count: count)
    let result: R = node.update {
      $0.itemMap = itemMap
      $0.childMap = childMap

      assert(occupiedBytes <= $0.bytesFree)
      $0.bytesFree &-= occupiedBytes

      let childStart = $0._memory
        .bindMemory(to: _Node.self, capacity: childCount)
      let itemStart = ($0._memory + ($0.byteCapacity - itemBytes))
        .bindMemory(to: Element.self, capacity: itemCount)

      return initializer(
        UnsafeMutableBufferPointer(start: childStart, count: childCount),
        UnsafeMutableBufferPointer(start: itemStart, count: itemCount))
    }
    return (node, result)
  }

  @inlinable
  internal static func allocateCollision<R>(
    count: Int,
    _ hash: _Hash,
    extraBytes: Int = 0,
    initializingWith initializer: (UnsafeMutableBufferPointer<Element>) -> R
  ) -> (node: _Node, result: R) {
    assert(count >= 2)
    assert(extraBytes >= 0)
    let itemBytes = count * MemoryLayout<Element>.stride
    let hashBytes = MemoryLayout<_Hash>.stride
    let bytes = itemBytes &+ hashBytes
    assert(MemoryLayout<_Hash>.alignment <= MemoryLayout<_RawNode>.alignment)
    let storage = Storage.allocate(byteCapacity: bytes &+ extraBytes)
    var node = _Node(storage: storage, count: count)
    let result: R = node.update {
      $0.itemMap = _Bitmap(bitPattern: count)
      $0.childMap = $0.itemMap
      assert(bytes <= $0.bytesFree)
      $0.bytesFree &-= bytes

      $0._memory.storeBytes(of: hash, as: _Hash.self)

      let itemStart = ($0._memory + ($0.byteCapacity &- itemBytes))
        .bindMemory(to: Element.self, capacity: count)

      let items = UnsafeMutableBufferPointer(start: itemStart, count: count)
      return initializer(items)
    }
    return (node, result)
  }


  @inlinable @inline(never)
  internal func copy(withFreeSpace space: Int = 0) -> _Node {
    assert(space >= 0)

    if isCollisionNode {
      return read { src in
        Self.allocateCollision(
          count: self.count, self.collisionHash
        ) { dstItems in
          dstItems.initializeAll(fromContentsOf: src.reverseItems)
        }.node
      }
    }
    return read { src in
      Self.allocate(
        itemMap: src.itemMap,
        childMap: src.childMap,
        count: self.count,
        extraBytes: space
      ) { dstChildren, dstItems in
        dstChildren.initializeAll(fromContentsOf: src.children)
        dstItems.initializeAll(fromContentsOf: src.reverseItems)
      }.node
    }
  }

  @inlinable @inline(never)
  internal mutating func move(withFreeSpace space: Int = 0) {
    assert(space >= 0)
    let c = self.count
    if isCollisionNode {
      self = update { src in
        Self.allocateCollision(
          count: c, src.collisionHash
        ) { dstItems in
          dstItems.moveInitializeAll(fromContentsOf: src.reverseItems)
          src.clear()
        }.node
      }
      return
    }
    self = update { src in
      Self.allocate(
        itemMap: src.itemMap,
        childMap: src.childMap,
        count: c,
        extraBytes: space
      ) { dstChildren, dstItems in
        dstChildren.moveInitializeAll(fromContentsOf: src.children)
        dstItems.moveInitializeAll(fromContentsOf: src.reverseItems)
        src.clear()
      }.node
    }
  }
}
