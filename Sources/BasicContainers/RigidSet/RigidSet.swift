//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif


#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS
/// A fixed-capacity, noncopyable, unordered hashed container of unique
/// elements.
@available(SwiftStdlib 5.0, *)
@frozen
public struct RigidSet<Element: GeneralizedHashable & ~Copyable>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket

  @_alwaysEmitIntoClient
  package var _members: UnsafeMutablePointer<Element>?
  
  @_alwaysEmitIntoClient
  package var _table: _HTable

  @inlinable
  @_transparent
  package init(
    _table: consuming _HTable
  ) {
    assert(_table.isEmpty)
    if _table.capacity == 0 {
      self._members = nil
    } else {
      self._members = .allocate(capacity: _table.storageCapacity)
    }
    self._table = _table
  }

  @_alwaysEmitIntoClient
  deinit {
    if !isEmpty {
      _deinitializeMembers()
    }
    _members?.deallocate()
  }
  
  @_alwaysEmitIntoClient
  internal func _deinitializeMembers() {
    let storage = _memberBuf
    var it = _table.makeBucketIterator()
    while let range = it.nextOccupiedRegion() {
      storage._extracting(unchecked: range._offsets).deinitialize()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    _assumeNonNegative(_table.count)
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    _assumeNonNegative(_table.capacity)
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
    _table.scale
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _storageCapacity: Int {
    _table.storageCapacity
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _memberBuf: UnsafeMutableBufferPointer<Element> {
    .init(start: _members, count: Int(bitPattern: _table.bucketCount))
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal func _memberPtr(
    at bucket: _Bucket
  ) -> UnsafeMutablePointer<Element> {
    assert(_table.isValid(bucket))
    return _members.unsafelyUnwrapped.advanced(by: bucket.offset)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal var _seed: Int {
#if COLLECTIONS_DETERMINISTIC_HASHING
    Int(_table.scale)
#else
    Int(bitPattern: _members)
#endif
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    at bucket: _Bucket
  ) -> Int {
    assert(bucket.offset >= 0 && bucket.offset < _table.storageCapacity)
    return _hashValue(for: _members.unsafelyUnwrapped[bucket.offset])
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    for item: borrowing Element
  ) -> Int {
    item._rawHashValue_temp(seed: _seed)
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
