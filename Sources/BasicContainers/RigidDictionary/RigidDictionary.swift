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
@available(*, unavailable, message: "RigidDictionary requires a Swift 6.4 toolchain")
@frozen
@safe
public struct RigidDictionary<
  Key: Hashable,
  Value: ~Copyable
>: ~Copyable {
  package init() {
    fatalError()
  }
}
#else
@available(SwiftStdlib 5.0, *)
@frozen
@_addressableForDependencies
@safe
public struct RigidDictionary<
  Key: Hashable & ~Copyable,
  Value: ~Copyable
>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket
  
  @_alwaysEmitIntoClient
  package var _keys: RigidSet<Key>

  @_alwaysEmitIntoClient
  @unsafe
  package var _values: UnsafeMutablePointer<Value>
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  package init(
    _keys: consuming RigidSet<Key>,
    values: UnsafeMutablePointer<Value>
  ) {
    assert(unsafe (values != ._dangling()) == (_keys._members != nil))
    self._keys = _keys
    unsafe self._values = values
  }
  
  @_alwaysEmitIntoClient
  deinit {
    // FIXME: This iterates over the bitmap twice: once in `self._dispose()`,
    // and once in `_keys.deinit`. `self` not being mutable really hurts us
    // here.
    if !isEmpty {
      unsafe _deinitializeValues()
      unsafe _values.deallocate()
    }
  }
  
  @_alwaysEmitIntoClient
  @unsafe
  internal func _deinitializeValues() {
    let values = unsafe _valueBuf
    var it = unsafe _keys._table.makeBucketIterator()
    while let range = it.nextOccupiedRegion() {
      unsafe values.extracting(range._offsets).deinitialize()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    _keys.count
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    _keys.capacity
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
    _keys.freeCapacity
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _scale: UInt8 {
    _keys._scale
  }

  @_alwaysEmitIntoClient
  @_transparent
  public var _isSmall: Bool {
    _keys._isSmall
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal var _keyBuf: UnsafeMutableBufferPointer<Key> {
    unsafe _keys._memberBuf
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal var _valueBuf: UnsafeMutableBufferPointer<Value> {
    unsafe .init(start: _values, count: Int(bitPattern: _keys._table.bucketCount))
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal func _valuePtr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Value> {
    assert(unsafe _keys._table.isValid(bucket))
    return unsafe _values.advanced(by: bucket.offset)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  internal func _keyPtr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Key> {
    unsafe _keys._memberPtr(at: bucket)
  }
}

#endif
#endif
