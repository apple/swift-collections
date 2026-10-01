//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if UnstableHashedContainers
#if compiler(<6.4)
/// A fixed-capacity, noncopyable, unordered hashed container of unique
/// elements.
@available(*, unavailable, message: "RigidSet requires a Swift 6.4 toolchain")
public struct RigidSet<Element: Hashable>: ~Copyable {
  package init() {
    fatalError()
  }
}
#else
/// A fixed-capacity, noncopyable, unordered hashed container of unique
/// elements.
@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct RigidSet<Element: Hashable & ~Copyable>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket

  @_alwaysEmitIntoClient
  @unsafe
  package var _members: UnsafeMutablePointer<Element>?
  
  @_alwaysEmitIntoClient
  @unsafe // FIXME: Only mutations are unsafe
  package var _table: _HTable

  @inlinable
  @_transparent
  @unsafe
  package init(
    _table: consuming _HTable
  ) {
    assert(_table.isEmpty)
    if _table.capacity == 0 {
      unsafe self._members = nil
    } else {
      unsafe self._members = .allocate(capacity: _table.storageCapacity)
    }
    unsafe self._table = _table
  }

  @_alwaysEmitIntoClient
  deinit {
    if !isEmpty {
      unsafe _deinitializeMembers()
    }
    unsafe _members?.deallocate()
  }
  
  @_alwaysEmitIntoClient
  @unsafe
  internal func _deinitializeMembers() {
    // FIXME: This should be declared mutating and update stored properties.
    let storage = unsafe _memberBuf
    var it = unsafe _table.makeBucketIterator()
    while let range = it.nextOccupiedRegion() {
      unsafe storage._extracting(unchecked: range._offsets).deinitialize()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    unsafe _assumeNonNegative(_table.count)
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    unsafe _assumeNonNegative(_table.capacity)
  }
  
  @inlinable
  @inline(__always)
  public var isEmpty: Bool {
    count == 0
  }
  
  @inlinable
  @inline(__always)
  public var isFull: Bool {
    count == capacity
  }
  
  @inlinable
  @inline(__always)
  public var freeCapacity: Int {
    _assumeNonNegative(capacity &- count)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _scale: UInt8 {
    unsafe _table.scale
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _storageCapacity: Int {
    unsafe _table.storageCapacity
  }

  @_alwaysEmitIntoClient
  @_transparent
  public var _isSmall: Bool {
    unsafe _table.isSmall
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal var _memberBuf: UnsafeMutableBufferPointer<Element> {
    unsafe .init(start: _members, count: Int(bitPattern: _table.bucketCount))
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal func _memberPtr(
    at bucket: _Bucket
  ) -> UnsafeMutablePointer<Element> {
    assert(unsafe _table.isValid(bucket))
    return unsafe _members.unsafelyUnwrapped.advanced(by: bucket.offset)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal var _seed: Int {
#if COLLECTIONS_DETERMINISTIC_HASHING
    unsafe Int(_table.scale)
#else
    unsafe Int(bitPattern: _members)
#endif
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    at bucket: _Bucket
  ) -> Int {
    assert(unsafe bucket.offset >= 0 && bucket.offset < _table.storageCapacity)
    return unsafe _hashValue(for: _members.unsafelyUnwrapped[bucket.offset])
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    for item: borrowing Element
  ) -> Int {
    item._rawHashValue(seed: _seed)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  package mutating func _take() -> Self {
    let r = self
    self = .init()
    return r
  }
}

#endif
#endif
