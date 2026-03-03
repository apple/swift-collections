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

#if false // This requires the BorrowAndMutateAccessors feature that isn't available yet.
//  @inlinable
//  public var keys: RigidSet<Key> {
//    borrow {
//      _keys
//    }
//  }
#endif
  
  /// This is a stand-in for an eventual computed property with a `borrow`
  /// accessor. It is destined for deprecation once that feature becomes
  /// available.
  @_alwaysEmitIntoClient
  public func withKeys<E: Error, R: ~Copyable>(
  _ body: (borrowing RigidSet<Key>) throws(E) -> R
  ) throws(E) -> R {
    try body(_keys)
  }
}

#endif
