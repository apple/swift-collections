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

#if !COLLECTIONS_SINGLE_MODULE
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @inlinable
  package borrowing func _find(
    _ item: borrowing Element
  ) -> (bucket: _Bucket?, hashValue: Int) {
    let storage = _memberBuf
    if _table.isSmall {
      let bucket = _table.find_Small(tester: { storage[$0] == item })
      return (bucket, 0)
    }
    let hashValue = _hashValue(for: item)
    let bucket = _table.find_Large(
      hashValue: hashValue,
      tester: { storage[$0] == item })
    return (bucket, hashValue)
  }
  
  @inlinable
  public borrowing func contains(_ item: borrowing Element) -> Bool {
    _find(item).bucket != nil
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowValue(at bucket: _Bucket) -> Borrow<Element> {
    assert(self._table.isOccupied(bucket))
    return Borrow(unsafeAddress: self._memberPtr(at: bucket), borrowing: self)
  }
#endif
}

#endif
