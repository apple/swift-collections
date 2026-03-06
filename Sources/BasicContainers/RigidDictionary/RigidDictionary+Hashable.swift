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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_HASHED_CONTAINERS

@available(SwiftStdlib 5.0, *)
extension RigidDictionary: Hashable where Value: Hashable { // Should be Hashable
  @inlinable
  public func hash(into hasher: inout Hasher) {
    var commutativeHash = 0
    var it = self._keys._table.makeBucketIterator()
    while let next = it.nextOccupiedRegion() {
      var b = next.lowerBound
      while b < next.upperBound {
        // Note that we use a copy of our own hasher here. This makes hash values
        // dependent on its state, eliminating static collision patterns.
        var elementHasher = hasher
        _keyPtr(at: b).pointee.hash(into: &elementHasher)
        _valuePtr(at: b).pointee.hash(into: &elementHasher)
        commutativeHash ^= elementHasher.finalize()
        b._offset &+= 1
      }
    }
    hasher.combine(commutativeHash)
  }
}

#endif
