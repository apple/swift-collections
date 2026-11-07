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
  @_alwaysEmitIntoClient
  public var keys: RigidSet<Key> {
    borrow {
      _keys
    }
  }

  /// Calls the given closure with a borrowed view of the keys in this
  /// dictionary.
  ///
  /// Until the compiler issue behind
  /// https://github.com/apple/swift-collections/issues/841 is fixed, prefer
  /// this method over the `keys` property: in some builds, `keys` can return
  /// a view into a deallocated temporary.
  @_alwaysEmitIntoClient
  public func withKeys<E: Error, R: ~Copyable>(
  _ body: (borrowing RigidSet<Key>) throws(E) -> R
  ) throws(E) -> R {
    try body(_keys)
  }
}

#endif
