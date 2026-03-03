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
  @_alwaysEmitIntoClient
  @_transparent
  package borrowing func _find(
    _ key: borrowing Key
  ) -> (bucket: _Bucket?, hashValue: Int) {
    self._keys._find(key)
  }
  
  @inlinable
  public func containsKey(_ key: borrowing Key) -> Bool {
    _find(key).bucket != nil
  }
    
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  @_lifetime(borrow self)
  public func value(
    forKey key: borrowing Key
  ) -> Borrow<Value>? {
    guard let bucket = self._find(key).bucket else { return nil }
    return Borrow(unsafeAddress: _valuePtr(at: bucket), borrowing: self)
  }
#endif

  /// A stand-in for a `struct Borrow`-returning lookup operation.
  /// This is quite clumsy to use, but this is the best we can do without a way
  /// to express optional borrows.
  @_alwaysEmitIntoClient
  @_transparent
  public func withValue<E: Error, R: ~Copyable>(
    forKey key: borrowing Key,
    _ body: (borrowing Value) throws(E) -> R?
  ) throws(E) -> R? {
    guard let bucket = self._find(key).bucket else { return nil }
    return try body(_valueBuf[bucket])
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowKey(at bucket: _Bucket) -> Borrow<Key> {
    assert(_keys._table.isOccupied(bucket))
    return Borrow(unsafeAddress: _keyPtr(at: bucket), borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowValue(at bucket: _Bucket) -> Borrow<Value> {
    assert(_keys._table.isOccupied(bucket))
    return Borrow(unsafeAddress: _valuePtr(at: bucket), borrowing: self)
  }
#endif
}

#endif
