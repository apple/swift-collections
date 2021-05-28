# Swift Collections

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

Read more about the package, and the intent behind it, in the [announcement on swift.org][announcement].

[announcement]: https://swift.org/blog/swift-collections

## Contents

The package currently provides the following implementations:

- [`Deque<Element>`][Deque], a double-ended queue backed by a ring buffer. Deques are range-replaceable, mutable, random-access collections.

- [`OrderedSet<Element>`][OrderedSet], a variant of the standard `Set` where the order of items is well-defined and items can be arbitrarily reordered. Uses a `ContiguousArray` as its backing store, augmented by a separate hash table of bit packed offsets into it.

- [`OrderedDictionary<Key, Value>`][OrderedDictionary], an ordered variant of the standard `Dictionary`, providing similar benefits.

- `PriorityQueue<Element>`, a queue whose elements are ordered by priority. This uses a `MinMaxHeap<Element>` as its backing store.

[Deque]: Documentation/Deque.md
[OrderedSet]: Documentation/OrderedSet.md
[OrderedDictionary]: Documentation/OrderedDictionary.md

Swift Collections uses the same modularization approach as [**Swift Numerics**](https://github.com/apple/swift-numerics): it provides a standalone module for each group of data structures it implements. For instance, if you only need a double-ended queue type, you can pull in only that by importing `DequeModule`. `OrderedSet` and `OrderedDictionary` share much of the same underlying implementation, so they are provided by a single module, called `OrderedCollections`.  However, there is also a top-level `Collections` module that gives you all of the included modules with a single import statement.

``` swift
import Collections

var deque: Deque<String> = ["Ted", "Rebecca"]
deque.prepend("Keeley")
deque.append("Nathan")
print(deque) // ["Keeley", "Ted", "Rebecca", "Nathan"]
```

## Project Status

We think the implementations in this package are robust, but the interfaces provided have not had time to stabilize. Accordingly, while the package is in its pre-1.0 state, from time to time new releases may sometimes include source-breaking changes. We'll try our best to keep such changes to a minimum, though, even during this chaotic initial period. Whenever feasible, we'll mitigate such changes with a multi-release deprecation period. 

Before the 1.0 release, releases containing potentially source-breaking changes will increase the middle version number. The release notes will explain what changed, and how to update your code to work with the new version.

The implementations in this package have gone through an initial performance optimization pass, but there are lots of work still to be done. Still, we think these implementations are already quite fast enough for production use -- sometimes matching or exceeding the performance of similar constructs in popular prexisting implementations in other languages.

### Underscored Interfaces

As customary in Swift, interfaces that are technically declared `public` but begin with an underscore are not considered part of the public interface of this package. We may remove or change them in any release without notice, including minor point releases. (If you have a use case that requires using them, please [submit a Feature Request][feature-request] describing it! We'd like the public interface to be as useful as possible -- preferably without compromising safety or limiting future evolution.)

[feature-request]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=enhancement&template=FEATURE_REQUEST.md

### Benchmarks

The package includes an extensive library of benchmarks in the [Benchmarks](./Benchmarks) directory, driven by a command-line executable target, `swift-collections-benchmark`. These benchmarks, the executable target, and its command-line interface are not considered part of the public interface of the package. As such, new releases may break them without any special ceremony. We do expect the benchmarks will stabilize with time.

For more information on our benchmarking tool, please see its dedicated package, [**Swift Collections Benchmark**][swift-collections-benchmark].

[swift-collections-benchmark]: https://github.com/apple/swift-collections-benchmark

### Test Support Library

The package comes with a rich test support library in the [Sources/CollectionsTestSupport](./Sources/CollectionsTestSupport) directory. These were loosely adapted from the contents of the `StdlibUnittest*` modules in the [Swift compiler repository](https://github.com/apple/swift/tree/main/stdlib/private), with some custom additions.

These components would likely be of interest to the wider Swift community, but they aren't yet stable enough (or documented enough) to publish them. Accordingly, these testing helpers are currently considered implementation details of this package, and are subject to change at whim.

The test support library currently provides the following functionality:

- [`AssertionContexts`](./Sources/CollectionsTestSupport/AssertionContexts): Custom test assertions with support for keeping track of nested context information, including stopping execution when the current context matches a particular value. (Useful for debugging combinatorial tests.)

  <details>
   <summary><strong>Click here for a short demonstration</strong></summary>

    ```swift
    import XCTest
    import CollectionsTestSupport

    final class DequeTests: CollectionTestCase {
      func test_demo() {
        let values = [0, 10, 20, 30, 42, 50, 60]
        for i in values.indices {
          context.withTrace("i: \(i)") {
            expectEqual(values[i], 10 * i)
          }
        }
      }
    }
    ```

    ```
    DemoTests.swift:21: error: -[DemoTests.DemoTests test_demo] : XCTAssertEqual failed: ("42") is not equal to ("40") - 
    Trace:
      - i: 4
    ```
    
    To debug issues, copy the trace message into a `context.failIfTraceMatches(_:)` invocation and set a breakpoint on test failures.
    
    ```swift
        let values = [0, 10, 20, 30, 42, 50, 60]
        for i in values.indices {
          context.withTrace("i: \(i)") {
            // This will report a test failure before executing the `i == 4` case,
            // letting us investigate what's going on.
            context.failIfTraceMatches("""
              Trace:
                - i: 4
              """)
            expectEqual(values[i], 10 * i)
          }
        }
    ```

    </details>

- [`Combinatorics`](./Sources/CollectionsTestSupport/AssertionContexts/Combinatorics.swift): Basic support for exhaustive combinatorial testing. This allows us to easily verify that a collection operation works correctly on all possible instances up to a certain size, including behavioral variations such as unique/shared storage.

  <details>
   <summary><strong>Click here for an example</strong></summary>

    ```swift
    func test_popFirst() {
      withEveryDeque("deque", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (deque, contents) = tracker.deque(with: layout)
            withHiddenCopies(if: isShared, of: &deque) { deque in
              let expected = contents[...].popFirst()
              let actual = deque.popFirst()
              expectEqual(actual, expected)
              expectEqualElements(deque, contents)
            }
          }
        }
      }
    }
    ```

  </details>

- [`ConformanceCheckers`](./Sources/CollectionsTestSupport/ConformanceCheckers): A set of generic, semi-automated protocol conformance tests for some Standard Library protocols. These can be used to easily validate the custom protocol conformances provided by this package. These checks aren't (can't be) complete -- but when used correctly, they are able to detect most accidental mistakes. 

    We currently have conformance checkers for the following protocols:
    
    - [`Sequence`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckSequence.swift)
    - [`Collection`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckCollection.swift)
    - [`BidirectionalCollection`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckBidirectionalCollection.swift)
    - [`Equatable`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckEquatable.swift)
    - [`Hashable`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckHashable.swift)
    - [`Comparable`](./Sources/CollectionsTestSupport/ConformanceCheckers/CheckComparable.swift)

- [`MinimalTypes`](./Sources/CollectionsTestSupport/MinimalTypes): Minimally conforming implementations for standard protocols. These types conform to various standard protocols by implementing the requirements in as narrow-minded way as possible -- sometimes going to extreme lengths to, say, implement collection index invalidation logic in the most unhelpful way possible.

    - [`MinimalSequence`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalSequence.swift)
    - [`MinimalCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalCollection.swift)
    - [`MinimalBidirectionalCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalBidirectionalCollection.swift)
    - [`MinimalRandomAccessCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalRandomAccessCollection.swift)
    - [`MinimalMutableRandomAccessCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalMutableRandomAccessCollection.swift)
    - [`MinimalRangeReplaceableRandomAccessCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalRangeReplaceableRandomAccessCollection.swift)
    - [`MinimalMutableRangeReplaceableRandomAccessCollection`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalMutableRangeReplaceableRandomAccessCollection.swift)
    - [`MinimalIterator`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalIterator.swift)
    - [`MinimalIndex`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalIndex.swift)
    - [`MinimalEncoder`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalEncoder.swift)
    - [`MinimalDecoder`](./Sources/CollectionsTestSupport/MinimalTypes/MinimalDecoder.swift)

- [`Utilities`](./Sources/CollectionsTestSupport/Utilities): Utility types. Wrapper types for boxed values, a simple deterministic random number generator, and a lifetime tracker for catching simple memory management issues such as memory leaks. (The [Address Sanitizer][asan] can be used to catch more serious problems.)

[asan]: https://developer.apple.com/documentation/xcode/diagnosing_memory_thread_and_crash_issues_early?language=objc


## Using **Swift Collections** in your project

To use this package in a SwiftPM project, add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/apple/swift-collections", from: "0.0.1"),
```

## Contributing to Swift Collections

### Asking questions

We have a dedicated [Swift Collections Forum][forum] where we can ask and answer questions on how to use or work on this package. It's also a great place to discuss its evolution.

[forum]: https://forums.swift.org/c/related-projects/collections

### Reporting a bug

If you find something that looks like a bug, please open a [Bug Report][bugreport]! Fill out as many details as you can.

### Fixing a bug or making a small improvement

1. [Submit a PR][PR] with your change. If there is an [existing issue][issues] for the bug you're fixing, please include a reference to it.
2. Make sure to add tests covering whatever changes you are making.

[PR]: https://github.com/apple/swift-collections/compare
[issues]: https://github.com/apple/swift-collections/issues

[bugreport]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=bug&template=BUG_REPORT.md

### Proposing a small enhancement

1. Raise a [Feature Request][enhancement]. Discuss why it would be important to implement it.
2. Submit a PR with your implementation, participate in the review discussion.
3. When there is a consensus that the feature is desirable, and the implementation works well, it is fully tested and documented, then it will be merged. 
4. Rejoice!

[enhancement]: https://github.com/apple/swift-collections/issues/new?assignees=&labels=enhancement&template=FEATURE_REQUEST.md

### Proposing the addition of a new data structure

1. Start a topic on the [forum], explaining why you believe it would be important to implement the data structure. This way we can figure out if it would be right for the package, discuss implementation strategies, and plan to allocate capacity to help.
2. When maintainers agreed to your implementation plan, start work on it, and submit a PR with your implementation as soon as you have something that's ready to show! We'd love to get involved as early as you like.
3. Participate in the review discussion, and adapt the code accordingly. Sometimes we may need to go through several revisions! This is fine -- it makes the end result that much better.
3. When there is a consensus that the feature is ready, and the implementation is fully tested and documented, the PR will be merged by a maintainer.
4. Celebrate! You've achieved something great!

### Licensing

By submitting a pull request, you represent that you have the right to license your contribution to Apple and the community, and agree by submitting the patch that your contributions are licensed under the [Swift License](https://swift.org/LICENSE.txt), a copy of which is [provided in this repository](LICENSE.txt).

### Code of Conduct

Like all Swift.org projects, we would like the Swift Collections project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md

### Contacting the maintainers

The current code owner of this package is Karoy Lorentey ([@lorentey](https://github.com/lorentey)). You can contact him [on the Swift forums](https://forums.swift.org/u/lorentey/summary), or by writing an email to klorentey at apple dot com. (Please keep it related to this project.)

In case of moderation issues, you can also directly contact a member of the [Swift Core Team](https://swift.org/community/#community-structure).

