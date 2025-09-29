// swift-tools-version:6.2
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

#if false // FIXME: Disabled while we're debugging a runtime crash (rdar://150240032)
let _traits: Set<Trait> = [
  .default(
    enabledTraits: [
      //"UnstableContainersPreview"
    ]),
  .trait(
    name: "UnstableContainersPreview",
    description: """
      Enables source-unstable components of the ContainersPreview module in
      swift-collections. This allows experimental use of the Container
      protocols and associated algorithms.
      """),
]
#endif

// This package recognizes the conditional compilation flags listed below.
// To use enable them, uncomment the corresponding lines or define them
// from the package manager command line:
//
//     swift build -Xswiftc -DCOLLECTIONS_INTERNAL_CHECKS
var defines: [SwiftSetting] = [
//  .define(
//    "COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW",
//    .when(traits: ["UnstableContainersPreview"])),

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

  // Enables randomized testing of some data structure implementations.
  .define("COLLECTIONS_RANDOMIZED_TESTING"),

  // Enable this to build the sources as a single, large module.
  // This removes the distinct modules for each data structure, instead
  // putting them all directly into the `Collections` module.
  // Note: This is a source-incompatible variation of the default configuration.
//  "COLLECTIONS_SINGLE_MODULE",
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
  // Note: if you touch these, please make sure to also update the similar lists in
  // CMakeLists.txt and Xcode/Shared.xcconfig.
]

let extraSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility"),
//  .strictMemorySafety(),
  .enableExperimentalFeature("BuiltinModule"),
  .enableExperimentalFeature("Lifetimes"),
  .enableExperimentalFeature("InoutLifetimeDependence"),
  .enableExperimentalFeature("SuppressedAssociatedTypes"),
//  .enableExperimentalFeature("AddressableParameters"),
//  .enableExperimentalFeature("AddressableTypes"),

  // Note: if you touch these, please make sure to also update the similar lists in
  // CMakeLists.txt and Xcode/Shared.xcconfig.
]

let _sharedSettings: [SwiftSetting] = (
  defines
  + availabilityMacros.map { name, value in
      .enableExperimentalFeature("AvailabilityMacro=\(name): \(value)")
  }
  + extraSettings
)

let _settings: [SwiftSetting] = _sharedSettings + []
let _testSettings: [SwiftSetting] = _sharedSettings + []

struct CustomTarget {
  enum Kind {
    case exported
    case hidden
    case test
    case testSupport
  }

  var kind: Kind
  var name: String
  var dependencies: [Target.Dependency]
  var directory: String
  var exclude: [String]
  var sources: [String]?
  var settings: [SwiftSetting]
}

extension CustomTarget.Kind {
  func path(for name: String) -> String {
    switch self {
    case .exported, .hidden: return "Sources/\(name)"
    case .test, .testSupport: return "Tests/\(name)"
    }
  }

  var isTest: Bool {
    switch self {
    case .exported, .hidden: return false
    case .test, .testSupport: return true
    }
  }
}

extension CustomTarget {
  static func target(
    kind: Kind,
    name: String,
    dependencies: [Target.Dependency] = [],
    directory: String? = nil,
    exclude: [String] = [],
    sources: [String]? = nil,
    settings: [SwiftSetting]? = nil
  ) -> CustomTarget {
    CustomTarget(
      kind: kind,
      name: name,
      dependencies: dependencies,
      directory: directory ?? name,
      exclude: exclude,
      sources: sources,
      settings: settings ?? (kind.isTest ? _testSettings : _settings))
  }

  func toTarget() -> Target {
    var linkerSettings: [LinkerSetting] = []
    if kind == .testSupport {
      linkerSettings.append(
        .linkedFramework("XCTest", .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])))
    }
    switch kind {
    case .exported, .hidden, .testSupport:
      return Target.target(
        name: name,
        dependencies: dependencies,
        path: kind.path(for: directory),
        exclude: exclude,
        sources: sources,
        swiftSettings: settings,
        linkerSettings: linkerSettings)
    case .test:
      return Target.testTarget(
        name: name,
        dependencies: dependencies,
        path: kind.path(for: directory),
        exclude: exclude,
        swiftSettings: settings,
        linkerSettings: linkerSettings)
    }
  }
}

