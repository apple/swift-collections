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
  public mutating func remove(_ member: borrowing Element) -> Element? {
    let r = _find(member)
    guard let bucket = r.bucket else { return nil }
    return _remove(at: bucket)
  }
  
  /// Remove the member currently at the specified occupied bucket,
  /// and mark it as unoccupied, without restoring the hash table's
  /// invariants. Lookup operations may fail after this.
  ///
  /// This operation is intended to be used just before resizing the table.
  @inlinable
  package mutating func _punchHole(at bucket: _Bucket) -> Element {
    assert(_table.isOccupied(bucket))
    _table.createHole(at: bucket)
    let result = _memberPtr(at: bucket).move()
    let members = _members.unsafelyUnwrapped
    _table.finalizeHole(
      at: bucket,
      mover: {
        (members + $1.offset).initialize(to: (members + $0.offset).move())
      })
    return result
  }
  
  @inlinable
  package mutating func _remove(at bucket: _Bucket) -> Element {
    assert(_table.isOccupied(bucket))
    _table.createHole(at: bucket)
    let result = _memberPtr(at: bucket).move()
    let seed = self._seed
    let members = _members.unsafelyUnwrapped
    _table.resolveHole(
      at: bucket,
      hashGenerator: {
        members[$0.offset]._rawHashValue_temp(seed: seed)
      },
      mover: {
        (members + $1.offset).initialize(to: (members + $0.offset).move())
      })
    return result
  }
  
  @inlinable
  public mutating func removeAll() {
    if isEmpty { return }
    _deinitializeMembers()
    _table.clear()
  }
}

#endif
