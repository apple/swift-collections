// swift-tools-version:5.3
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

import PackageDescription

// This package recognizes the conditional compilation flags listed below.
// To use enable them, uncomment the corresponding lines or define them
// from the package manager command line:
//
//     swift build -Xswiftc -DCOLLECTIONS_INTERNAL_CHECKS
var settings: [SwiftSetting]? = [

  // Enables internal consistency checks at the end of initializers and
  // mutating operations. This can have very significant overhead, so enabling
  // this setting invalidates all documented performance guarantees.
  //
  // This is mostly useful while debugging an issue with the implementation of
  // the hash table itself. This setting should never be enabled in production
  // code.
//  .define("COLLECTIONS_INTERNAL_CHECKS"),

  // Hashing collections provided by this package usually seed their hash
  // function with the address of the memory location of their storage,
  // to prevent some common hash table merge/copy operations from regressing to
  // quadratic behavior. This setting turns off this mechanism, seeding
  // the hash function with the table's size instead.
  //
  // When used in conjunction with the SWIFT_DETERMINISTIC_HASHING environment
  // variable, this enables reproducible hashing behavior.
  //
  // This is mostly useful while debugging an issue with the implementation of
  // the hash table itself. This setting should never be enabled in production
  // code.
//  .define("COLLECTIONS_DETERMINISTIC_HASHING"),

]

// Prevent SPM 5.3 from throwing an error on empty settings arrays.
// (This has been fixed in 5.4.)
if settings?.isEmpty == true { settings = nil }

let package = Package(
  name: "swift-collections",
  products: [
    .library(name: "Collections", targets: ["Collections"]),
    .library(name: "DequeModule", targets: ["DequeModule"]),
    .library(name: "OrderedCollections", targets: ["OrderedCollections"]),
    .library(name: "PriorityQueue", targets: ["PriorityQueue"]),
  ],
  dependencies: [
    // This is only used in the benchmark executable target.
    .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.1"),
  ],
  targets: [
    .target(
      name: "Collections",
      dependencies: [
        "DequeModule",
        "OrderedCollections",
        "PriorityQueue",
      ],
      path: "Sources/Collections",
      exclude: ["CMakeLists.txt"],
      swiftSettings: settings),

    // Testing support module
    .target(
      name: "CollectionsTestSupport",
      dependencies: [],
      swiftSettings: settings,
      linkerSettings: [
        .linkedFramework(
          "XCTest",
          .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])),
      ]
    ),

    // Benchmarking
    .target(
      name: "Benchmarks",
      dependencies: [
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
        "CppBenchmarks",
        "Collections",
      ],
      path: "Benchmarks/Benchmarks",
      resources: [
        .copy("Library.json"),
      ]
    ),
    .target(
      name: "CppBenchmarks",
      path: "Benchmarks/CppBenchmarks"
    ),
    .target(
      name: "swift-collections-benchmark",
      dependencies: [
        "Benchmarks",
      ],
      path: "Benchmarks/swift-collections-benchmark"
    ),

    // Deque<Element>
    .target(
      name: "DequeModule",
      exclude: ["CMakeLists.txt"],
      swiftSettings: settings),
    .testTarget(
      name: "DequeTests",
      dependencies: ["DequeModule", "CollectionsTestSupport"],
      swiftSettings: settings),
    
    // PriorityQueue<Element>
    .target(
      name: "PriorityQueue",
      swiftSettings: settings),
    .testTarget(
      name: "PriorityQueueTests",
      dependencies: ["PriorityQueue", "CollectionsTestSupport"],
      swiftSettings: settings),
    
    
    // OrderedSet<Element>, OrderedDictionary<Key, Value>
    .target(
      name: "OrderedCollections",
      exclude: ["CMakeLists.txt"],
      swiftSettings: settings),
    .testTarget(
      name: "OrderedCollectionsTests",
      dependencies: ["OrderedCollections", "CollectionsTestSupport"],
      swiftSettings: settings),
  ],
  cxxLanguageStandard: .cxx1z
)
