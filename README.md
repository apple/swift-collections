# Swift Collections

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

Read more about the package, and the intent behind it, in the [announcement on swift.org][announcement].

[announcement]: https://swift.org/blog/swift-collections

## Contents

The package currently provides the following implementations:

- [`BitSet`][BitSet] and [`BitArray`][BitArray], dynamic bit collections.

- [`Deque<Element>`][Deque], a double-ended queue backed by a ring buffer. Deques are range-replaceable, mutable, random-access collections.

- [`Heap`][Heap], a min-max heap backed by an array, suitable for use as a priority queue.

- [`OrderedSet<Element>`][OrderedSet], a variant of the standard `Set` where the order of items is well-defined and items can be arbitrarily reordered. Uses a `ContiguousArray` as its backing store, augmented by a separate hash table of bit packed offsets into it.

- [`OrderedDictionary<Key, Value>`][OrderedDictionary], an ordered variant of the standard `Dictionary`, providing similar benefits.

- [`TreeSet`][TreeSet] and [`TreeDictionary`][TreeDictionary], persistent hashed collections implementing Compressed Hash-Array Mapped Prefix Trees (CHAMP). These work similar to the standard `Set` and `Dictionary`, but they excel at use cases that mutate shared copies, offering dramatic memory savings and radical time improvements.

- [`UniqueArray`][UniqueArray] and [`RigidArray`][RigidArray], noncopyable array variants trading some of `Array`'s flexibility for more predictable performance.

- [`TrailingArray`][TrailingArray], a low-level, ownership-aware variant of `ManagedBuffer`, for interoperability with C constructs that consist of a fixed-size header directly followed by variable-size storage buffer.

[BitSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/bitcollections/bitset
[BitArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/bitcollections/bitarray
[Deque]: https://swiftpackageindex.com/apple/swift-collections/documentation/dequemodule/deque
[Heap]: https://swiftpackageindex.com/apple/swift-collections/documentation/heapmodule/heap
[OrderedSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/orderedcollections/orderedset
[OrderedDictionary]: https://swiftpackageindex.com/apple/swift-collections/documentation/orderedcollections/ordereddictionary
[TreeSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/hashtreecollections/treeset
[TreeDictionary]: https://swiftpackageindex.com/apple/swift-collections/documentation/hashtreecollections/treedictionary
[RigidArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/basiccontainers/rigidarray
[UniqueArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/basiccontainers/uniquearray
[TrailingArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/trailingelementsmodule/trailingarray

Swift Collections uses the same modularization approach as [**Swift Numerics**](https://github.com/apple/swift-numerics): it provides a standalone module for each thematic group of data structures it implements. For instance, if you only need a double-ended queue type, you can pull in only that by importing `DequeModule`. `OrderedSet` and `OrderedDictionary` share much of the same underlying implementation, so they are provided by a single module, called `OrderedCollections`. However, there is also a top-level `Collections` module that gives you the most commonly used collection types with a single import statement:

``` swift
import Collections

var deque: Deque<String> = ["Ted", "Rebecca"]
deque.prepend("Keeley")
deque.append("Nathan")
print(deque) // ["Keeley", "Ted", "Rebecca", "Nathan"]
```

## Project Status

The Swift Collections package is source stable. The version numbers follow [Semantic Versioning][semver] -- source breaking changes to public API can only land in a new major version.

[semver]: https://semver.org

### Public API

The public API of version 1.3 of the `swift-collections` package consists of non-underscored declarations that are marked `public` in the `Collections`, `BitCollections`, `DequeModule`, `HeapModule`, `OrderedCollections` and `HashTreeCollections` modules.

Interfaces that aren't part of the public API may continue to change in any release, including patch releases.

By "underscored declarations" we mean declarations that have a leading underscore anywhere in their fully qualified name. For instance, here are some names that wouldn't be considered part of the public API, even if they were technically marked public:

- `FooModule.Bar._someMember(value:)` (underscored member)
- `FooModule._Bar.someMember` (underscored type)
- `_FooModule.Bar` (underscored module)
- `FooModule.Bar.init(_value:)` (underscored initializer)

If you have a use case that requires using underscored (or otherwise non-public) APIs, please [submit a Feature Request][enhancement] describing it! We'd like the public interface to be as useful as possible -- although preferably without compromising safety or limiting future evolution.

This source compatibility promise only applies to swift-collection when built as a Swift package. (The repository also contains unstable configurations for building swift-collections using CMake and Xcode. These configurations are provided for internal Swift project use only -- such as for building the (private) swift-collections binaries that ship within Swift toolchains.)

Note that the files in the `Tests`, `Utils`, `Documentation`, `Xcode`, `cmake` and `Benchmarks` subdirectories may change at whim; they may be added, modified or removed in any new release. Do not rely on anything about them.

Future minor versions of the package may update these rules as needed.

### Minimum Required Swift Toolchain Version

We'd like this package to quickly embrace Swift language and toolchain improvements that are relevant to its mandate. Accordingly, from time to time, new versions of this package require clients to upgrade to a more recent Swift toolchain release. (This allows the package to make use of new language/stdlib features, build on compiler bug fixes, and adopt new package manager functionality as soon as they are available.) Patch (i.e., bugfix) releases will not increase the required toolchain version, but any minor (i.e., new feature) release may do so.

The following table maps package releases to their minimum required Swift toolchain release:

| Package version         | Swift version   | Xcode release |
| ----------------------- | --------------- | ------------- |
| swift-collections 1.0.x | >= Swift 5.3.2  | >= Xcode 12.4 |
| swift-collections 1.1.x | >= Swift 5.7.2  | >= Xcode 14.2 |
| swift-collections 1.2.x | >= Swift 5.10.0 | >= Xcode 15.3 |
| swift-collections 1.3.x | >= Swift 6.0.3  | >= Xcode 16.2 |

(Note: the package has no minimum deployment target, so while it does require clients to use a recent Swift toolchain to build it, the code itself is able to run on any OS release that supports running Swift code.)

## Using **Swift Collections** in your project

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-collections.git",
      .upToNextMinor(from: "1.3.0") // or `.upToNextMajor
    )
  ],
  targets: [
    .target(
      name: "MyTarget",
      dependencies: [
        .product(name: "Collections", package: "swift-collections")
      ]
    )
  ]
)
```

## Contributing to Swift Collections

We have a dedicated [Swift Collections Forum][forum] where people can ask and answer questions on how to use or work on this package. It's also a great place to discuss its evolution.

[forum]: https://forums.swift.org/c/related-projects/collections

If you find something that looks like a bug, please open a [Bug Report][bugreport]! Fill out as many details as you can.

### Branching Strategy

We maintain separate branches for each minor version of the package:

| Package version         | Branch      | Status   |
| ----------------------- | ----------- | -------- |
| swift-collections 1.0.x | release/1.0 | Obsolete |
| swift-collections 1.1.x | release/1.1 | Obsolete |
| swift-collections 1.2.x | release/1.2 | Bugfixes only |
| swift-collections 1.3.x | release/1.3 | Bugfixes only |
| n.a.                    | main        | Feature work towards next minor release |

Changes must land on the branch corresponding to the earliest release that they will need to ship on. They are periodically propagated to subsequent branches, in the following direction:

`release/1.1` → `release/1.2` → `release/1.3` → `main`

For example, anything landing on `release/1.2` will eventually appear on `release/1.3` and then `main` too; there is no need to file standalone PRs for each release line. Change propagation is not instantaneous, as it currently requires manual work -- it is performed by project maintainers.

### Working on the package

We have some basic [documentation on package internals](./Documentation/Internals/README.md) that will help you get started.

By submitting a pull request, you represent that you have the right to license your contribution to Apple and the community, and agree by submitting the patch that your contributions are licensed under the [Swift License](https://swift.org/LICENSE.txt), a copy of which is [provided in this repository](LICENSE.txt).

#### Fixing a bug or making a small improvement

1. Make sure to start by checking out the appropriate branch for the minor release you want the fix to ship in. (See above.)
2. [Submit a PR][PR] with your change. If there is an [existing issue][issues] for the bug you're fixing, please include a reference to it.
3. Make sure to add tests covering whatever changes you are making.

[PR]: https://github.com/apple/swift-collections/compare
[issues]: https://github.com/apple/swift-collections/issues

[bugreport]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=bug&template=BUG_REPORT.md

#### Proposing a small enhancement

1. Raise a [Feature Request][enhancement]. Discuss why it would be important to implement it.
2. Submit a PR with your implementation, participate in the review discussion.
3. When there is a consensus that the feature is desirable, and the implementation works well, it is fully tested and documented, then it will be merged.
4. Rejoice!

[enhancement]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=enhancement&template=FEATURE_REQUEST.md

#### Proposing the addition of a new data structure

**Note:** As of 2025, we are fully preoccupied with refactoring our existing data structures to support noncopyable and/or nonescapable element types; this includes designing new container protocols around them. I don't expect we'll have capacity to work on any major new data structure implementations until this effort is complete.

### Code of Conduct

Like all Swift.org projects, we would like the Swift Collections project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md

### Contact information

The current code owner of this package is Karoy Lorentey ([@lorentey](https://github.com/lorentey)). You can contact him [on the Swift forums](https://forums.swift.org/u/lorentey/summary), or by writing an email to klorentey at apple dot com. (Please keep it related to this project.)

In case of moderation issues, you can also directly contact a member of the [Swift Core Team](https://swift.org/community/#community-structure).
