//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.8, *)
extension BigString {
  struct ChunkIterator {
    var base: _Rope.Iterator

    init(base: _Rope.Iterator) {
      self.base = base
    }
  }

  func makeChunkIterator() -> ChunkIterator {
    ChunkIterator(base: _rope.makeIterator())
  }
}

@available(SwiftStdlib 5.8, *)
extension BigString.ChunkIterator: IteratorProtocol {
  typealias Element = String

  mutating func next() -> String? {
    base.next()?.string
  }
}
