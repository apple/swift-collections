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
  @usableFromInline
  package mutating func migrateItems_Small(
    from source: inout _HTable,
    migrator: (Bucket, Bucket) -> Void
  ) {
    assert(self.isEmpty)
    assert(self.isSmall)
    assert(source.count <= self.capacity)
    guard !source.isEmpty else { return }
    
    // Let's reverse the order of members, to emphasize that this is not an
    // ordered container.
    let c = source.count
    self._count = c
    self._maxProbeLength = c
    var dst = Bucket(offset: c)
    var it = source.makeBucketIterator()
    while let next = it.nextOccupiedRegion() {
      var src = next.lowerBound
      while src != next.upperBound {
        dst._offset &-= 1
        migrator(src, dst)
        src._offset &+= 1
      }
    }
    source.clear()
  }
    
  @usableFromInline
  package mutating func migrateItems_Large(
    from source: inout _HTable,
    selector: (Bucket) -> Int,
    hashGenerator: (Bucket) -> Int,
    swapper: (Bucket) -> Void,
    finalizer: (Bucket) -> Void,
  ) {
    assert(self.isEmpty)
    assert(!self.isSmall)
    assert(source.count <= self.capacity)
    guard !source.isEmpty else { return }
    
    // Move & rehash items one by one.
    var it = source.makeBucketIterator()
    while let next = it.nextOccupiedRegion() {
      var src = next.lowerBound
      while src < next.upperBound {
        let hashValue = selector(src)
        let dst = self.insertNew_Large(
          hashValue: hashValue,
          hashGenerator: hashGenerator,
          swapper: swapper)
        finalizer(dst)
        src._offset &+= 1
      }
    }
    source.clear()
  }
}

#endif
