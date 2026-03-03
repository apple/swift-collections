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
extension RigidSet: GeneralizedHashable { // Should be Hashable
  @inlinable
  public func hash(into hasher: inout Hasher) {
    // Generate a seed from a snapshot of the hasher.  This makes members' hash
    // values depend on the state of the hasher, which improves hashing
    // quality. (E.g., it makes it possible to resolve collisions by passing in
    // a different hasher.)
    let copy = hasher
    hasher.combine(_rawHashValue(seed: copy.finalize()))
  }
  
  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    var hash = 0
    var it = self.makeBorrowingIterator()
    while true {
      let next = it.nextSpan()
      var i = 0
      while i < next.count {
        hash ^= next[i]._rawHashValue_temp(seed: seed)
        i &+= 1
      }
    }
    return hash
  }
}

#endif
