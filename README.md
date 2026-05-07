# Swift Collections

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-collections%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/apple/swift-collections) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-collections%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/apple/swift-collections)

## Table of Contents

  * [Stable Data Structures](#stable-data-structures)
      * [`BasicContainers` module](#basiccontainers-module)
      * [`DequeModule` module](#dequemodule-module)
      * [`OrderedCollections` module](#orderedcollections-module)
      * [`BitCollections` module](#bitcollections-module)
      * [`HeapModule` module](#heapmodule-module)
      * [`HashTreeCollections` module](#hashtreecollections-module)
      * [`TrailingElementsModule` module](#trailingelementsmodule-module)
      * [`ContainersPreview` module](#containerspreview-module)
      * [`Collections` module](#collections-module)
  * [Experimental Features](#experimental-features)
    * [`UnstableContainersPreview` package trait](#unstablecontainerspreview-package-trait)
    * [`UnstableHashedContainers` package trait](#unstablehashedcontainers-package-trait)
    * [`UnstableSortedCollections` package trait](#unstablesortedcollections-package-trait)
  * [Project Status](#project-status)
    * [Definition of Public API](#public-api)
    * [Minimum Required Swift Toolchain Version](#minimum-required-swift-toolchain-version)
  * [Using <strong>Swift Collections</strong> in your project](#using-swift-collections-in-your-project)
  * [Contributing to Swift Collections](#contributing-to-swift-collections)
    * [Branching Strategy](#branching-strategy)
    * [Working on the package](#working-on-the-package)
      * [Fixing a bug or making a small improvement](#fixing-a-bug-or-making-a-small-improvement)
      * [Proposing a small enhancement](#proposing-a-small-enhancement)
      * [Proposing the addition of a new data structure](#proposing-the-addition-of-a-new-data-structure)
  * [Code of Conduct](#code-of-conduct)
  * [Contact information](#contact-information)


## Stable Data Structures

The package currently provides the following types, organized into thematic modules:

#### [`BasicContainers`][BasicContainers] module

Ownership-aware reimplementations of the standard generic collection types `Array`, `Set`, and `Dictionary`.

- [`struct UniqueArray<Element>`][UniqueArray] is a uniquely held, dynamically resizing array.
- [`struct RigidArray<Element>`][RigidArray] is a fixed-capacity array.

[BasicContainers]: https://swiftpackageindex.com/apple/swift-collections/documentation/basiccontainers
[RigidArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/basiccontainers/rigidarray
[UniqueArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/basiccontainers/uniquearray

#### [`DequeModule`][DequeModule] module

Implementations of double-ended queue types, implemented by a ring buffer.

- [`struct Deque<Element>`][Deque] is a classic collection, implementing value semantics with the copy-on-write optimization.
- [`struct UniqueDeque<Element>`][UniqueDeque] is a uniquely held, dynamically resizing, noncopyable deque.
- [`struct RigidDeque<Element>`][RigidDeque] is a fixed-capacity deque implementation.

[DequeModule]: https://swiftpackageindex.com/apple/swift-collections/documentation/dequemodule
[Deque]: https://swiftpackageindex.com/apple/swift-collections/documentation/dequemodule/deque
[RigidDeque]: https://swiftpackageindex.com/apple/swift-collections/documentation/dequemodule/rigiddeque
[UniqueDeque]: https://swiftpackageindex.com/apple/swift-collections/documentation/dequemodule/uniquedeque

#### [`OrderedCollections`][OrderedCollections] module

Provides variants of the standard `Set` and `Dictionary` types with user-defined ordering.

- [`struct OrderedSet<Element>`][OrderedSet] is a `Set` that preserves insertion order.
- [`struct OrderedDictionary<Key, Value>`][OrderedDictionary] is a `Dictionary` that preserves insertion order.

[OrderedCollections]: https://swiftpackageindex.com/apple/swift-collections/documentation/orderedcollections
[OrderedSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/orderedcollections/orderedset
[OrderedDictionary]: https://swiftpackageindex.com/apple/swift-collections/documentation/orderedcollections/ordereddictionary

#### [`BitCollections`][BitCollections] module

Provides efficient implementations of bit maps.

- [`struct BitSet`][BitSet] is a more efficient implementation of `Set<Int>`.
- [`struct BitArray`][BitArray] is a more efficient implementation of `Array<Bool>`.

[BitCollections]: https://swiftpackageindex.com/apple/swift-collections/documentation/bitcollections
[BitSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/bitcollections/bitset
[BitArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/bitcollections/bitarray

#### [`HeapModule`][HeapModule] module

- [`struct Heap<Element>`][Heap], a min-max heap backed by an array, suitable for use as a priority queue.

[HeapModule]: https://swiftpackageindex.com/apple/swift-collections/documentation/heapmodule
[Heap]: https://swiftpackageindex.com/apple/swift-collections/documentation/heapmodule/heap

#### [`HashTreeCollections`][HashTreeCollections] module

Persistent hashed collections implementing Compressed Hash-Array Mapped Prefix Trees (CHAMP). These are like `Set` and `Dictionary`, but they can efficiently mutate shared copies.

   - [`struct TreeSet<Element>`][TreeSet] is a persistent hashed set.
   - [`struct TreeDictionary<Key, Value>`][TreeDictionary] is a persistent hashed dictionary.

[HashTreeCollections]: https://swiftpackageindex.com/apple/swift-collections/documentation/hashtreecollections
[TreeSet]: https://swiftpackageindex.com/apple/swift-collections/documentation/hashtreecollections/treeset
[TreeDictionary]: https://swiftpackageindex.com/apple/swift-collections/documentation/hashtreecollections/treedictionary

#### [`TrailingElementsModule`][TrailingElementsModule] module

- [`struct TrailingArray`][TrailingArray], a low-level, ownership-aware variant of `ManagedBuffer`, for interoperability with C constructs that consist of a fixed-size header directly followed by variable-size storage buffer.
- [`protocol TrailingElements`][TrailingElements]
- [`struct TrailingPadding<Header>`][TrailingPadding]

[TrailingElementsModule]: https://swiftpackageindex.com/apple/swift-collections/documentation/trailingelementsmodule
[TrailingArray]: https://swiftpackageindex.com/apple/swift-collections/documentation/trailingelementsmodule/trailingarray
[TrailingElements]: https://swiftpackageindex.com/apple/swift-collections/documentation/trailingelementsmodule/trailingelements
[TrailingPadding]: https://swiftpackageindex.com/apple/swift-collections/documentation/trailingelementsmodule/trailingpadding

#### [`ContainersPreview`][ContainersPreview] module

An experimental preview of an ownership-aware container model in Swift.

- [`struct UniqueBox<Value>`][UniqueBox] is a heap-allocated noncopyable wrapper for an arbitrary value.

[ContainersPreview]: https://swiftpackageindex.com/apple/swift-collections/documentation/containerspreview
[UniqueBox]: https://swiftpackageindex.com/apple/swift-collections/documentation/containerspreview/uniquebox

#### [`Collections`][CollectionsModule] module

Exposes the most commonly used collection types with a single import statement:

- [`struct BitArray`][BitArray] from `BitCollections`
- [`struct BitSet`][BitSet] from `BitCollections`
- [`struct Deque<Element>`][Deque] from `DequeModule`
- [`struct Heap<Element>`][Heap] from `HeapModule`
- [`struct OrderedSet<Element>`][OrderedSet] from `OrderedCollections`
- [`struct OrderedDictionary<Key, Value>`][OrderedDictionary] from `OrderedCollections`
- [`struct TreeSet<Element>`][TreeSet] from `HashTreeCollections`
- [`struct TreeDictionary<Element>`][TreeDictionary] from `HashTreeCollections`

[CollectionsModule]: https://swiftpackageindex.com/apple/swift-collections/documentation/collections

## Experimental Features

The package also includes previews of features that aren't ready to be declared source stable yet. This includes prototypes of basic abstractions that belong in the Swift Standard Library, as well as concrete data structures that aren't ready for production use yet -- either because they depend on unreleased language/stdlib improvements, or because they still have known API or implementation issues.

These features are disabled by default. The package provides several package traits to allow intrepid early adopters to selectively opt into using them, to validate potential use cases. All APIs and behavior that these traits enable are highly experimental, and completely unstable -- they can (and often will!) change in incompatible ways or they may even get removed with no advance notice, in any new release of the package (including patch releases).

### `UnstableContainersPreview` package trait

This trait enables the following types in the [`ContainersPreview`][ContainersPreview] module:

- [`struct InputSpan<Element>`][InputSpan] is a reference to a contiguous region of consumable items.
- [`struct Ref<Target>`][Ref] represents a borrowing reference to an item.
- [`struct MutableRef<Target>`][MutableRef] represents a mutating reference to an item.

- [`protocol BorrowingSequence<Element>`][BorrowingSequence] models borrowing sequences with ephemeral lifetimes.
- [`protocol BorrowingIteratorProtocol<Element>`][BorrowingIteratorProtocol] models borrowing iterators with ephemeral elements.
- [`protocol Container<Element>`][Container] models containers, or constructs that physically store their contents.
- [`protocol BidirectionalContainer<Element>`][BidirectionalContainer] is the container analogue of `BidirectionalCollection`.
- [`protocol RandomAccessContainer<Element>`][RandomAccessContainer] is the container analogue of `RandomAccessCollection`.
- [`protocol PermutableContainer<Element>`][PermutableContainer] models a container that allows items to be arbitrarily reordered (sorted, reversed, etc).
- [`protocol MutableContainer<Element>`][MutableContainer] refines `PermutableContainer` to also support arbitrary element replacements/mutations, like `MutableCollection`.
- [`protocol RangeReplaceableContainer<Element>`][RangeReplaceableContainer] models a (potentially fixed capacity) container with insert/append/replace operations.
- [`protocol DynamicContainer<Element>`][DynamicContainer] refines `RangeReplaceableContainer` to add operations that require dynamic storage sizing.
- [`protocol Producer<Element, Failure>`][Producer] models a generative iterator -- an abstraction for producing items on demand.
- [`protocol Drain<Element>`][Drain] refines `Producer` to model an in-place consumable elements -- primarily for use around container types.

[InputSpan]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Types/InputSpan.swift
[Ref]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Types/Ref.swift
[MutableRef]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Types/MutableRef.swift
[BorrowingSequence]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/BorrowingSequence.swift
[BorrowingIteratorProtocol]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/BorrowingIteratorProtocol.swift
[Container]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/Container.swift
[BidirectionalContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/Container.swift
[RandomAccessContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/RandomAccessContainer.swift
[PermutableContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/PermutableContainer.swift
[MutableContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/MutableContainer.swift
[RangeReplaceableContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/RangeReplaceableContainer.swift
[DynamicContainer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Container/DynamicContainer.swift
[Producer]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Producer.swift
[Drain]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Protocols/Drain.swift

The trait also enables a large list of new APIs throughout the package that make use of these constructs -- such as generic methods for transferring items between container types, and implementations of the classic `map`/`reduce`/`filter`/etc algorithms.

These constructs are previews of potential stdlib additions. As of March 2026, some of these are already making their way through the Swift Evolution process; others are still unfinished and highly experimental. These need to remain unstable, as we expect that (as usual) these construct will see some API breaking changes on their way to the stdlib; additionally, they will likely need to be removed from the package entirely once they are fully adopted into the Standard Library. (It would not be feasible to maintain two distinct versions of universal library primitives, or basic protocols / generic algorithms.)

### `UnstableHashedContainers` package trait

This trait enables the following hashed containers in the [`BasicContainers`][BasicContainers] module:

- [`struct UniqueSet<Element>`][UniqueSet] is a uniquely held, dynamically resizing set.
- [`struct RigidSet<Element>`][RigidSet] is a fixed-capacity set.
- [`struct UniqueDictionary<Key, Value>`][UniqueDictionary] is a uniquely held, dynamically resizing dictionary.
- [`struct RigidDictionary<Key, Value>`][RigidDictionary] is a fixed-capacity dictionary.

[RigidSet]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/RigidSet
[UniqueSet]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/UniqueSet
[RigidDictionary]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/RigidDictionary
[UniqueDictionary]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/UniqueDictionary

The set types support noncopyable members, while the dictionary types support noncopyable keys and values. (Of course, they can also be used with copyable types.)

Under the hood, these containers implement Robin Hood hashing, achieving better memory utilization and more consistent lookup performance when compared to the standard `Set` and `Dictionary` types.

These types need to remain unstable for now, as they depend on compiler/stdlib features that have not shipped yet. Additionally, we may need to tweak their API as we gain more experience with using them.

### `UnstableSortedCollections` package trait

This trait enables the following types in the `SortedCollections` module:

- [`struct SortedSet<Element>`][SortedSet] is a set type that requires its element to be `Comparable`, and keeps its members sorted in strictly increasing order.
- [`struct SortedDictionary<Element>`][SortedDictionary] is a dictionary type that always keeps its keys sorted in strictly increasing order.

[SortedSet]: https://github.com/apple/swift-collections/tree/main/Sources/SortedCollections/SortedSet
[SortedDictionary]: https://github.com/apple/swift-collections/tree/main/Sources/SortedCollections/SortedDictionary

These constructs are based around an in-memory B-tree implementation.

They remain unstable for now because they have known API deficiencies -- we expect many of their interfaces will need to be adjusted in source breaking ways.

## Project Status

The Swift Collections package is source stable. The version numbers follow [Semantic Versioning][semver] -- source breaking changes to public API can only land in a new major version.

[semver]: https://semver.org

### Definition of Public API

The public API of version 1.4 of the `swift-collections` package consists of non-underscored declarations that are marked `public` in the `Collections`, `BasicContainers`, `BitCollections`, `DequeModule`, `HeapModule`, `OrderedCollections`, and `HashTreeCollections` modules.

Interfaces that aren't part of the public API may continue to change in any release, including patch releases.

By "underscored declarations" we mean declarations that have a leading underscore anywhere in their fully qualified name. For instance, here are some names that wouldn't be considered part of the public API, even if they were technically marked public:

- `FooModule.Bar._someMember(value:)` (underscored member)
- `FooModule._Bar.someMember` (underscored type)
- `_FooModule.Bar` (underscored module)
- `FooModule.Bar.init(_value:)` (underscored initializer)

Interfaces that get enabled by opting into the `UnstableContainersPreview`, `UnstableSortedCollections`, or `UnstableHashedContainers` package traits are not part of the public API; those interfaces may get removed or changed in any release.

(Note: the list of stable modules above intentionally does not include `ContainersPreview`, `SortedCollections`, nor `_RopeModule` -- these experimental modules are unstable and need more time in the oven before they can become public API.)

If you have a use case that requires using underscored (or otherwise non-public) APIs, please [submit a Feature Request][enhancement] describing it! We'd like the public interface to be as useful as possible -- although preferably without compromising safety or limiting future evolution.

This source compatibility promise only applies to swift-collections when built as a Swift package. The repository also contains unstable configurations for building swift-collections using CMake and Xcode. These configurations are provided for internal Swift project use only -- such as for building the (private) swift-collections binaries that ship within Swift toolchains. As such, they are unstable and may arbitrarily change (including wholesale removal) in any swift-collections release.

The files in the `Tests`, `Utils`, `Documentation`, `Xcode`, `cmake`, and `Benchmarks` subdirectories may change at whim; they may get added, modified, or removed in any new release. Do not rely on anything about them.

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
| swift-collections 1.4.x | >= Swift 6.0.3  | >= Xcode 16.2 |

We make an effort to ensure that each new minor package version supports the most recent three major Swift versions at the time of its release.

(Note: the package has no minimum deployment target, so while it does require clients to use a recent Swift toolchain to build it, the code itself is able to run on any OS release that supports running Swift code.)

Select features may require a more recent compiler than the minimum specified above. (For example, `RigidArray` only works on Swift 6.2 or better.)

## Using **Swift Collections** in your project

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version:6.3
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-collections.git",
      .upToNextMinor(from: "1.4.0") // or `.upToNextMajor`
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
| swift-collections 1.2.x | release/1.2 | Obsolete |
| swift-collections 1.3.x | release/1.3 | Bugfixes only |
| swift-collections 1.4.x | release/1.4 | Bugfixes only |
| n.a.                    | main        | Feature work towards next minor release |

Changes must land on the branch corresponding to the earliest release that they will need to ship on. They are periodically propagated to subsequent branches, in the following direction:

`release/1.3` → `release/1.4` → `main`

For example, anything landing on `release/1.3` will eventually appear on `release/1.4` and then `main` too; there is no need to file standalone PRs for each release line. Change propagation is not instantaneous, as it currently requires manual work -- it is performed by project maintainers.

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
2. Submit a PR with your implementation, and participate in the review discussion.
3. When there is a consensus that the feature is desirable, and the implementation works well, it is fully tested and documented, then it will be merged.
4. Rejoice!

[enhancement]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=enhancement&template=FEATURE_REQUEST.md

#### Proposing the addition of a new data structure

**Note:** We are currently fully preoccupied with refactoring our existing data structures to support noncopyable and/or nonescapable element types; this includes designing new container protocols around them. I don't expect we'll have capacity to work on any major new data structure implementations until this effort is complete.

## Code of Conduct

Like all Swift.org projects, we would like the Swift Collections project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md

## Contact information

The current code owner of this package is Karoy Lorentey ([@lorentey](https://github.com/lorentey)). You can contact him [on the Swift forums](https://forums.swift.org/u/lorentey/summary), or by writing an email to klorentey at apple dot com. (Please keep it related to this project.)

In case of moderation issues, you can also directly contact a member of the [Swift Core Team](https://swift.org/community/#community-structure).
