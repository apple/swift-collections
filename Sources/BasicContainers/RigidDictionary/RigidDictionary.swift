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
public struct RigidDictionary<
  Key: GeneralizedHashable & ~Copyable,
    Value: ~Copyable
>: ~Copyable {
  @_alwaysEmitIntoClient
  package var _keys: RigidSet<Key>

  @_alwaysEmitIntoClient
  package var _values: UnsafeMutablePointer<Value>?
  
  @inlinable
  public init() {
    self.init(capacity: 0)
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Capacity must be nonnegative")
    self._keys = RigidSet(capacity: capacity)
    if capacity > 0 {
      self._values = .allocate(capacity: Int(bitPattern: _keys._table.bucketCount))
    } else {
      self._values = nil
    }
  }

  @_alwaysEmitIntoClient
  deinit {
    // FIXME: This iterates over the bitmap twice: once in `self._dispose()`,
    // and once in `_keys.deinit`. `self` not being mutable really hurts us
    // here.
    _dispose()
  }
  
  @_alwaysEmitIntoClient
  internal func _dispose() {
    if !isEmpty {
      let values = _valueBuf
      var it = _keys._table.makeBucketIterator()
      while let range = it.nextOccupiedRegion() {
        values.extracting(range._offsets).deinitialize()
      }
    }
    _values?.deallocate()
  }
}

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
}

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

extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @_lifetime(borrow self)
  public func value(
    forKey key: borrowing Key
  ) -> Borrow<Value>? {
    guard let bucket = _keys._find(key) else { return nil }
    return Borrow(unsafeAddress: _valuePtr(at: bucket), borrowing: self)
  }
  
  @inlinable
  public mutating func insertValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    let valueBuf = _valueBuf
    let r = _keys._insert(key) { key, bucket in
      swap(&value, &valueBuf[bucket])
    }
    if r.found {
      return value
    }
    valueBuf.initializeElement(at: r.bucket, to: value)
    return nil
  }
  
  @inlinable
  public mutating func updateValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    let valueBuf = _valueBuf
    let r = _keys._insert(key) { key, bucket in
      swap(&value, &valueBuf[bucket])
    }
    if r.found {
      return exchange(&valueBuf[r.bucket], with: value)
    }
    valueBuf.initializeElement(at: r.bucket, to: value)
    return nil
  }
  
  @inlinable
  @_lifetime(&self)
  public mutating func memoizedValue(
    forKey key: consuming Key,
    _ body: (borrowing Key) -> Value
  ) -> Borrow<Value> {
    let values = _valueBuf
    var value: Value? = nil
    let r = _keys._insert(key) { key, bucket in
      var v = value.take() ?? body(key)
      swap(&values[bucket.offset], &v)
      value = consume v
    }
    let p = values._ptr(at: r.bucket)
    if !r.found {
      p.initialize(to: value.take() ?? body(_keys._memberBuf[r.bucket]))
    }
    return Borrow(unsafeAddress: p, borrowing: self)
  }
}


#endif
