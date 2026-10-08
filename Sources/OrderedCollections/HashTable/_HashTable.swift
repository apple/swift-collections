//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

@usableFromInline
@frozen
package struct _HashTable {
  @usableFromInline
  package var _storage: Storage

  @inlinable
  @inline(__always)
  package init(_ storage: Storage) {
    _storage = storage
  }
}

extension _HashTable {
  /// A class holding hash table storage for a `OrderedSet` collection.
  /// Values in the hash table are offsets into separate element storage, so
  /// this class doesn't need to be generic over `OrderedSet`'s `Element` type.
  @usableFromInline
  package final class Storage
  : ManagedBuffer<Header, UInt64>
  {}
}

extension _HashTable {
  /// Allocate a new empty hash table buffer of the specified scale.
  @usableFromInline
  @_effects(releasenone)
  package init(scale: Int, reservedScale: Int = 0) {
    assert(scale >= Self.minimumScale && scale <= Self.maximumScale)
    let wordCount = Self.wordCount(forScale: scale)
    let storage = Storage.create(
      minimumCapacity: wordCount,
      makingHeaderWith: { object in
        #if COLLECTIONS_DETERMINISTIC_HASHING
        let seed = scale << 6
        #else
        let seed = Int(bitPattern: unsafe Unmanaged.passUnretained(object).toOpaque())
        #endif
        return Header(scale: scale, reservedScale: reservedScale, seed: seed)
      })
    unsafe storage.withUnsafeMutablePointerToElements { elements in
      unsafe elements.initialize(repeating: 0, count: wordCount)
    }
    self.init(unsafe unsafeDowncast(storage, to: Storage.self))
  }

  /// Populate a new hash table with data from `elements`.
  ///
  /// - Parameter scale: The desired hash table scale or nil to use the minimum
  ///     scale that satisfies invariants.
  /// - Parameter reservedScale: The reserved scale to remember in the returned
  ///     storage.
  /// - Returns: `(storage, index)` where `storage` is a storage instance. The
  ///     contents of `storage` reflects all elements in
  ///     `contents[contents.startIndex ..< index]`. `index` is usually
  ///     `contents.endIndex`, except when the function was asked to reject
  ///     duplicates, in which case `index` addresses the first duplicate
  ///     element in `contents` (if any).
  @inlinable
  @inline(never)
  @_effects(releasenone)
  package static func create<C: RandomAccessCollection>(
    uncheckedUniqueElements elements: C,
    scale: Int? = nil,
    reservedScale: Int = 0
  ) -> _HashTable?
  where C.Element: Hashable {
    let minScale = Self.scale(forCapacity: elements.count)
    let scale = Swift.max(Swift.max(scale ?? 0, minScale),
                          reservedScale)
    if scale < Self.minimumScale { return nil }
    let hashTable = Self(scale: scale, reservedScale: reservedScale)
    unsafe hashTable.update { handle in
      unsafe handle.fill(uncheckedUniqueElements: elements)
    }
    return hashTable
  }

