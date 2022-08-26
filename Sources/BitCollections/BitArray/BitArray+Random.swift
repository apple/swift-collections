//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray {
  public static func random(count: Int) -> BitArray {
    var rng = SystemRandomNumberGenerator()
    return random(count: count, using: &rng)
  }

  public static func random<R: RandomNumberGenerator>(
    count: Int,
    using rng: inout R
  ) -> BitArray {
    precondition(count >= 0, "Invalid capacity value")
    guard count > 0 else { return BitArray() }
    let (w, b) = _BitPosition(count).endSplit
    var words = (0 ... w).map { _ in _Word(rng.next() as UInt) }
    words[w].formIntersection(_Word(upTo: b))
    return BitArray(_storage: words, count: count)
  }
}
