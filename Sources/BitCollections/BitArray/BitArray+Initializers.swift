//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray {
  public init(_ set: BitSet<Index>) {
    guard let l = set.last else { self.init(); return }
    self.init(_storage: set._core._storage, count: l + 1)
  }
  
  public init<I: BinaryInteger>(bitPattern value: I) {
    let words = value.words.map { _Word($0) }
    let count = value.bitWidth
    self.init(_storage: words, count: count)
  }
}
