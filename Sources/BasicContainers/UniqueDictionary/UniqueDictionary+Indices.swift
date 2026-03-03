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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  public typealias Indices = RigidDictionary<Key, Value>.Indices

  @inlinable
  public var indices: Indices {
    @_lifetime(borrow self)
    get {
      _storage.indices
    }
  }
}

#endif
