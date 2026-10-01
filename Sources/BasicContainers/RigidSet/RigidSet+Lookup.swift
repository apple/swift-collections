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
extension RigidSet where Element: ~Copyable {
  @inlinable
  package borrowing func _find(
    _ item: borrowing Element
  ) -> (bucket: _Bucket?, hashValue: Int) {
    let storage = unsafe _memberBuf
    if _isSmall {
      let bucket = unsafe _table.find_Small { unsafe storage[$0] == item }
      return (bucket, 0)
    }
    let hashValue = _hashValue(for: item)
    let bucket = unsafe _table.find_Large(
      hashValue: hashValue,
      tester: { unsafe storage[$0] == item })
    return (bucket, hashValue)
  }
  
  @inlinable
  public borrowing func contains(_ item: borrowing Element) -> Bool {
    _find(item).bucket != nil
  }
  
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  package func _borrowValue(at bucket: _Bucket) -> Ref<Element> {
    assert(unsafe self._table.isOccupied(bucket))
    return unsafe Ref(unsafeAddress: self._memberPtr(at: bucket), borrowing: self)
  }
}

#endif
