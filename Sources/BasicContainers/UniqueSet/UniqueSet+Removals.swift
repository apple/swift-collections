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
extension UniqueSet where Element: ~Copyable {
  @inlinable
  package mutating func _remove(at bucket: _Bucket) -> Element {
    guard self.count <= _HTable.minimumCapacity(forScale: self._scale) else {
      return _storage._remove(at: bucket)
    }
    // Shrink storage.
    let result = _storage._punchHole(at: bucket)
    _resize(minimumCapacity: self.count)
    return result
  }
  
  @inlinable
  public mutating func remove(_ member: borrowing Element) -> Element? {
    let r = _storage._find(member)
    guard let bucket = r.bucket else { return nil }
    return _remove(at: bucket)
  }
  
  @inlinable
  @inline(__always)
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    if keepCapacity {
      _storage.removeAll()
    } else {
      _storage = RigidSet()
    }
  }
}

#endif
