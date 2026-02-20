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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
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
    valueBuf._initializeElement(at: r.bucket, to: value)
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
    valueBuf._initializeElement(at: r.bucket, to: value)
    return nil
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
#endif
}

#endif
