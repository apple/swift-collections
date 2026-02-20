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
  @_alwaysEmitIntoClient
  @_transparent
  @discardableResult
  package mutating func _ensureFreeCapacity(_ freeCapacity: Int) -> Bool {
    let c = count + freeCapacity
    guard _storage.capacity < c else { return false }
    _resize(minimumCapacity: c)
    return true
  }
  
  @inlinable
  @inline(never)
  package mutating func _resize(minimumCapacity: Int) {
    let p = _HTable.dynamicStorageParameters(minimumCapacity: minimumCapacity)
    self._storage._resize(scale: p.scale, capacity: p.capacity)
  }
  
  @inlinable
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    guard minimumCapacity > capacity else { return }
    _resize(minimumCapacity: minimumCapacity)
  }
}

#endif