  /// Populate a new hash table with data from `elements`.
  ///
  /// - Parameter scale: The desired hash table scale or nil to use the minimum
  ///    scale that satisfies invariants.
  /// - Parameter reservedScale: The reserved scale to remember in the returned
  ///    storage.
  /// - Returns: `(storage, index)` where `storage` is a storage instance. The
  ///    contents of `storage` reflects all elements in
  ///    `contents[contents.startIndex ..< index]`. `index` is usually
  ///    `contents.endIndex`, except when the function was asked to reject
  ///    duplicates, in which case `index` addresses the first duplicate
  ///    element in `contents` (if any).
  @inlinable
  @inline(never)
  @_effects(releasenone)
  package static func create<C: RandomAccessCollection>(
    untilFirstDuplicateIn elements: C,
    scale: Int? = nil,
    reservedScale: Int = 0
  ) -> (hashTable: _HashTable?, end: C.Index)
  where C.Element: Hashable {
    let minScale = Self.scale(forCapacity: elements.count)
    let scale = Swift.max(Swift.max(scale ?? 0, minScale),
                          reservedScale)

    if scale < Self.minimumScale {
      // Don't hash anything.
      if elements.count < 2 { return (nil, elements.endIndex) }
      // fast path that doesn't allocate per element if _read accessor can't
      // be inlined because this function doesn't get specialized e.g.
      // if `Element` isn't known at compile time.
      let firstDuplicateIndexFastPath: Int? = elements.withContiguousStorageIfAvailable { elements in
        var temp: ContiguousArray<C.Element> = []
        temp.reserveCapacity(elements.count)
        for i in elements.indices {
          let item = unsafe elements[i]
          guard !temp._contains(item) else { return i }
          temp.append(item)
        }
        return elements.endIndex
      }
      if let firstDuplicateIndexFastPath {
        return (nil, elements.index(elements.startIndex, offsetBy: firstDuplicateIndexFastPath))
      }
      var temp: ContiguousArray<C.Element> = []
      temp.reserveCapacity(elements.count)
      for i in elements.indices {
        let item = elements[i]
        guard !temp._contains(item) else { return (nil, i) }
        temp.append(item)
      }
      return (nil, elements.endIndex)
    }
    let hashTable = Self(scale: scale, reservedScale: reservedScale)
    let (_, index) = unsafe hashTable.update { handle in
      unsafe handle.fill(untilFirstDuplicateIn: elements)
    }
    return (hashTable, index)
  }

  /// Create and return a new copy of this instance. The result has the same
  /// scale and seed, and contains the exact same bucket data as the original instance.
  @usableFromInline
  @_effects(releasenone)
  package func copy() -> _HashTable {
    unsafe self.read { handle in
      let wordCount = unsafe handle.wordCount
      let new = Storage.create(
        minimumCapacity: wordCount,
        makingHeaderWith: { _ in unsafe handle._header.pointee })
      unsafe new.withUnsafeMutablePointerToElements { elements in
        unsafe elements.initialize(from: handle._buckets, count: wordCount)
      }
      return Self(unsafe unsafeDowncast(new, to: Storage.self))
    }
  }
}

/// copy of the standard library implementation of `Sequence.contains(_:)`
/// to allow partial specialization if `Element` is not known at compile time.
/// also some modification to remove some more generic overhead.
extension ContiguousArray where Element: Equatable {
  @inlinable
  internal func _contains(_ element: Element) -> Bool {
    for index in 0..<count {
      if element == self[index] {
        return true
      }
    }
    return false
  }
}



extension _HashTable {
  /// Call `body` with a hash table handle suitable for read-only use.
  ///
  /// - Warning: The handle supplied to `body` is only valid for the duration of
  ///    the closure call. The closure must not escape it outside the call.
  @inlinable
  @inline(__always)
  package func read<R>(_ body: (_UnsafeHashTable) throws -> R) rethrows -> R {
    unsafe try _storage.withUnsafeMutablePointers { header, elements in
      let handle = unsafe _UnsafeHashTable(header: header, buckets: elements, readonly: true)
      return unsafe try body(handle)
    }
  }

  /// Call `body` with a hash table handle suitable for mutating use.
  ///
  /// - Warning: The handle supplied to `body` is only valid for the duration of
  ///    the closure call. The closure must not escape it outside the call.
  @inlinable
  @inline(__always)
  package func update<R>(_ body: (_UnsafeHashTable) throws -> R) rethrows -> R {
    unsafe try _storage.withUnsafeMutablePointers { header, elements in
      let handle = unsafe _UnsafeHashTable(header: header, buckets: elements, readonly: false)
      return unsafe try body(handle)
    }
  }
}

extension _HashTable {
  @inlinable
  package var header: Header {
    get { _storage.header }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    nonmutating _modify { yield &_storage.header }
  }

  @inlinable
  package var capacity: Int {
    _storage.header.capacity
  }

  @inlinable
  package var minimumCapacity: Int {
    if scale == reservedScale { return 0 }
    return Self.minimumCapacity(forScale: scale)
  }

  @inlinable
  package var scale: Int {
    _storage.header.scale
  }

  @inlinable
  package var reservedScale: Int {
    _storage.header.reservedScale
  }

  @inlinable
  package var bias: Int {
    _storage.header.bias
  }
}
