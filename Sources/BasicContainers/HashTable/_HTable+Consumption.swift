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
  package mutating func consumeAll(
    consumer: (Range<Bucket>) -> Void
  ) {
    var it = makeBucketIterator()
    while let next = it.nextOccupiedRegion() {
      consumer(next)
    }
    clear()
  }
}

#endif
