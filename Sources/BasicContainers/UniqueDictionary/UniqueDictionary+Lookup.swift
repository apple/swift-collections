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
  public func containsKey(_ key: borrowing Key) -> Bool {
    _storage.containsKey(key)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  @_lifetime(borrow self)
  public func value(
    forKey key: borrowing Key
  ) -> Borrow<Value>? {
    // FIXME: Why is this override necessary? Is it sound? It was triggered by RigidDictionary becoming `@_addressableForDependencies`.
    _overrideLifetime(_storage.value(forKey: key), borrowing: self)
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
    try _storage.withValue(forKey: key, body)
  }
}

#endif
