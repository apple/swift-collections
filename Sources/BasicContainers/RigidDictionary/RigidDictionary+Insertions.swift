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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @inline(__always)
  @discardableResult
  @unsafe
  package mutating func _insertNew(
    _ key: consuming Key,
    hashValue: Int,
    _ value: consuming Value
  ) -> _Bucket {
    precondition(!isFull, "RigidDictionary capacity overflow")
    let keys = unsafe _keyBuf
    let values = unsafe _valueBuf
    if self._keys._isSmall {
      let bucket = unsafe self._keys._table.insertNew_Small(
        swapper: {
          unsafe swap(&key, &keys[$0])
          unsafe swap(&value, &values[$0])
        })
      unsafe keys._initializeElement(at: bucket, to: key)
      unsafe values._initializeElement(at: bucket, to: value)
      return bucket
    }
    return unsafe _insertNew_Large(key, hashValue: hashValue, value)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @unsafe
  package mutating func _insertNew_Large(
    _ key: consuming Key,
    hashValue: Int,
    _ value: consuming Value
  ) -> _Bucket {
    let keys = unsafe _keyBuf
    let values = unsafe _valueBuf
    let seed = self._keys._seed
    let bucket = unsafe self._keys._table.insertNew_Large(
      hashValue: hashValue,
      hashGenerator: {
        unsafe keys[$0]._rawHashValue(seed: seed)
      },
      swapper: { bucket in
        unsafe swap(&key, &keys[bucket])
        unsafe swap(&value, &values[bucket])
      })
    unsafe keys.initializeElement(at: bucket.offset, to: key)
    unsafe values.initializeElement(at: bucket.offset, to: value)
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
    unsafe self._insertNew(key, hashValue: r.hashValue, value)
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
      return unsafe exchange(&_valuePtr(at: bucket).pointee, with: value)
    }
    unsafe self._insertNew(key, hashValue: r.hashValue, value)
    return nil
  }
  
  @available(SwiftStdlib 6.4, *)
  @inlinable
  @discardableResult
  @_lifetime(&self)
  public mutating func memoizedValue<E: Error>(
    forKey key: consuming Key,
    _ body: (borrowing Key) throws(E) -> Value
  ) throws(E) -> Ref<Value> {
    let r = _find(key)
    let bucket: _Bucket
    if let b = r.bucket {
      bucket = b
    } else {
      let value = try body(key)
      bucket = unsafe self._insertNew(key, hashValue: r.hashValue, value)
    }
    return _borrowValue(at: bucket)
  }

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
      value = unsafe _valuePtr(at: bucket).move()
    }
    var key: Key? = key // To work around inability to consume key in deinit
    defer {
      if let bucket {
        if let value = value.take() { // Simple update
          unsafe _valuePtr(at: bucket).initialize(to: value)
        } else { // Removal
          unsafe self._keyPtr(at: bucket).deinitialize(count: 1)
          unsafe _resolveHole(at: bucket)
        }
      } else if let value = value.take() { // Insertion
        unsafe self._insertNew(key.take()!, hashValue: r.hashValue, value)
      }
    }
    return try updater(&value)
  }
}

#endif
