# Swift Collections

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

Read more about the package, and the intent behind it, in the [announcement on swift.org][announcement].

[announcement]: https://swift.org/blog/swift-collections

## Contents

The package currently provides the following implementations:

- [`Deque<Element>`][Deque], a double-ended queue backed by a ring buffer. Deques are range-replaceable, mutable, random-access collections.

- [`OrderedSet<Element>`][OrderedSet], a variant of the standard `Set` where the order of items is well-defined and items can be arbitrarily reordered. Uses a `ContiguousArray` as its backing store, augmented by a separate hash table of bit packed offsets into it.

- [`OrderedDictionary<Key, Value>`][OrderedDictionary], an ordered variant of the standard `Dictionary`, providing similar benefits.

[Deque]: Documentation/Deque.md
[OrderedSet]: Documentation/OrderedSet.md
[OrderedDictionary]: Documentation/OrderedDictionary.md

Swift Collections uses the same modularization approach as [**Swift Numerics**](https://github.com/apple/swift-numerics): it provides a standalone module for each thematic group of data structures it implements. For instance, if you only need a double-ended queue type, you can pull in only that by importing `DequeModule`. `OrderedSet` and `OrderedDictionary` share much of the same underlying implementation, so they are provided by a single module, called `OrderedCollections`. However, there is also a top-level `Collections` module that gives you every collection type with a single import statement:

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

The public API of version 1.0 of the `swift-collections` package consists of non-underscored declarations that are marked `public` in the `Collections`, `DequeModule` and `OrderedCollections` modules.

Interfaces that aren't part of the public API may continue to change in any release, including patch releases. 
If you have a use case that requires using underscored APIs, please [submit a Feature Request][enhancement] describing it! We'd like the public interface to be as useful as possible -- although preferably without compromising safety or limiting future evolution.

By "underscored declarations" we mean declarations that have a leading underscore anywhere in their fully qualified name. For instance, here are some names that wouldn't be considered part of the public API, even if they were technically marked public:

- `FooModule.Bar._someMember(value:)` (underscored member)
- `FooModule._Bar.someMember` (underscored type)
- `_FooModule.Bar` (underscored module)
- `FooModule.Bar.init(_value:)` (underscored initializer)

Note that contents of the `Tests`, `Utils` and `Benchmarks` subdirectories aren't public API. We don't make any source compatibility promises about them -- they may change at whim, and code may be removed in any new release. Do not rely on anything about them. 

Future minor versions of the package may update these rules as needed.

We'd like this package to quickly embrace Swift language and toolchain improvements that are relevant to its mandate. Accordingly, from time to time, we expect that new versions of this package will require clients to upgrade to a more recent Swift toolchain release. (This allows the package to make use of new language/stdlib features, build on compiler bug fixes, and adopt new package manager functionality as soon as they are available.) Requiring a new Swift release will only need a minor version bump.

## Using **Swift Collections** in your project

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-collections.git", 
      .upToNextMajor(from: "1.0.0") // or `.upToNextMinor
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

### Working on the package

We have some basic [documentation on package internals](./Documentation/Development/Internals/) that will help you get started.

By submitting a pull request, you represent that you have the right to license your contribution to Apple and the community, and agree by submitting the patch that your contributions are licensed under the [Swift License](https://swift.org/LICENSE.txt), a copy of which is [provided in this repository](LICENSE.txt).

#### Fixing a bug or making a small improvement

1. [Submit a PR][PR] with your change. If there is an [existing issue][issues] for the bug you're fixing, please include a reference to it.
2. Make sure to add tests covering whatever changes you are making.

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

1. Start a topic on the [forum], explaining why you believe it would be important to implement the data structure. This way we can figure out if it would be right for the package, discuss implementation strategies, and plan to allocate capacity to help.
2. When maintainers agreed to your implementation plan, start work on it, and submit a PR with your implementation as soon as you have something that's ready to show! We'd love to get involved as early as you like.
3. Participate in the review discussion, and adapt the code accordingly. Sometimes we may need to go through several revisions! This is fine -- it makes the end result that much better.
3. When there is a consensus that the feature is ready, and the implementation is fully tested and documented, the PR will be merged by a maintainer.
4. Celebrate! You've achieved something great!

### Code of Conduct

Like all Swift.org projects, we would like the Swift Collections project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md

### Contact information

The current code owner of this package is Karoy Lorentey ([@lorentey](https://github.com/lorentey)). You can contact him [on the Swift forums](https://forums.swift.org/u/lorentey/summary), or by writing an email to klorentey at apple dot com. (Please keep it related to this project.)

In case of moderation issues, you can also directly contact a member of the [Swift Core Team](https://swift.org/community/#community-structure).

