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
import Benchmarks

var benchmark = Benchmark(title: "Collection Benchmarks")
benchmark.addArrayBenchmarks()
benchmark.addSetBenchmarks()
benchmark.addDictionaryBenchmarks()
benchmark.addDequeBenchmarks()
benchmark.addOrderedSetBenchmarks()
benchmark.addOrderedDictionaryBenchmarks()
benchmark.addCppBenchmarks()

benchmark.chartLibrary = try benchmark.loadReferenceLibrary()

benchmark.main()
