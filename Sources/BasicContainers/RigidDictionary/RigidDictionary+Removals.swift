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
  @inlinable
  public mutating func removeValue(forKey key: borrowing Key) -> Value? {
    let r = _keys._find(key)
    guard let bucket = r.bucket else { return nil }
    return _removeValue(at: bucket)
  }
  
  @inlinable
  package mutating func _removeValue(at bucket: _Bucket) -> Value {
    assert(self._keys._table.isOccupied(bucket))
    self._keys._table.createHole(at: bucket)
    self._keyPtr(at: bucket).deinitialize(count: 1)
    let oldValue = self._valuePtr(at: bucket).move()
    let seed = self._keys._seed
    let keys = self._keys._members.unsafelyUnwrapped
    let values = self._values.unsafelyUnwrapped
    self._keys._table.resolveHole(
      at: bucket,
      hashGenerator: {
        keys[$0.offset]._rawHashValue_temp(seed: seed)
      },
      mover: {
        (keys + $1.offset).initialize(to: (keys + $0.offset).move())
        (values + $1.offset).initialize(to: (values + $0.offset).move())
      })
    return oldValue
  }
  
  /// Remove the member currently at the specified occupied bucket,
  /// and mark it as unoccupied, without restoring the hash table's
  /// invariants. Lookup operations may fail after this.
  ///
  /// This operation is intended to be used just before resizing the table.
  @inlinable
  package mutating func _punchHole(at bucket: _Bucket) -> Value {
    assert(self._keys._table.isOccupied(bucket))
    self._keys._table.createHole(at: bucket)
    self._keyPtr(at: bucket).deinitialize(count: 1)

    let oldValue = self._valuePtr(at: bucket).move()
    let keys = self._keys._members.unsafelyUnwrapped
    let values = self._values.unsafelyUnwrapped
    self._keys._table.finalizeHole(
      at: bucket,
      mover: {
        (keys + $1.offset).initialize(to: (keys + $0.offset).move())
        (values + $1.offset).initialize(to: (values + $0.offset).move())
      })
    return oldValue
  }
  
  @inlinable
  public mutating func removeAll() {
    if isEmpty { return }
    _deinitializeValues()
    _keys._deinitializeMembers()
    _keys._table.clear()
  }
}

#endif
