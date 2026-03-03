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
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @inline(__always)
  @discardableResult
  package mutating func _insertNew(
    _ key: consuming Key,
    hashValue: Int,
    _ value: consuming Value
  ) -> _Bucket {
    precondition(!isFull, "RigidDictionary capacity overflow")
    let keys = _keyBuf
    let values = _valueBuf
    if self._keys._table.isSmall {
      let bucket = self._keys._table.insertNew_Small(
        swapper: {
          swap(&key, &keys[$0])
          swap(&value, &values[$0])
        })
      keys._initializeElement(at: bucket, to: key)
      values._initializeElement(at: bucket, to: value)
      return bucket
    }
    return _insertNew_Large(key, hashValue: hashValue, value)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  package mutating func _insertNew_Large(
    _ key: consuming Key,
    hashValue: Int,
    _ value: consuming Value
  ) -> _Bucket {
    let keys = _keyBuf
    let values = _valueBuf
    let seed = self._keys._seed
    let bucket = self._keys._table.insertNew_Large(
      hashValue: hashValue,
      hashGenerator: {
        keys[$0]._rawHashValue_temp(seed: seed)
      },
      swapper: { bucket in
        swap(&key, &keys[bucket])
        swap(&value, &values[bucket])
      })
    keys.initializeElement(at: bucket.offset, to: key)
    values.initializeElement(at: bucket.offset, to: value)
    return bucket
  }

  
  @inlinable
  @discardableResult
  public mutating func insertValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    let r = _find(key)
    if r.bucket != nil {
      return value
    }
    self._insertNew(key, hashValue: r.hashValue, value)
    return nil
  }
  
  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    let r = _find(key)
    if let bucket = r.bucket {
      return exchange(&_valuePtr(at: bucket).pointee, with: value)
    }
    self._insertNew(key, hashValue: r.hashValue, value)
    return nil
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  @discardableResult
  @_lifetime(&self)
  public mutating func memoizedValue<E: Error>(
    forKey key: consuming Key,
    _ body: (borrowing Key) throws(E) -> Value
  ) throws(E) -> Borrow<Value> {
    let r = _find(key)
    let bucket: _Bucket
    if let b = r.bucket {
      bucket = b
    } else {
      let value = try body(key)
      bucket = self._insertNew(key, hashValue: r.hashValue, value)
    }
    return _borrowValue(at: bucket)
  }
#endif
  
  @inlinable
  @discardableResult
  public mutating func updateValue<E: Error, R: ~Copyable>(
    forKey key: consuming Key,
    with updater: (inout Value?) throws(E) -> R
  ) throws(E) -> R {
    var bucket: _Bucket?
    var value: Value?
    
    let r = _keys._find(key)
    bucket = r.bucket
    if let bucket {
      value = _valuePtr(at: bucket).move()
    }
    var key: Key? = key // To work around inability to consume key in deinit
    defer {
      if let bucket {
        if let value = value.take() { // Simple update
          _valuePtr(at: bucket).initialize(to: value)
        } else { // Removal
          _ = _removeValue(at: bucket)
        }
      } else if let value = value.take() { // Insertion
        self._insertNew(key.take()!, hashValue: r.hashValue, value)
      }
    }
    return try updater(&value)
  }
}

#endif