let targets: [CustomTarget] = [
  .target(
    kind: .testSupport,
    name: "_CollectionsTestSupport",
    dependencies: [
      "InternalCollectionsUtilities",
      "ContainersPreview",
      "BasicContainers",
    ]),
  .target(
    kind: .test,
    name: "CollectionsTestSupportTests",
    dependencies: ["_CollectionsTestSupport"]),
  .target(
    kind: .hidden,
    name: "InternalCollectionsUtilities",
    exclude: [
      "CMakeLists.txt",
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
      "UnsafeRawBufferPointer+Extras.swift.gyb",
      "UnsafeMutableRawBufferPointer+Extras.swift.gyb",
      "LifetimeOverride.swift.gyb",
    ]),

  .target(
    kind: .exported,
    name: "BasicContainers",
    dependencies: [
      "InternalCollectionsUtilities",
      "ContainersPreview",
    ],
    exclude: ["CMakeLists.txt"]
  ),
  .target(
    kind: .test,
    name: "BasicContainersTests",
    dependencies: [
        "BasicContainers", "_CollectionsTestSupport"
    ]),

  .target(
    kind: .exported,
    name: "BitCollections",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "BitCollectionsTests",
    dependencies: [
      "BitCollections", "_CollectionsTestSupport", "OrderedCollections"
    ]),

  .target(
    kind: .exported,
    name: "ContainersPreview",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "ContainersTests",
    dependencies: [
      "ContainersPreview", "_CollectionsTestSupport"
    ]),

  .target(
    kind: .exported,
    name: "DequeModule",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "DequeTests",
    dependencies: ["DequeModule", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "HashTreeCollections",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "HashTreeCollectionsTests",
    dependencies: ["HashTreeCollections", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "HeapModule",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "HeapTests",
    dependencies: ["HeapModule", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "OrderedCollections",
    dependencies: ["InternalCollectionsUtilities"],
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "OrderedCollectionsTests",
    dependencies: ["OrderedCollections", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "_RopeModule",
    dependencies: ["InternalCollectionsUtilities"],
    directory: "RopeModule",
    exclude: ["CMakeLists.txt"],
    // FIXME: _modify accessors in RopeModule seem to be broken in Swift 6 mode
    settings: _sharedSettings + [.swiftLanguageMode(.v5)]),
  .target(
    kind: .test,
    name: "RopeModuleTests",
    dependencies: ["_RopeModule", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "TrailingElementsModule",
    exclude: ["CMakeLists.txt"]),
  .target(
    kind: .test,
    name: "TrailingElementsTests",
    dependencies: ["TrailingElementsModule"]),

  // These aren't ready for production use yet.
//  .target(
//    kind: .exported,
//    name: "SortedCollections",
//    dependencies: ["InternalCollectionsUtilities"],
//    directory: "SortedCollections"),
//  .target(
//    kind: .test,
//    name: "SortedCollectionsTests",
//    dependencies: ["SortedCollections", "_CollectionsTestSupport"]),

  .target(
    kind: .exported,
    name: "Collections",
    dependencies: [
      "BitCollections",
      "DequeModule",
      "HashTreeCollections",
      "HeapModule",
      "OrderedCollections",
      "_RopeModule",
    ],
    exclude: ["CMakeLists.txt"])
]

let _products: [Product] = targets.compactMap { t in
  guard t.kind == .exported else { return nil }
  return .library(name: t.name, targets: [t.name])
}
let _targets: [Target] = targets.map { $0.toTarget() }

let package = Package(
  name: "swift-collections",
  products: _products,
  traits: [], //_traits,
  targets: _targets
)
