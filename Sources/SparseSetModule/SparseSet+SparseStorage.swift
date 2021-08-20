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

extension SparseSet {
  @usableFromInline
  internal struct _SparseStorage {
    @usableFromInline
    var buffer: Buffer

    @inlinable
    @inline(__always)
    init(_ buffer: Buffer) {
      self.buffer = buffer
    }

    @inlinable
    internal init<C: Collection>(withCapacity capacity: Int, keys: C) where C.Element == Key {
      self.buffer = Buffer.bufferWith(capacity: capacity, keys: keys)
    }

    @inlinable
    internal init(withCapacity capacity: Int) {
      self.buffer = Buffer.bufferWith(capacity: capacity, keys: EmptyCollection<Key>())
    }

    @inlinable
    internal init<C: Collection>(keys: C) where C.Element == Key {
      let universeSize: Int = keys.max().map { Int($0) + 1 } ?? 0
      self.buffer = Buffer.bufferWith(capacity: universeSize, keys: keys)
    }
  }
}

extension SparseSet._SparseStorage {
  @usableFromInline
  internal struct Header {
    @usableFromInline
    internal var capacity: Int

    @inlinable
    internal init(capacity: Int) {
      self.capacity = capacity
    }
  }
}

extension SparseSet._SparseStorage {
  @usableFromInline
  internal final class Buffer: ManagedBuffer<Header, Key> {
    /// Create a buffer populated with the given key data.
    ///
    /// - Parameters:
    ///   - capacity: The capacity of the new buffer.
    ///   - keys: A collection of keys.
    ///
    /// - Returns: A new buffer.
    @inlinable
    internal static func bufferWith<C: Collection>(capacity: Int, keys: C) -> Buffer where C.Element == Key {
      assert(capacity >= keys.max().map { Int($0) + 1 } ?? 0)
      let newBuffer = Buffer.create(
        minimumCapacity: capacity,
        makingHeaderWith: { _ in
          Header(capacity: capacity)
        })
      newBuffer.withUnsafeMutablePointerToElements { ptr in
        for (i, key) in keys.enumerated() {
          let index = Int(key)
          precondition(index >= 0, "Negative key")
          precondition(index < capacity, "Insufficient capacity")
          ptr[index] = Key(i)
        }
      }
      return unsafeDowncast(newBuffer, to: Buffer.self)
    }

    /// Create a new buffer populated with the same data as the given buffer.
    ///
    /// - Parameter buffer: The buffer to clone.
    ///
    /// - Returns: A new buffer.
    @inlinable
    internal static func bufferWith(contentsOf buffer: Buffer) -> Buffer {
      return Buffer.bufferWith(capacity: buffer.capacity, contentsOf: buffer)
    }

    /// Create a new buffer populated with data from the given buffer.
    ///
    /// The new capacity may be smaller than the capacity of the buffer
    /// providing the data, in which case not all the data will be copied.
    ///
    /// - Parameters:
    ///   - capacity: The capacity of the new buffer.
    ///   - buffer: The data to populate the new buffer with.
    ///
    /// - Returns: A new buffer.
    @inlinable
    internal static func bufferWith(capacity: Int, contentsOf buffer: Buffer) -> Buffer {
      let newBuffer = Buffer.create(
        minimumCapacity: capacity,
        makingHeaderWith: { _ in
          Header(capacity: capacity)
        })
      newBuffer.withUnsafeMutablePointerToElements { targetPtr in
        buffer.withUnsafeMutablePointerToElements { sourcePtr in
          targetPtr.moveAssign(from: sourcePtr, count: Swift.min(capacity, buffer.capacity))
        }
      }
      return unsafeDowncast(newBuffer, to: Buffer.self)
    }
  }
}

extension SparseSet._SparseStorage {
  @inlinable
  internal var capacity: Int {
    buffer.header.capacity
  }

  /// Resize this storage to a new capacity.
  ///
  /// The underlying buffer is replaced with a new one and its contents are
  /// copied.
  ///
  /// - Parameter newCapacity: The new capacity of the storage.
  @usableFromInline
  internal mutating func resize(to newCapacity: Int) {
    buffer = Buffer.bufferWith(capacity: newCapacity, contentsOf: buffer)
  }

  /// Resize this storage to a new capacity.
  ///
  /// The underlying buffer is replaced with a new one. The contents of the
  /// new buffer is initialized from the provided `keys` collection. This
  /// may be faster than `resize(to:)` when the density of the set is low (the
  /// number of members is small relative to the capacity).
  ///
  /// - Parameters:
  ///   - newCapacity: The new capacity of the storage.
  ///   - keys: A collection of keys.
  @usableFromInline
  internal mutating func resize<C: Collection>(to newCapacity: Int, keys: C) where C.Element == Key {
    buffer = Buffer.bufferWith(capacity: newCapacity, keys: keys)
  }

  /// Rebuilds the index data for the given keys.
  ///
  /// - Parameter keys: A collection of keys.
  @inlinable
  internal mutating func reindex<C: Collection>(keys: C) where C.Element == Key {
    assert(capacity >= keys.max().map { Int($0) + 1 } ?? 0)
    buffer.withUnsafeMutablePointerToElements { ptr in
      for(i, key) in keys.enumerated() {
        let index = Int(key)
        precondition(index >= 0, "Negative key")
        precondition(index < capacity, "Insufficient capacity")
        ptr[index] = Key(i)
      }
    }
  }
}

extension SparseSet._SparseStorage {
  @inlinable
  internal subscript(position: Key) -> Int {
    get {
      buffer.withUnsafeMutablePointerToElements { ptr in
        Int(ptr[Int(position)])
      }
    }
    set {
      buffer.withUnsafeMutablePointerToElements { ptr in
        ptr[Int(position)] = Key(newValue)
      }
    }
  }
}
