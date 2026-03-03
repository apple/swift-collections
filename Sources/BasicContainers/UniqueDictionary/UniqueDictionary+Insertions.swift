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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func insertValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    var (bucket, hashValue) = _storage._find(key)
    if bucket != nil {
      return value
    }
    if _ensureFreeCapacity(1), !_storage._keys._table.isSmall {
      hashValue = _storage._keys._hashValue(for: key)
    }
    _storage._insertNew(key, hashValue: hashValue, value)
    return nil
  }
  
  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: consuming Value,
    forKey key: consuming Key
  ) -> Value? {
    var (bucket, hashValue) = _storage._find(key)
    if let bucket {
      return exchange(&_storage._valuePtr(at: bucket).pointee, with: value)
    }
    if _ensureFreeCapacity(1), !_storage._keys._table.isSmall {
      hashValue = _storage._keys._hashValue(for: key)
    }
    _storage._insertNew(key, hashValue: hashValue, value)
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
    let r = _storage._find(key)
    let bucket: _Bucket
    if let b = r.bucket {
      bucket = b
    } else {
      let value = try body(key)
      var hashValue = r.hashValue
      if _ensureFreeCapacity(1), !_storage._keys._table.isSmall {
        hashValue = _storage._keys._hashValue(for: key)
      }
      bucket = _storage._insertNew(key, hashValue: hashValue, value)
    }
    return _storage._borrowValue(at: bucket)
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
    
    let r = _storage._find(key)
    bucket = r.bucket
    if let bucket {
      value = _storage._valuePtr(at: bucket).move()
    }
    
    var key: Key? = key // To work around inability to consume key in deinit
    defer {
      if let bucket {
        if let value = value.take() { // Simple update
          _storage._valuePtr(at: bucket).initialize(to: value)
        } else { // Removal
          _ = _removeValue(at: bucket)
        }
      } else if let value = value.take() {
        // Insertion.
        let key = key.take()!
        var hashValue = r.hashValue
        if _ensureFreeCapacity(1), !_storage._keys._table.isSmall {
          hashValue = _storage._keys._hashValue(for: key)
        }
        _storage._insertNew(key, hashValue: hashValue, value)
      }
    }
    
    return try updater(&value)
  }
  
}
#endif
