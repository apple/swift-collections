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
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  public init() {
    self.init(capacity: 0)
  }

  @inlinable
  package init(_table: consuming _HTable) {
    let keys = RigidSet<Key>(_table: _table)
    let values: UnsafeMutablePointer<Value>?
    if keys.capacity == 0 {
      values = nil
    } else {
      values = .allocate(capacity: keys._storageCapacity)
    }
    self.init(_keys: keys, values: values)
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Capacity must be nonnegative")
    self.init(_table: _HTable(capacity: capacity))
  }
  
  @inlinable
  public init(consuming dict: consuming UniqueDictionary<Key, Value>) {
    self.init() // FIXME: Language limitation as of 6.3; this should not be needed here.
    // error: Conditional initialization or destruction of noncopyable types is
    // not supported; this variable must be consistently in an initialized or
    // uninitialized state through every code path
    self = dict._storage
  }
}

#endif
