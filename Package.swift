// swift-tools-version:5.5
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2023 Apple Inc. and the Swift project authors
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
var defines: [String] = [

  // Enables internal consistency checks at the end of initializers and
  // mutating operations. This can have very significant overhead, so enabling
  // this setting invalidates all documented performance guarantees.
  //
  // This is mostly useful while debugging an issue with the implementation of
  // the hash table itself. This setting should never be enabled in production
  // code.
//  "COLLECTIONS_INTERNAL_CHECKS",

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
//  "COLLECTIONS_DETERMINISTIC_HASHING",

  // Enables randomized testing of some data structure implementations.
  "COLLECTIONS_RANDOMIZED_TESTING",

  // Enable modules that aren't source stable yet, and aren't ready for general use.
//  "COLLECTIONS_ENABLE_UNSTABLE_MODULES",

  // Enable this to allow building the sources as a single, large module.
  // Note: this setting isn't a supported package configuration, but it's listed
  // here for completeness.
//  "COLLECTIONS_SINGLE_MODULE",
]

var _modules: [String] = []
var _products: [Product] = []
var _targets: [Target] = []
var _settings: [SwiftSetting] = defines.map { .define($0) }

func registerTargets(_ targets: [Target]) {
  _targets.append(contentsOf: targets)
}
func registerTargets(_ targets: Target...) { registerTargets(targets) }

func registerLibrary(_ module: String, _ targets: [Target]) {
  _modules.append(module)
  _products.append(.library(name: module, targets: [module]))
  registerTargets(targets)
}
func registerLibrary(_ module: String, _ targets: Target...) {
  registerLibrary(module, targets)
}

func registerUnstableLibrary(_ module: String, _ targets: Target...) {
  if defines.contains("COLLECTIONS_ENABLE_UNSTABLE_MODULES") {
    registerLibrary(module, targets)
  }
}

registerTargets(
  .target(
    name: "_CollectionsTestSupport",
    dependencies: ["_CollectionsUtilities"],
    swiftSettings: _settings,
    linkerSettings: [
      .linkedFramework(
        "XCTest",
        .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])),
    ]
  ),
  .testTarget(
    name: "CollectionsTestSupportTests",
    dependencies: ["_CollectionsTestSupport"],
    swiftSettings: _settings),

  .target(
    name: "_CollectionsUtilities",
    exclude: [
      "CMakeLists.txt",
      "Compatibility/Array+WithContiguousStorage Compatibility.swift.gyb",
      "Compatibility/UnsafeMutableBufferPointer+SE-0370.swift.gyb",
      "Compatibility/UnsafeMutablePointer+SE-0370.swift.gyb",
      "Compatibility/UnsafeRawPointer extensions.swift.gyb",
      "Debugging.swift.gyb",
      "Descriptions.swift.gyb",
      "IntegerTricks/FixedWidthInteger+roundUpToPowerOfTwo.swift.gyb",
      "IntegerTricks/Integer rank.swift.gyb",
      "IntegerTricks/UInt+first and last set bit.swift.gyb",
      "IntegerTricks/UInt+reversed.swift.gyb",
      "RandomAccessCollection+Offsets.swift.gyb",
      "UnsafeBitSet/_UnsafeBitSet+Index.swift.gyb",
      "UnsafeBitSet/_UnsafeBitSet+_Word.swift.gyb",
      "UnsafeBitSet/_UnsafeBitSet.swift.gyb",
      "UnsafeBufferPointer+Extras.swift.gyb",
      "UnsafeMutableBufferPointer+Extras.swift.gyb",
    ],
    swiftSettings: _settings)
)

registerLibrary(
  "BitCollections",
  .target(
    name: "BitCollections",
    dependencies: ["_CollectionsUtilities"],
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings),
  .testTarget(
    name: "BitCollectionsTests",
    dependencies: [
      "BitCollections", "_CollectionsTestSupport", "OrderedCollections"
    ],
    swiftSettings: _settings)
)

registerLibrary(
  "DequeModule",
  .target(
    name: "DequeModule",
    dependencies: ["_CollectionsUtilities"],
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings),
  .testTarget(
    name: "DequeTests",
    dependencies: ["DequeModule", "_CollectionsTestSupport"],
    swiftSettings: _settings)
)

registerLibrary(
  "HashTreeCollections",
  .target(
    name: "HashTreeCollections",
    dependencies: ["_CollectionsUtilities"],
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings),
  .testTarget(
    name: "HashTreeCollectionsTests",
    dependencies: ["HashTreeCollections", "_CollectionsTestSupport"],
    swiftSettings: _settings)
)

registerLibrary(
  "HeapModule",
  .target(
    name: "HeapModule",
    dependencies: ["_CollectionsUtilities"],
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings),
  .testTarget(
    name: "HeapTests",
    dependencies: ["HeapModule", "_CollectionsTestSupport"],
    swiftSettings: _settings)
)

registerLibrary(
  "OrderedCollections",
  .target(
    name: "OrderedCollections",
    dependencies: ["_CollectionsUtilities"],
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings),
  .testTarget(
    name: "OrderedCollectionsTests",
    dependencies: ["OrderedCollections", "_CollectionsTestSupport"],
    swiftSettings: _settings)
)

registerLibrary(
  "_RopeModule",
  .target(
    name: "_RopeModule",
    dependencies: ["_CollectionsUtilities"],
    path: "Sources/RopeModule",
    swiftSettings: _settings),
  .testTarget(
    name: "RopeModuleTests",
    dependencies: ["_RopeModule", "_CollectionsTestSupport"],
    swiftSettings: _settings)
)

registerLibrary(
  "Collections",
  .target(
    name: "Collections",
    dependencies: _modules.map { .target(name: $0) },
    exclude: ["CMakeLists.txt"],
    swiftSettings: _settings)
)

let package = Package(
  name: "swift-collections",
  products: _products,
  targets: _targets
)
