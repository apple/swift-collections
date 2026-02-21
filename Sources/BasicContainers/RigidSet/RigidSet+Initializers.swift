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
extension RigidSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public init() {
    self.init(capacity: 0)
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Capacity must be nonnegative")
    self.init(_table: _HTable(capacity: capacity))
  }
  
  @inlinable
  public init(consuming set: consuming UniqueSet<Element>) {
    self.init() // FIXME: Language limitation as of 6.3; this should not be needed here.
    // error: Conditional initialization or destruction of noncopyable types is
    // not supported; this variable must be consistently in an initialized or
    // uninitialized state through every code path
    self = set._storage
  }
}

#endif
