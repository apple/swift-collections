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
import InternalCollectionsUtilities
import ContainersPreview
#endif


#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidDictionary {
  @inlinable
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._keys.isTriviallyIdentical(to: other._keys)
    && self._values == other._values
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary {
  @inlinable
  public func isEqual(
    to other: borrowing Self,
    by areEquivalent: (borrowing Value, borrowing Value) -> Bool
  ) -> Bool {
    if self.isTriviallyIdentical(to: other) { return true }
    
    guard self.count == other.count else { return false }
    
    var it = self._keys._table.makeBucketIterator()
    while let next = it.nextOccupiedRegion() {
      var lb = next.lowerBound
      while lb < next.upperBound {
        let res = other._find(self._keyPtr(at: lb).pointee)
        guard let rb = res.bucket else { return false }
        
        let lp = self._valuePtr(at: lb)
        let rp = other._valuePtr(at: rb)
        guard areEquivalent(lp.pointee, rp.pointee) else { return false }
        lb._offset &+= 1
      }
    }
    return true
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary: GeneralizedEquatable where Value: GeneralizedEquatable { // Should be Equatable
  @inlinable
  public static func ==(left: borrowing Self, right: borrowing Self) -> Bool {
    left.isEqual(to: right, by: ==)
  }
}

#endif
