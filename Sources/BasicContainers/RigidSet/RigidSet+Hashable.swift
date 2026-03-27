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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_HASHED_CONTAINERS && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.4, *)
extension RigidSet: Hashable {}

@available(SwiftStdlib 5.0, *)
extension RigidSet {
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
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
    var hash = 0
    var it = self.makeBorrowingIterator_()
    while true {
      let next = it.nextSpan_()
      var i = 0
      while i < next.count {
        hash ^= next[i]._rawHashValue(seed: seed)
        i &+= 1
      }
    }
    return hash
#else
    var hasher = Hasher()
    hasher.combine(seed)
    self.hash(into: &hasher)
    return hasher.finalize()
#endif
  }
}

#endif
