//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A class holding hash table storage for a `Uniqued` collection.
/// Values in the hash table are offsets into separate element storage, so
/// this class doesn't need to be generic over `Uniqued`'s `Element` type.
internal final class _HashTableStorage: ManagedBuffer<_HashTableHeader, UInt64> {
  /// Allocate a new empty hash table buffer of the specified scale.
  static func create(scale: Int, reservedScale: Int = 0) -> _HashTableStorage {
    assert(scale >= _UnsafeHashTable.minimumScale && scale <= _UnsafeHashTable.maximumScale)
    let wordCount = _UnsafeHashTable.wordCount(forScale: scale)
    let storage = self.create(
      minimumCapacity: wordCount,
      makingHeaderWith: { object in
        #if COLLECTIONS_DETERMINISTIC_HASHING
        let seed = scale << 6
        #else
        let seed = Int(bitPattern: Unmanaged.passUnretained(object).toOpaque())
        #endif
        return _HashTableHeader(scale: scale, reservedScale: reservedScale, seed: seed)
      })
    storage.withUnsafeMutablePointerToElements { elements in
      elements.initialize(repeating: 0, count: wordCount)
    }
    return unsafeDowncast(storage, to: _HashTableStorage.self)
  }

  /// Populate a new hash table with data from `self`.
  ///
  /// - Parameter scale: The desired hash table scale or nil to use the minimum scale that satisfies invariants.
  /// - Parameter reservedScale: The reserved scale to remember in the returned storage.
  /// - Parameter duplicates: The strategy to use to handle duplicate items.
  /// - Returns: `(storage, index)` where `storage` is a storage instance. The contents of `storage` reflects all elements in `contents[contents.startIndex ..< index]`. `index` is usually `contents.endIndex`, except when the function was asked to reject duplicates, in which case `index` addresses the first duplicate element in `contents` (if any).
  static func create<C: RandomAccessCollection>(
    from contents: C,
    scale: Int? = nil,
    reservedScale: Int = 0,
    stoppingOnFirstDuplicateValue: Bool = true
  ) -> (storage: _HashTableStorage, end: C.Index)
  where C.Element: Hashable {
    let minScale = _UnsafeHashTable.scale(forCapacity: contents.count)
    let scale = scale ?? Swift.max(Swift.max(minScale, reservedScale),
                                   _UnsafeHashTable.minimumScale)
    assert(scale >= minScale && scale >= reservedScale)
    let storage = _HashTableStorage.create(scale: scale, reservedScale: reservedScale)
    let (_, index) = storage.update { hashTable in
      hashTable.fill(
        from: contents,
        stoppingOnFirstDuplicateValue: stoppingOnFirstDuplicateValue)
    }
    return (storage, index)
  }

  /// Create and return a new copy of this instance. The result has the same
  /// scale and seed, and contains the exact same bucket data as the original instance.
  internal func copy() -> _HashTableStorage {
    self.read { hashTable in
      let wordCount = hashTable.wordCount
      let new = Self.create(
        minimumCapacity: wordCount,
        makingHeaderWith: { _ in hashTable._header.pointee })
      new.withUnsafeMutablePointerToElements { elements in
        elements.initialize(from: hashTable._buckets, count: wordCount)
      }
      return unsafeDowncast(new, to: _HashTableStorage.self)
    }
  }

  /// Call `body` with a hash table handle suitable for read-only use.
  ///
  /// - Warning: The handle supplied to `body` is only valid for the duration of
  ///    the closure call. The closure must not escape it outside the call.
  @inline(__always)
  internal func read<R>(_ body: (_UnsafeHashTable) throws -> R) rethrows -> R {
    return try self.withUnsafeMutablePointers { header, elements in
      let hashTable = _UnsafeHashTable(header: header, buckets: elements, readonly: true)
      defer { withExtendedLifetime(self) {} }
      return try body(hashTable)
    }
  }

  /// Call `body` with a hash table handle suitable for mutating use.
  ///
  /// - Warning: The handle supplied to `body` is only valid for the duration of
  ///    the closure call. The closure must not escape it outside the call.
  @inline(__always)
  internal func update<R>(_ body: (_UnsafeHashTable) throws -> R) rethrows -> R {
    return try self.withUnsafeMutablePointers { header, elements in
      let hashTable = _UnsafeHashTable(header: header, buckets: elements, readonly: false)
      defer { withExtendedLifetime(self) {} }
      return try body(hashTable)
    }
  }
}

extension _HashTableStorage: CustomStringConvertible {
  internal var description: String {
    "_HashTableStorage\(header._description)"
  }
}
