//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if ENABLE_RUST_BENCHMARKS

import CollectionsBenchmark

extension Benchmark {
  public mutating func addRustBenchmarks() {
    _addRustVecDequeBenchmarks()
  }
}

#endif
