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
  @inlinable
  public mutating func removeValue(forKey key: borrowing Key) -> Value? {
    let r = _keys._find(key)
    guard let bucket = r.bucket else { return nil }
    return _removeValue(at: bucket)
  }
  
  @inlinable
  package mutating func _removeValue(at bucket: _Bucket) -> Value {
    assert(unsafe self._keys._table.isOccupied(bucket))
    unsafe self._keyPtr(at: bucket).deinitialize(count: 1)
    let oldValue = unsafe self._valuePtr(at: bucket).move()
    unsafe _resolveHole(at: bucket)
    return oldValue
  }
  
  /// Remove the entry at `bucket`, assuming its value slot has already been
  /// moved out (e.g., by `updateValue(forKey:with:)`). Handles key
  /// deinitialization and hole resolution without touching the value slot.
  @inlinable
  @unsafe
  package mutating func _resolveHole(at bucket: _Bucket) {
    assert(unsafe self._keys._table.isOccupied(bucket))
    unsafe self._keys._table.createHole(at: bucket)
    let seed = self._keys._seed
    let keys = unsafe self._keys._members.unsafelyUnwrapped
    unsafe self._keys._table.resolveHole(
      at: bucket,
      hashGenerator: {
        unsafe keys[$0.offset]._rawHashValue(seed: seed)
      },
      mover: {
        unsafe (keys + $1.offset).initialize(to: (keys + $0.offset).move())
        unsafe (_values + $1.offset).initialize(to: (_values + $0.offset).move())
      })
  }

  /// Remove the member currently at the specified occupied bucket,
  /// and mark it as unoccupied, without restoring the hash table's
  /// invariants. Lookup operations may fail after this.
  ///
  /// This operation is intended to be used just before resizing the table.
  @inlinable
  @unsafe
  package mutating func _punchHole(at bucket: _Bucket) -> Value {
    assert(unsafe self._keys._table.isOccupied(bucket))
    unsafe self._keys._table.createHole(at: bucket)
    unsafe self._keyPtr(at: bucket).deinitialize(count: 1)

    let oldValue = unsafe self._valuePtr(at: bucket).move()
    let keys = unsafe self._keys._members.unsafelyUnwrapped
    unsafe self._keys._table.finalizeHole(
      at: bucket,
      mover: {
        unsafe (keys + $1.offset).initialize(to: (keys + $0.offset).move())
        unsafe (_values + $1.offset).initialize(to: (_values + $0.offset).move())
      })
    return oldValue
  }
  
  @inlinable
  public mutating func removeAll() {
    if isEmpty { return }
    unsafe _deinitializeValues()
    unsafe _keys._deinitializeMembers()
    unsafe _keys._table.clear()
  }
}

#endif
