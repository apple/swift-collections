// swift-tools-version:6.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
  name: "swift-collections.Benchmarks",
  platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11), .tvOS(.v18), .visionOS(.v2)],
  products: [
    .executable(name: "benchmark", targets: ["benchmark"]),
    .executable(name: "memory-benchmark", targets: ["memory-benchmark"]),
  ],
  dependencies: [
    .package(name: "swift-collections", path: ".."),
    .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.4"),
  ],
  targets: [
    .target(
      name: "Benchmarks",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
        "CppBenchmarks",
      ]
    ),
    .target(
      name: "CppBenchmarks"
    ),
    .executableTarget(
      name: "benchmark",
      dependencies: [
        "Benchmarks",
      ],
      path: "Sources/benchmark-tool"
    ),
    .executableTarget(
      name: "memory-benchmark",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
      ]
    ),
  ],
  cxxLanguageStandard: .cxx17
)
