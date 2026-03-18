// swift-tools-version:6.2
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import PackageDescription

let _traits: Set<Trait> = [
  .default(
    enabledTraits: [
    ]
  ),
  .trait(
    name: "EnableRustBenchmarks",
    description: """
      Enables building and running benchmarks written in Rust, for comparative analysis.
      """),
]

let availabilityMacros: KeyValuePairs<String, String> = [
  "SwiftStdlib 5.0":  "macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2",
  "SwiftStdlib 5.1":  "macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0",
  "SwiftStdlib 5.6":  "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4",
  "SwiftStdlib 5.8":  "macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4",
  "SwiftStdlib 5.9":  "macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0",
  "SwiftStdlib 5.10": "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.1",
  "SwiftStdlib 6.0":  "macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0",
  "SwiftStdlib 6.1":  "macOS 15.4, iOS 18.4, watchOS 11.4, tvOS 18.4, visionOS 2.4",
  "SwiftStdlib 6.2":  "macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0",
  "SwiftStdlib 6.3":  "macOS 26.4, iOS 26.4, watchOS 26.4, tvOS 26.4, visionOS 26.4",
]

let _sharedSettings: [SwiftSetting] = (
  availabilityMacros.map { name, value in
      .enableExperimentalFeature("AvailabilityMacro=\(name): \(value)")
  } +
    [
      .enableExperimentalFeature("Extern", .when(traits: ["EnableRustBenchmarks"])),
      .define("ENABLE_RUST_BENCHMARKS", .when(traits: ["EnableRustBenchmarks"])),
    ]
)

let package = Package(
  name: "swift-collections.Benchmarks",
  platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11), .tvOS(.v18), .visionOS(.v2)],
  products: [
    .executable(name: "benchmark", targets: ["benchmark"]),
    .executable(name: "memory-benchmark", targets: ["memory-benchmark"]),
  ],
  traits: _traits,
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
        .target(name: "RustBenchmarks", condition: .when(traits: ["EnableRustBenchmarks"])),
      ],
      swiftSettings: _sharedSettings
    ),
    .target(
      name: "CppBenchmarks",
      swiftSettings: _sharedSettings
    ),
    .plugin(
      name: "RustBuild",
      capability: .buildTool()
    ),
    .target(
      name: "RustBenchmarks",
      swiftSettings: _sharedSettings,
      plugins: [
        .plugin(name: "RustBuild")
      ]
    ),
    .executableTarget(
      name: "benchmark",
      dependencies: [
        "Benchmarks",
      ],
      path: "Sources/benchmark-tool",
      swiftSettings: _sharedSettings,
      linkerSettings: [
        .unsafeFlags(
          [
            "-L\(Context.packageDirectory)/.build/plugins/outputs/benchmarks/RustBenchmarks/destination/RustBuild",
            "-lRustBenchmarks"
          ],
          .when(traits: ["EnableRustBenchmarks"])
        ),

      ],
    ),
    .executableTarget(
      name: "memory-benchmark",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
      ],
      swiftSettings: _sharedSettings
    ),
  ],
  cxxLanguageStandard: .cxx17
)
