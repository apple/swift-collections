//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SparseSet {
  #if COLLECTIONS_INTERNAL_CHECKS
  @inlinable
  @inline(never)
  internal func _checkInvariants() {
    // Check there are the same number of keys as values.
    precondition(_dense._keys.count == _dense._values.count)
    // Check that the sparse storage buffer has sufficient capacity.
    let universeSize: Int = keys.max().map { Int($0) + 1 } ?? 0
    precondition(_sparse.capacity >= universeSize)
    // Check that the keys' positions in the dense storage agree with those
    // given by the sparse storage.
    for (i, key) in _dense._keys.enumerated() {
      precondition(_sparse[key] == i)
    }
  }
  #else
  @inline(__always) @inlinable
  public func _checkInvariants() {}
  #endif // COLLECTIONS_INTERNAL_CHECKS
}
