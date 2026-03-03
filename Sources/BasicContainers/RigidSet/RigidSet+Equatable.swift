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
extension RigidSet {
  @inlinable
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._members == other._members
    && self._table.isTriviallyIdentical(to: other._table)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet: GeneralizedEquatable { // Should be Equatable
  @inlinable
  public static func ==(left: borrowing Self, right: borrowing Self) -> Bool {
    if left.isTriviallyIdentical(to: right) { return true }
    
    guard left.count == right.count else { return false }
    
    var lit = left.makeBorrowingIterator()
    while true {
      let l = lit.nextSpan()
      if l.isEmpty { break }
      var i = 0
      while i < l.count {
        guard right.contains(l[i]) else { return false }
        i &+= 1
      }
    }
    return true
  }
}

#endif
