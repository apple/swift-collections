//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark

extension Benchmark {
  public mutating func addFoundationBenchmarks() {
    _addCFBinaryHeapBenchmarks()
    _addCFBitVectorBenchmarks()
  }
}
