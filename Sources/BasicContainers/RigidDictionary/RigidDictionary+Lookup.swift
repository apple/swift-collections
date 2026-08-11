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
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  package borrowing func _find(
    _ key: borrowing Key
  ) -> (bucket: _Bucket?, hashValue: Int) {
    self._keys._find(key)
  }

  /// Checks if the given key is present in the `RigidDictionary`.
  ///
  /// - Parameter key: The key to find in the dictionary.
  @inlinable
  public func containsKey(_ key: borrowing Key) -> Bool {
    _find(key).bucket != nil
  }

  /// Checks if the given key is present in the `RigidDictionary`, and returns
  /// a reference to the value associated with it.
  ///
  /// - Parameter key: The key to find in the dictionary.
  /// - Returns: A reference to the value associated with the given `key`, or
  ///            nil if the `key` is not found.
  @available(SwiftStdlib 6.4, *)
  @inlinable
  @_lifetime(borrow self)
  public func value(
    forKey key: borrowing Key
  ) -> Ref<Value>? {
    guard let bucket = self._find(key).bucket else { return nil }
    return Ref(unsafeAddress: _valuePtr(at: bucket), borrowing: self)
  }

  /// Checks if the given key is present in the `RigidDictionary`, and returns
  /// a mutable reference to the value associated with it.
  ///
  /// - Parameter key: The key to find in the dictionary.
  /// - Returns: A mutable reference to the value associated with the given
  ///            `key`, or nil if the `key` is not found.
  @available(SwiftStdlib 6.4, *)
  @inlinable
  @_lifetime(&self)
  public mutating func mutableValue(
    forKey key: borrowing Key
  ) -> MutableRef<Value>? {
    guard let bucket = self._find(key).bucket else { return nil }
    return MutableRef(unsafeAddress: _valuePtr(at: bucket), mutating: &self)
  }

  /// A stand-in for a `struct Ref`-returning lookup operation.
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
  
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowKey(at bucket: _Bucket) -> Ref<Key> {
    assert(_keys._table.isOccupied(bucket))
    return Ref(unsafeAddress: _keyPtr(at: bucket), borrowing: self)
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowValue(at bucket: _Bucket) -> Ref<Value> {
    assert(_keys._table.isOccupied(bucket))
    return Ref(unsafeAddress: _valuePtr(at: bucket), borrowing: self)
  }
}

#endif
