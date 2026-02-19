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
    self.init() // FIXME: This should not be needed here.
    self = set._storage
  }
}

#endif
