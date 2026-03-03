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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS
@available(SwiftStdlib 5.0, *)
@frozen
@_addressableForDependencies
public struct RigidDictionary<
  Key: GeneralizedHashable & ~Copyable,
  Value: ~Copyable
>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket
  
  @_alwaysEmitIntoClient
  package var _keys: RigidSet<Key>

  @_alwaysEmitIntoClient
  package var _values: UnsafeMutablePointer<Value>?
  
  @_alwaysEmitIntoClient
  @_transparent
  package init(
    _keys: consuming RigidSet<Key>,
    values: UnsafeMutablePointer<Value>?
  ) {
    assert((values != nil) == (_keys._members != nil))
    self._keys = _keys
    self._values = values
  }
  
  @_alwaysEmitIntoClient
  deinit {
    // FIXME: This iterates over the bitmap twice: once in `self._dispose()`,
    // and once in `_keys.deinit`. `self` not being mutable really hurts us
    // here.
    if !isEmpty {
      _deinitializeValues()
    }
    _values?.deallocate()
  }
  
  @_alwaysEmitIntoClient
  internal func _deinitializeValues() {
    let values = _valueBuf
    var it = _keys._table.makeBucketIterator()
    while let range = it.nextOccupiedRegion() {
      values.extracting(range._offsets).deinitialize()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    _assumeNonNegative(_keys._table.count)
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    _assumeNonNegative(_keys._table.capacity)
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
    _keys._scale
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _keyBuf: UnsafeMutableBufferPointer<Key> {
    _keys._memberBuf
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal var _valueBuf: UnsafeMutableBufferPointer<Value> {
    .init(start: _values, count: Int(bitPattern: _keys._table.bucketCount))
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal func _valuePtr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Value> {
    assert(_keys._table.isValid(bucket))
    return _values.unsafelyUnwrapped.advanced(by: bucket.offset)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal func _keyPtr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Key> {
    _keys._memberPtr(at: bucket)
  }
}

#endif
