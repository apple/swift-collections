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

#if compiler(>=6.2)

extension _HTable {
  /// Create a hole at the specified occupied bucket without marking it as
  /// unoccupied ot restoring the hash table's other invariants. After a hole
  /// is created, the table remains in an inconsistent state until one of
  /// `resolveHole` or `finalizeHole` is called on the same bucket.
  @usableFromInline
  package mutating func createHole(
    at bucket: Bucket
  ) {
    assert(isOccupied(bucket))
    _count &-= 1
  }
  
  /// Restore hash table invariants after a hole was created by `createHole`.
  /// This works by swapping items as needed to move the hole forward until we
  /// reach the end of the affected chain of occupied buckets.
  @usableFromInline
  @discardableResult
  package mutating func resolveHole(
    at bucket: Bucket,
    hashGenerator: (Bucket) -> Int,
    mover: (Bucket, Bucket) -> Void,
  ) -> Bucket {
    if isSmall {
      return finalizeHole(at: bucket, mover: mover)
    }
    assert(isOccupied(bucket))

    // Our hash table does not have tombstones, so the holes that are left
    // behind when an element is removed need to be immediately filled by the
    // next item in the same chain that can now take that position. The process
    // then repeats with the new hole thus created, until we reach the end of
    // the chain. This is only possible because we're using linear probing;
    // otherwise the same bucket would be part of a large number of diverging
    // chains, and such compacting would require a full rehashing.

    // Note: _maxProbeLength is not updated here, and so it may get out of
    // sync with reality. It will get reset at the next rehashing, but if the
    // table gets stuck at this size, this parameter may get significantly
    // larger than it should be. The hope is that it won't so much larger that
    // it would materially affect the performance of negative lookups.

    var hole = bucket

    var candidate = bucket
    wrapBucket(after: &candidate)

    while isOccupied(candidate) {
      let hashValue = hashGenerator(candidate)
      let ideal = self.idealBucket(forHashValue: hashValue)
    
      // Does this element belong in some bucket at or below `hole`?
      // If so, move it to the hole. We need two separate tests depending on
      // whether `[hole, candidate]` wraps around the end of the storage.
      let c0 = ideal <= hole
      let c1 = ideal > candidate
      if hole < candidate ? (c0 || c1) : (c0 && c1) {
        mover(candidate, hole)
        hole = candidate
      }
      wrapBucket(after: &candidate)
    }
    bitmap.clearOccupied(hole)
    return hole
  }

  /// Finalize the hole at the given bucket, by moving it to some other position
  /// (if needed), then marking it as unoccupied.
  ///
  /// This does not fully restore the hash table to a usable state, but it
  /// does enough to allow the hash table to get resized.
  @discardableResult
  @usableFromInline
  package mutating func finalizeHole(
    at bucket: Bucket,
    mover: (Bucket, Bucket) -> Void,
  ) -> Bucket {
    assert(isValid(bucket))
    if isSmall {
      let last = Bucket(offset: _count) // Note: _count was decreased by createHole
      guard bucket < last else { return bucket }
      mover(last, bucket)
      return last
    }
    bitmap.clearOccupied(bucket)
    return bucket
  }
}

#endif
