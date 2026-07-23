# An Ownership-Aware Container Model for Swift

* Author: [Karoy Lorentey](https://github.com/lorentey)
* Version history:
   - 0.1 (2026-07-21): Initial draft, describing `Container`.
   - 0.2 (2026-07-22): Second draft, completing the chapter on the read-only container model.

## Table of Contents

  * [Introduction](#introduction)
  * [Making Sense of the Design Space](#making-sense-of-the-design-space)
    * ["Elementwise Iteration" vs "Bulk Iteration"](#elementwise-iteration-vs-bulk-iteration)
    * ["Iteration by Borrowing" vs "Iteration by Taking"](#iteration-by-borrowing-vs-iteration-by-taking)
    * ["Generative" vs "Visitative Iteration"](#generative-vs-visitative-iteration)
    * [Failability](#failability)
  * [A Read\-Only Container Model](#a-read-only-container-model)
    * [Counting Elements](#counting-elements)
    * [Container Indices](#container-indices)
    * [Visitative Iteration](#visitative-iteration)
    * [Default Implementations](#default-implementations)
    * [Subscripting](#subscripting)
    * [Interaction with Iterable](#interaction-with-iterable)
      * [ContainerIterator](#containeriterator)
      * [Conversions Between Indices and Iterators](#conversions-between-indices-and-iterators)
      * [Default Implementations of Iterable requirements](#default-implementations-of-iterable-requirements)
    * [Optional Lookup Hooks](#optional-lookup-hooks)
    * [Performance Requirements](#performance-requirements)
    * [The Full Container protocol](#the-full-container-protocol)
    * [Conforming to Container](#conforming-to-container)
    * [Bidirectional Containers](#bidirectional-containers)
    * [Random\-Access Containers](#random-access-containers)
  * [Mutable Containers](#mutable-containers)
    * [protocol PermutableContainer](#protocol-permutablecontainer)
    * [protocol MutableContainer](#protocol-mutablecontainer)
  * [Producers](#producers)
    * [Default Implementations on Producer](#default-implementations-on-producer)
  * [In\-Place Consumption](#in-place-consumption)
    * [struct InputSpan](#struct-inputspan)
    * [protocol Drain](#protocol-drain)
  * [Range\-Replaceable Containers](#range-replaceable-containers)
    * [Index Ranges and Range Expressions](#index-ranges-and-range-expressions)
    * [Adding Elements to a Container](#adding-elements-to-a-container)
    * [Replacing Subranges](#replacing-subranges)
    * [Consuming Subranges](#consuming-subranges)
    * [Removing Subranges](#removing-subranges)
    * [Dynamic Containers](#dynamic-containers)
  * [Rejected Directions](#rejected-directions)
    * [Cursors](#cursors)
    * [Index Rounding Operations](#index-rounding-operations)
  * [Potential Future Directions](#potential-future-directions)
    * [Support for Nonescapable Element Types](#support-for-nonescapable-element-types)
    * [Factoring Indexing Out of Containers](#factoring-indexing-out-of-containers)
    * [A Protocol for Directly Initializing Storage](#a-protocol-for-directly-initializing-storage)

## Introduction

Over the last several years, we've been [gradually][BorrowingConsuming] [building][NoncopyableTypes] [up][NoncopyableGenerics] [an][PartialConsumption] [ownership][PatternMatching] [model][NonescapableTypes] [for][SuppressedAssociatedTypes] [Swift][BorrowAndMutate], to simplify the creation of safe high-performance Swift code. Our goal is to fulfill Swift's mandate to become a high-performance systems programming language, suitable for use in all computing tasks, from the smallest microcontrollers to the largest supercomputers. As many of the target environments need to operate within strict performance constraints, developers who specialize in them expect to have precise, predictable control over runtime behavior, even at the cost of some coding flexibility.

[BorrowingConsuming]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md
[NoncopyableTypes]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md
[NoncopyableGenerics]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md
[PartialConsumption]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0429-partial-consumption.md
[PatternMatching]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0432-noncopyable-switch.md
[NonescapableTypes]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0446-non-escapable.md
[SuppressedAssociatedTypes]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0503-suppressed-associated-types.md
[BorrowAndMutate]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0507-borrow-accessors.md
[YieldingAccessors]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0474-yielding-accessors.md
[TypedThrows]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md

Crucially, Swift needs to satisfy this need without resorting to unsafe interfaces: our aim is to build constructs that can match (or exceed) the performance of legacy systems programming languages, while also avoiding undefined behavior if the interfaces get misused.

As of Swift 6.4, we have implemented a small but quickly growing list of useful data structures that follow these new design priorities:

- Members of the nonescapable span family provide safe, direct access to "somebody else's" contiguous pieces of memory.
  - [`Span`][Span], a read-only reference to fully initialized memory
  - [`MutableSpan`][MutableSpan], a mutable reference to fully initialized memory
  - [`OutputSpan`][OutputSpan], a safe reference to a fixed-capacity buffer of initializable memory
  - (in swift-collections) [`InputSpan`][InputSpan], a safe reference to a fixed-capacity buffer of consumable memory
- We also have ownership-aware implementations of some basic data structures.
    - [`InlineArray`][InlineArray] is a homogeneous tuple/vector type
    - [`UniqueArray`][UniqueArray] is a dynamically resizing array type
    - (in swift-collections) [`RigidArray`][RigidArray] is a fixed-capacity array type
    - (in swift-collections) [`RigidDeque`][RigidDeque] and [`UniqueDeque`][UniqueDeque] implement ring buffers
    - (in swift-collections) [`RigidSet`][RigidSet] and [`UniqueSet`][UniqueSet] are hashed sets of unique items
    - (in swift-collections) [`RigidDictionary`][RigidDictionary] and [`UniqueDictionary`][UniqueDictionary] are hashed dictionary types

[Span]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0447-span-access-shared-contiguous-storage.md
[InlineArray]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0453-vector.md
[MutableSpan]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0467-MutableSpan.md
[OutputSpan]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0485-outputspan.md
[Iterable]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0516-borrowing-sequence.md
[RefAndMutableRef]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0519-ref-mutableref-types.md
[UniqueArray]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0527-rigidarray-uniquearray.md
[InputSpan]: https://github.com/apple/swift-collections/blob/main/Sources/ContainersPreview/Types/InputSpan.swift
[RigidArray]: https://swiftpackageindex.com/apple/swift-collections/main/documentation/basiccontainers/rigidarray
[RigidSet]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/RigidSet
[UniqueSet]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/UniqueSet
[RigidDictionary]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/RigidDictionary
[UniqueDictionary]: https://github.com/apple/swift-collections/tree/main/Sources/BasicContainers/UniqueDictionary
[RigidDeque]: https://swiftpackageindex.com/apple/swift-collections/main/documentation/dequemodule/rigiddeque
[UniqueDeque]: https://swiftpackageindex.com/apple/swift-collections/main/documentation/dequemodule/uniquedeque

[BitSet]: https://swiftpackageindex.com/apple/swift-collections/main/documentation/bitcollections/bitset
[BitArray]: https://swiftpackageindex.com/apple/swift-collections/main/documentation/bitcollections/bitarray

At first glance, these types have the basic shape of a Swift `Collection`:

- They have a generic `Element` type
- They have the concept of an `Index`, modeling an abstract position within their storage
- They come with `subscript` operations that provide access to the element at a specific index
- They provide familiar operations for advancing an index to the next logical position, calculating distances between indices and similar tasks.

However, unlike `Collection`s, these types can contain noncopyable elements, and most of them are noncopyable and/or nonescapable types themselves. These are significant complications, as our classic `Collection` protocols have been built upon the assumption of universal copyability and escapability, and it isn't feasible to factor out these assumptions without breaking the protocols. (The `SubSequence` and `Indices` associated types are particularly problematic.)

## Making Sense of the Design Space

Swift 6.4 introduced [protocol `Iterable`][Iterable] to enable borrowing for-in loops over these new types. The new protocol made several notable choices in the design space of ownership-aware iteration; it is crucial that we identify them so that we can carefully examine the purpose and consequences of each one, and so that we are able to analyze alternative choices. Each specific choice defines a particular design axis; we'll give them names that reflect their purpose.

We do this not to criticize the design of `Iterable`, but to understand the use cases for which it is best suited, and to allow us to explore the full design space with intention. Identifying design axes allows us to derive a full set of potential abstractions almost mechanically, so that we can analyze them and develop the ones that seem most useful into concrete protocols in the rest of this document.

We list the four axes we are considering below. The rest of this introductory section will define each of these in detail, but their names already give us a hint of their purpose:

1. **Elementwise** versus **bulk** iteration -- iteration may expose a single element at a time, or it may give access to multiple elements all at once.
2. Iteration by **borrowing elements** vs iteration by **taking elements** -- whether iteration transfers ownership of the elements it traverses to the client.
3. **Generative** vs **visitative** iteration -- conforming types may be allowed to materialize their contents on the fly, or iteration may require to merely visit preexisting elements.
4. **Failable** and **non-failable** iteration -- whether iteration is allowed to throw an error.

Under these terms, our classic `Sequence` models _non-failable, generative, elementwise iteration by taking elements_.<br>
The new `Iterable` protocol models _failable, generative, bulk iteration by borrowing elements_.

In the rest of this document, we'll define three additional core protocols, `Container`, `Producer` and `Drain` (as well as a number of auxiliary protocols refining them). The four core protocols have the following properties and relationships:

| Protocol | Elementwise/bulk | Borrowing/taking | Generative/Visitative | Failable |
| :--- | :--- | :---: | :---: | :---: |
| [`Iterable`][Iterable] | bulk (`Span`-based) | borrowing | generative | failable |
| `└╴`[`Container`](#read-only-container-model) | bulk (`Span`-based) | borrowing | visitative | -- |
| [`Producer`](#producers) | bulk (`OutputSpan`-based) | taking | generative | failable |
| `└╴`[`Drain`](#protocol-drain) | bulk (`InputSpan`-based) | taking | visitative | -- |

We can already use this table to gain some interesting observations:

- Our proposed new protocols all have a strong preference towards bulk (rather than elementwise) iteration.
- "Iteration by borrowing" and "iteration by taking" are independent abstractions; they are both useful enough to deserve their separate protocol hierarchies.
- The design indicates that the generative iteration model is a "wider" or "weaker" abstraction than the "narrower"/"stronger" visitative one; both visitative protocols refine their generative counterparts. This is, to some extent, intuitively understandable: a protocol that only works with preexisting elements can also implement an interface that allows them to be generated on the fly. In exchange, the visitative protocols can provide richer, more specialized abstractions.
- This design also strongly correlates failability with generative iteration. Neither of our proposed "visitative" protocols is failable. This too follows from the fact that visitative iteration merely accesses elements that already exist; there isn't much possibility for these accesses to fail.

Let's now explore this design space a little further, by looking at the benefits and consequences of each decision.

### "Elementwise Iteration" vs "Bulk Iteration"

The classic `Sequence` models iteration by exposing elements one by one, through its iterator's `next()` method.

```swift
  mutating func next() -> Element?
```

This model of **elementwise iteration** is extremely straightforward to understand, and with a little practice we can write a rich variety of elementwise algorithms (almost) without thinking. However, it is not necessarily the most efficient way to iterate over things -- especially not over containers that organize their elements into piecewise contiguous storage chunks.

In elementwise iteration, we need to call a protocol's customizable entry point for each and every item we traverse. The entry point needs to load the iteration's current state, and find (or generate) the next element to visit -- precisely what that means varies wildly between each type we want to iterate over.

This makes it much harder for the compiler to reliably reason about and optimize code using `Sequence` types; this is especially difficult for sequences whose definitions are hidden behind a resilience boundary. In classic Swift, it isn't uncommon to see performance drop by a factor of hundreds as an operation's implementation moves across resilient module boundaries. As library evolution is a crucial feature of the language, this is rather unfortunate.

The new `Iterable` protocol resolves this issue by introducing the idea of **bulk iteration**, where each primitive iteration step exposes multiple items all at once to the client, batched up into a `Span` instance.

```swift
  mutating func nextSpan(maxCount: Int) throws(Failure) -> Span<Element>
```

`Span` is a small, frozen type in the Swift Standard Library, eminently amenable to optimizations -- efficiently traversing the elements of a span is a drastically simpler problem than iterating over an arbitrary sequence. `Iterable` forces conforming types to factor iteration into two distinct layers: clients still invoke custom code to retrieve the next batch of items, but once they have them, accessing the individual elements within each batch becomes dependably cheap.

For iterables that physically store their contents in memory, implementing iteration simply requires exposing spans over their preexisting piecewise contiguous storage chunks -- the bigger the chunks, the more efficient iteration becomes, even if `nextSpan`'s implementation isn't visible to the optimizer.

<details><summary>Click to expand footnote</summary>

> Of course, it was always possible to factor the implementation of iterators this way, by splitting `next()` into two layers, with judicious use of `@inlinable` or even `@inline(always)` attributes to encourage better performance while we're iterating within a storage chunk. However, this required a deep understanding of the underlying issues, and a large amount of willpower to structure the implementation the right way: this meant that only a select handful of types made an effort, and clients couldn't depend on it.
>
> `Iterable` forces all conforming types to organize their implementation around this idea, drastically improving clients' ability to reason about performance costs, even in generic contexts.

</details>

Bulk iteration is not without drawbacks: it comes with a drastically more complicated interface, increasing the mental load of authoring conforming types, and of solving problems using the protocol.

To understand how `Iterable` works, we need to learn about what `Span` is, which requires us to also learn at least a little about nonescapable types. We need to figure out how to resolve a whole new class of compiler errors, and ultimately we need to get comfortable reading lifetime dependency declarations, to allow us to predict what operations we can express and so that we can architect our solutions without constantly fighting compiler diagnostics.

Operations for bulk iteration are full of subtle design complications that often don't seem particularly important, but dismissing them can render the abstraction impossible to use in some contexts. For instance, `nextSpan`'s `maxCount` parameter is there to allow clients to limit the number of elements they receive at a time. Having to accommodate this limit is a significant complication for conforming types, so it is tempting to cut the complexity by force-feeding clients an arbitrary number of items. (After all, clients often set `maxCount` to `Int.max` anyway, and don't mind having to potentially deal with millions of items at a time.)

However, consider a client that just wants to look at the first three elements to make a decision about what to do with the rest. Giving this caller four thousand items would put them in an awkward position: they would need to stash the leftovers somewhere, and then process them all before pulling on the iterator again. The spans that `nextSpan` returns are tied to an exclusive access of the iterator, which (currently at least) makes it impossible to actually store them alongside the iterator in any meaningful way: these clients would be drowned in a sea of elements they cannot process. By simplifying conforming implementations, we would significantly limit the usefulness of the protocol.

<details><summary>Click to expand footnote</summary>

> Throwing away the iterator and restarting it may seem like a possible workaround, but as `Iterable` types aren't required to produce the same items on repeated iterations, this cannot be a general solution. It only works on some iterable types, such as the containers we are introducing in this document.

</details>

<span id="bulk-failures">

How bulk operations report/handle failures is a similarly subtle but important complication: operations that need to throw errors must be able to properly report partial success, to avoid data loss and to allow clients to identify precisely which element triggered the error. If the fifth element of an `Iterable` instance happens to trigger an error, it still needs to be possible for clients to reliably access the first four elements -- no matter what value they use for `maxCount`.

</span>

In this document, we consider this added conceptual complexity a reasonable cost of improving the predictability of Swift performance. We're fully embracing bulk iteration across the full spectrum of container operations. Each flavor of iteration will be primarily built around one of the standard span types: `Span`, `MutableSpan`, `OutputSpan` and `InputSpan`.

### "Iteration by Borrowing" vs "Iteration by Taking"

Code iterating over a `Sequence` gains full ownership of the items it accesses. It can decide to store some of them for later processing, and arbitrarily mutate or discard them as it wishes. Clients do not need to ask permission to do this, as `Sequence` relinquishes all control over the elements it exposes, as an inherent part of its design.

`Sequence` elements are (implicitly) required to be copyable, so this places no real restrictions on the kinds of types that can conform to the protocol. Conforming types are not _actually_ required to relinquish control over any of the items they contain just because someone is iterating over them: they can simply return copies of each element while also holding on to their "original" copy.

In contrast, `Iterable` was designed to support noncopyable elements, which do not allow such simple workarounds. Returning a noncopyable instance means transferring its unique ownership out of the iterable. For container types, this would be a destructive operation, as the contents would have to be physically moved out of the container, emptying it out or entirely consuming it in the process. This would not be workable as the default form of iteration: we naturally expect to be able to iterate over a container multiple times without destroying it in the process.

To avoid this, `Iterable` instead chooses to return _borrowing references_ to the elements it traverses, not the elements themselves. Clients do not get ownership over the items they access -- they get a temporary window that they can peer through to see a batch of items at a time; but they don't get to break the glass (to modify or consume the items), and once the window moves to the next batch, they lose sight of all previously seen items.

In this document, we'll call the ownership model of `Iterable` **iteration by borrowing**, as clients _borrow_ the elements they traverse. The other way to gain access to something is to _take_ ownership of it -- hence, we'll call the model `Sequence` follows **iteration by taking**.

<details><summary>Click to expand footnote</summary>

> People have sometimes referred to "iteration by taking elements" as "consuming iteration". Unfortunately, this is routinely misunderstood to mean that the sequence itself gets consumed, rather than its elements, and that makes it an actively confusing term. "Iteration by taking" is meant to describe what the client does to the _elements_, not what happens to the source of the iteration.

</details>

Of course, the way `Iterable` only provides read-only, borrowing access to its elements severely limits what clients can do with them. Obviously, we will also need to provide iterator-like constructs that transfer ownership of their elements to the caller, so that it can collect them into a container type, or otherwise mutate/consume them as it wishes. In this document, we model the idea of "iterating by taking elements" with protocol [`Producer`](#producers).

A variant of the `Iterable` approach is one where instead of borrowing references, we provide mutable references to elements -- we change the unit of iteration from `Span<Element>` to `MutableSpan<Element>` (or change `Ref<Element>` to `MutableRef<Element>`). The source of the elements still retains ownership in this case, but clients are allowed to arbitrarily mutate or even replace them. In this document, we model this approach with protocol [`MutableContainer`](#protocol-mutablecontainer). Notably, we only model visitative "muteration"; we are not introducing an `Iterable`-style, generative protocol for mutating iteration.

### "Generative" vs "Visitative Iteration"

`Sequence` and `Iterable` both allow their elements to be generated on the fly. We'll be calling this style of traversal **generative iteration**. This allows a wide spectrum of conforming types, but it complicates performance analysis, as the variable cost of on-demand generation inherently adds a difficult term to the complexity of element access.

Additionally, generative iteration by _borrowing_ (as implemented by `Iterable`) has the crucial limitation that the client cannot hold on to generated items as they come out of the iterator -- it is only able to see a single batch of them at a time, and the minute it advances the iterator, it loses sight of all the items it previously encountered. Because `Iterable` allows elements to be generated (and discarded!) on the fly, clients must destroy all references to the elements they see before they can advance to the next batch. This strictly limits the kinds of algorithms we can implement over `Iterable`: in particular, we cannot define lookup or search algorithms that need to return references to specific elements (such as `min()` or `first(where:)`), unless we require `Element` to be copyable. The elements we want to reference may evaporate the moment we advance the iterator!

Not all iterable types need to generate their items on demand. In particular, many of the most useful data structures physically hold their contents in memory, and they can implement iteration by simply locating their storage chunks and directly exposing spans over them. Arrays, linked lists, hashed sets, hashed dictionaries, ring buffers, search trees, ropes are all examples of such data structures, and of course there are many more.

Data structures with preexisting storage form a highly useful subset of iterables, and it is worth giving them a name; we'll call such types **containers**, and the traversal they support **visitative iteration**. These terms emphasize that iterating over a container merely visits its preexisting contents, rather than materializing them on the fly. Locating items in preexisting storage is a far simpler task than generating them; and clients can safely extract and work with references to such items as long as they do not mutate the instance that contains them.

Not all data structures are containers in this sense, of course. For example, Swift's standard `String` type is a sequence of `Character` instances, but those instances are not directly stored anywhere in `String`'s storage representation -- they need to be created on the fly, as we iterate over the string instance. `String` therefore implements _generative_ rather than _visitative_ iteration; it is not a container type. (Of course, it would be possible to build a container of text data; but to do it efficiently, we'd likely need to avoid using `Character`-style grapheme clusters as its `Element`.)

### Failability

The final design aspect we need to consider is failability: whether we need to allow traversable constructs to throw errors.

The classic `Sequence` protocol provides no way for conforming types to signal a failure, other than by trapping or by stopping the iteration earlier than expected. For many developers, this feels like a defect -- `Sequence` allows (or even encourages) conforming types to produce their elements by running arbitrarily complex calculations; and of course those calculations can sometimes legitimately encounter non-fatal problems. The inability to properly signal failure leads to awkward workarounds.

Using the terminology established in the previous section, the ability to fail is therefore a natural expectation for _generative_ constructs.

The `Iterable` protocol addresses this by defining a `Failure` associated type and providing a throwing `nextSpan` method on its iterator. It relies on [typed throws][TypedThrows] so that conforming types that never need to throw can set `Never` as their failure type, enabling clients to avoid writing error handling code that deals with errors that are guaranteed never to happen.

Failable iteration potentially allows lazy `Iterable` algorithms (like `filter`) to take throwing closures, and cleanly propagate errors to clients. In exchange, failability greatly complicates the bulk iteration model, as operations need to be able to [properly report partial success](#bulk-failures).

<details><summary>Click to expand footnote</summary>

> However, we also expect a filter predicate to be able to throw a _different_ error type than the `Iterable`'s own `Failure`. We currently lack the means to express that, as the `nextSpan` method would need to be able to throw either error. We need to do further language-level work -- such as union error types -- to allow us to express such abstractions in a satisfying way.

</details>

On the other hand, the ability to fail is far less important for _visitative_ constructs, like `Container` -- if the items we're visiting already exist in memory at the start of the iteration, there is little reason to take on the complexity of throwing. Therefore, our two visitative protocols (`Container` and `Drain`) do not allow throwing.

This greatly simplifies the container model, but it does mean that throwing algorithms like our hypothetical lazy `filter` can only produce `Iterable` types -- they cannot return containers, even if their input is one.

<details><summary>Click to expand footnote</summary>

> Some readers may note a problem with the assumption that accessing storage held in memory cannot possibly fail. While it is true that accessing memory can trigger faults (e.g., consider `mmap`ped regions), we lack the means to turn these faults into recoverable errors in Swift, and it seems unlikely it would be actually desirable to design container protocols around a hypothetical future language direction like that. The pragmatic choice is to assume that container types are stored in memory allocated using Swift's dedicated heap allocation primitives, and access to them can never fail without crashing the entire process (or at least bringing down an isolated subsystem within it).

</details>

Let us now introduce the actual protocols, starting with `Container` itself.

## A Read-Only Container Model

Protocol `Container` is our ownership-aware analogue of `Collection`. It defines the abstract shape of a container type that physically holds its contents in memory, and makes them directly accessible to clients.

The contents of a container can be traversed multiple times, nondestructively. The same container must exhibit identical contents across repeated traversals. Clients must be able to form references to container contents that aren't tied to a specific iteration state, only the container itself. This allows Swift functions to directly return such references to callers, allowing the implementation of a variety of useful container algorithms, including basic search/lookup methods.

Let's start defining the new protocol.

```swift
protocol Container<Element>: Iterable, ~Copyable, ~Escapable
where
  Element: ~Copyable,
  Failure == Never
{...}
```

The `Container` protocol refines `Iterable`; `Iterable` algorithms are able to work with container types with no extra effort. However, not all iterable types can be containers. The requirement that a container's elements must preexist in memory rules out all iterables that generate items on demand; using the terms [we established above](#generative-iteration-vs-visitative-iteration), we say that iterables model _generative iteration_, while containers are restricted to _visitative_ semantics.

`Container` requires `Failure` to be set to `Never`: because the contents of a container are required to exist in advance within the container instance, they can always be successfully iterated: there is never a need to throw an error.

Naturally, container types are not required to be copyable, nor escapable. They don't require their elements to be copyable, either. (Support for nonescapable elements is a [highly desirable future direction](#support-for-nonescapable-element-types), but we currently lack the means to express it in Swift.)

### Counting Elements

As containers physically store their elements, they inherently always have a specific count.

```swift
protocol Container<Element>: ... {
  ...
  var count: Int { get }
  ...
}
```

Repeated invocations of the `count` property on the same container must return the same value. The returned value must match the number of elements that can be accessed by iterating through the container.

Unlike `Collection`, types conforming to `Container` are **required to produce their `count` in constant complexity**. This reflects the protocol's focus on predictable performance, and avoids a common worry with `Collection`. Conforming to this requirement typically requires container implementations to cache their count in an easily accessible stored property, and incrementally update it every time the container changes its size.

<details><summary>Click to expand footnote</summary>

> One consequence of this requirement is that constructs like lazy filter algorithms cannot practically conform to the protocol. However, they can still conform to `Iterable`, and that is in fact good enough for the vast majority of their use cases in practice. Notably, custom on-the-fly filtering is inherently incompatible with our emphasis on predictable performance. (After all, the `Container` protocol exists to focus on high-performance use cases; it would be a mistake to dilute this focus until the protocol becomes indistinguishable from `Collection`.)
>
> `count` is required to return a finite integer that fits in `Int`. This can be a true limitation, as some containers may have more than `Int.max` elements, despite the protocol's requirement for preexisting storage! The storage requirement does not preclude some containers from linking specific storage chunks multiple times (or simply repeating them), without allocating separate storage for each duplicate run. Such repetitions can cause the count of a container to overflow `Int`'s range, without ever overflowing available memory. While such humongous containers are certainly interesting, we do not consider it crucial to provide dedicated support for them.
>
> In the design we are proposing, humongous containers can choose to either only conform to `Iterable`, or to trigger a trap if they are ever asked for their count. Client code often invokes `count` so that it can preallocate storage for related work; obviously that is not going to end well if a container's count exceeds `Int.max`. (And in fact trapping early is much preferable to allowing the operation to inevitably fail midway through some vast computation.)
>
> If we wanted to support such containers better, one option would be to have `count` return an optional; another would be to push the property down into a separate `FiniteContainer` protocol. The overwhelming complexity of these options does not feel to be anywhere in proportion to the practical importance of such cases. Which is not to say they don't exist: tree-based ropes in particular (like `Foundation`'s `AttributedString`) can easily grow to humongous sizes, by simply concatenating a rope with itself a few dozen times. However, these are mostly just curiosities; such trees are rarely (if ever) practically useful.

</details>

As a small nod towards infinite/vast containers, `Container` still provides an `isEmpty` property that avoids problems with integer overflow:

```swift
protocol Container<Element>: ... {
  ...
  var isEmpty: Bool { get }
  ...
}
```

This comes with a default implementation that simply checks if `count` is zero. (`Collection` defines a default implementation for its `isEmpty` that compares `startIndex` to `endIndex`. Given that `Container` requires its `count` to have O(1) complexity, it is slightly better to define `isEmpty` in terms of it, as it avoids having to materialize two index instances.)

Infinite/vast containers can provide their own `isEmpty` implementation that avoids using `count`, for example, by following `Collection`'s pattern. (They also need to provide a custom implementation for `underestimatedCount`, for the same reason.)

### Container Indices

As `Container` refines `Iterable`, it provides a `BorrowingIterator`, and we can use this iterator to access the elements of a container in batches, starting from its beginning. However, it would be a shame to stop there: `Container` can also provide a more flexible model for element access that acknowledges that its contents survive across iteration steps. To help model this, we introduce a slightly adapted version of `Collection`'s familiar `Index` concept.

```swift
protocol Container<Element>: ... {
  ...
  associatedtype Index: Equatable, Hashable
  ...
}
```

Our indices represent abstract positions within containers (just as they do in collections): one useful way to look at them is to say that they're addressing the logical boundaries between neighboring elements, with a "start index" addressing the boundary before the first element, and the "end index" addressing the boundary after the last. A container with five items therefore has six indices, addressing all its various logical positions:

```
         ┌─────┬─────┬─────┬─────┬─────┐
         │  A  │  B  │  C  │  D  │  E  │
         └─────┴─────┴─────┴─────┴─────┘
         ↑     ↑     ↑     ↑     ↑     ↑
         0     1     2     3     4     5
   (start)                             (end)
```

Equivalently, we can say that each index addresses a specific element, with the end index addressing an imaginary empty slot after the last item in the container.

Over the years, Swift's indices have proven to be extremely successful abstractions. This incarnation preserves them as copyable and escapable types, so that they can be processed without undue friction. Indices are soft references that are allowed to go stale when the underlying container is mutated; therefore, container operations taking indices are still required to carefully validate their inputs to catch misuse. (We could have chosen to replace indices with a nonescapable abstraction that would avoid this; however, in practice we found that direction to be [impractical](#cursors).)

Every one of the standard container types we've introduced so far (from `Span` to `UniqueArray` and beyond) already defines an index that fits this model.

`Container` indices are required to be `Equatable`, but unlike `Collection`, they do not need to be `Comparable`. Linked lists are commonly used in systems programming, and this choice allows some linked list implementations to usefully conform to `Container`. The lack of an inherent ordering does complicate the default implementations of some index operations -- [see below](#distance-from-to).

In exchange, `Container` requires its indices to be `Hashable`. This does not put an undue burden on container implementations, but it does allow indices to be collected in sets or used as dictionary keys, enabling use cases such as dynamic filtering or out-of-band storage of data associated with container elements. (Not guaranteeing hashable indices is a long-standing annoyance with `Collection`.)

To acknowledge our performance goals, **we require that equating and hashing `Container` indices must be performed with O(1) complexity**. If a container's index does happen to be `Comparable`, then it is required that `<` has O(1) complexity as well.

Now that we have an `Index` type, we can define all the familiar operations that allow us to navigate within a container:

```swift
protocol Container<Element>: ... {
  ...
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after index: Index) -> Index
  func formIndex(after index: inout Index)
  func index(_ index: Index, offsetBy n: Int) -> Index
  func formIndex(_ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index)
  func distance(from start: Index, to end: Index) -> Int
  ...
}
```

`startIndex` and `endIndex` work exactly like `Collection`'s corresponding properties, defining the bounds of a half-open range: `endIndex` returns a valid index that addresses the logical empty slot following the container's last element, while `startIndex` addresses the container's first element.

`index(_:offsetBy:)` is the `Container` analogue of `BorrowingIterator`'s `skip(by:)` method. It has slightly different semantics though, as it follows `Collection`'s behavior: `index(_:offsetBy:)` always takes exactly the specified number of steps, and it traps if it runs off the end of the container.

As `Container` models a forward-only container, its `index(_:offsetBy:)` operation requires a nonnegative offset. (We'll shortly introduce a `BidirectionalContainer` refinement that will relax this constraint.)

<span id="distance-from-to">

As indices aren't required to be `Comparable`, the default implementation of `distance(from:to:)` cannot quickly validate that its `start` argument precedes `end`. To avoid having to run all the way to the end of the container to detect misuse, the algorithm instead iterates forward from both arguments, until it finds the other. This makes the default implementation twice as slow, but it allows it to correctly calculate negative distances. In the common case when `Index` is `Comparable`, we also provide a refined default algorithm that avoids this overhead.

</span>

Notably, we replace `Collection`'s classic `index(_:offsetBy:limitedBy:)` requirement with an improved variant ([first introduced on `UniqueArray`][formIndex-offsetBy-limitedBy]) that reports the number of steps it was unable to take when reaching the limit. This avoids having to figure this out with a separate `distance(from:to:)` invocation, enabling more efficient use of this operation in situations that need this data; for example, it allows easy single-pass offsetting across concatenated containers. `Collection`'s original `index(_:offsetBy:limitedBy:)` operation is still available, as a standard algorithm based on the new requirement.

<span id="limiting-index-semantics">

The `limit` argument here (and also elsewhere throughout the `Container` interface surface) means a **limiting index**, intended to cause the operation to stop if it encounters the limit during its execution. A limit of this sort only triggers a stop if the operation needs to actively iterate over it. A limit that the operation never needs to visit has no effect, whether it happens to address a position before or after the visited range. For example, if we're trying to find the index by offseting position 10 by 5 places forward, a limiting index at position 3 has no effect -- to offset the original position, we only need to visit positions 10, 11, 12, 13, 14, and 15.

These curious semantics allow types that cannot provide comparable indices to still correctly conform to the protocol. (For example, linked lists usually cannot determine relative ordering between their indices without actively iterating through the list in linear time. If `limit` was required to be observed even if it lied behind the starting position, then linked lists would need to painstakingly figure out if this was the case, by iterating through items we wouldn't expect the operation to ever visit.)

</span>

[formIndex-offsetBy-limitedBy]: https://github.com/swiftlang/swift/blob/swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-06-a/stdlib/public/core/UniqueArray/UniqueArray%2BContainer.swift#L267-L273


### Visitative Iteration

The preferred way to iterate over the contents of a `Container` is to repeatedly invoke its `nextSpan` operation:

```swift
protocol Container<Element>: ... {
  ...
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index) -> Span<Element>
  ...
}
```

Like the corresponding iterator method on `Iterable`, this implements [bulk iteration](#elementwise-iteration-vs-bulk-iteration): it gives clients access to a batch of items all at once, allowing them to quickly iterate over the returned `Span` instance without invoking any other `Container` methods.

However, this `nextSpan` function is only allowed to mutate an index, not the container itself. Additionally, the spans returned by `nextSpan` are declared to be scoped to a "borrow" of the container, too. This is the crucial difference from `Iterable`, whose spans extend (and are tied to) a particular mutation of the iterator. This is what causes `Container` to fundamentally require its elements to preexist in memory -- it isn't possible for a `nextSpan` with this signature to materialize items on the fly. Containers are required to implement [visitative iteration](#generative-vs-visitative-iteration).

`Container.nextSpan` returns a `Span` instance that begins with the container's element that the given index addresses, and runs to the end of the container's storage chunk that contains it. On return, the index is updated to address the item following the last element in the returned span. If the input index is the `endIndex`, then the method returns an empty span, and leaves the index as is.

This method can be used to efficiently process the items of a container in bulk, by directly iterating over its piecewise contiguous pieces of storage:

```swift
     var index = items.startIndex
     while true {
       let span = items.nextSpan(after: &index)
       if span.isEmpty { break }
       // Process items in `span`
     }
     // `index` is now equal to `items.endIndex`
```

We expect that for-in loops over container types will use this iteration style, to allow clients to form `Ref` instances over the element that's currently visited by the loop.


The spans returned by `nextSpan` are not guaranteed to be disjunct. Some containers may use the same storage chunk (or parts of a storage chunk) multiple times, to repeat their contents.

Repeated invocations of `nextSpan` on the same container and index are guaranteed to expose identical elements, in the same order, and grouped into spans of consistent counts.

Sometimes we don't want to iterate all the way to the end of a container: for instance, we may just want to look at a specific subrange, or we may need to access a specific number of elements. For these cases, `Container` also provides a delimited variant of `nextSpan`, modeled after `formIndex(_:offsetBy:limitedBy:)`:

```swift
protocol Container<Element>: ... {
  ...
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, maxCount: Int, limitedBy limit: Index) -> Span<Element>
  ...
}
```

The `maxCount` argument gives the caller control over the number of items it receives from the iterator, while `limit` allows the caller to request that the result never step over a specific index. These parameters let callers avoid overrunning their target, which would significantly complicate container use.

For convenience, `Container` provides overloads that (effectively) make `nextSpan`'s `maxCount` and `limit` arguments optional:

```swift
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, maxCount: Int) -> Span<Element> {
    self.nextSpan(after: &index, maxCount: maxCount, limitedBy: self.endIndex)
  }

  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, limitedBy limit: Index) -> Span<Element> {
    self.nextSpan(after: &index, maxCount: .max, limitedBy: limit)
  }
}
```

Not all containers are contiguous, so `maxCount` only sets an upper bound. To read a specific number of items, the caller usually needs to invoke `nextSpan` in a loop:

```swift
var items: some Container<Int>
var index = items.startIndex
var remainder = numberOfItemsToRead
while remainder > 0 {
  let next = items.nextSpan(after: &index, maxCount: remainder)
  guard !next.isEmpty else {
    // Container does not have enough items
    break
  }
  remainder -= next.count
  // Process items in `next`
}
```

### Default Implementations

The more powerful form of `nextSpan` is a core primitive; by default, most other `Container` requirements are implemented in terms of it. For example, here is the default implementation of `index(_:offsetBy:)`:

```swift
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  func index(_ index: Index, offsetBy n: Int) -> Index {
    var index = index
    var n = n
    let end = self.endIndex
    while n > 0 {
      let c = self.nextSpan(after: &index, maxCount: n, limitedBy: end).count
      precondition(c > 0, "Cannot advance index beyond the end of the container")
      n &-= c
    }
    return index
  }
}
```

Containers often group their contents into piecewise contiguous storage chunks: for example, array types hold all of their elements in a single, contiguous region of memory. As this default implementation iterates over entire chunks, it can be considerably more efficient than stepping through indices one by one, like `Collection` does. The elements are all required to preexist in memory, so materializing spans over them is relatively cheap -- `nextSpan` merely needs to locate storage, not populate its contents. Still, it is often possible to implement `Container` operations more directly (and more efficiently) than by invoking `nextSpan`, and so it is good practice to do so whenever it leads to measurable improvement.

While bulk iteration is often a performance boost, not all container types benefit from it. Some containers allocate a separate node for each of their elements, so their storage chunks all have just one item each. (Linked lists and binary search trees are two well-known examples.) These container types are still able to implement bulk iteration interfaces, but they become far less effective, as they are reduced to a somewhat overcomplicated form of elementwise iteration. Accordingly, in the worst case the `index(_:offsetBy:)` implementation above may need to invoke the `nextSpan` operation `n` times -- it has the same linear worst-case complexity as `Collection`'s elementwise implementation.

The default implementation of `distance(from:to:)` poses an interesting problem: `Container` only allows forward iteration, so to measure the distance between two indices, we have to start iterating from the one addressing the earlier one. But `Container` does not require its `Index` to be `Comparable`, so we cannot easily decide which index goes first! We have three options to resolve this:

1. Only provide a default `distance` algorithm for containers with comparable indices.

    ```swift
    extension Container
    where
      Self: ~Copyable & ~Escapable,
      Element: ~Copyable,
      Index: Comparable
    {
      func distance(from start: Index, to end: Index) -> Int {
        var (i, j, forward): (Index, Index, Bool) = (start <= end
         ? (start, end, true)
         : (end, start, false))
        var d = 0
        while i < j {
          let span = self.nextSpan(after: &i, maxCount: .max, limitedBy: j)
          precondition(span.count > 0, "Invalid Container")
          d += span.count
        }
        return forward ? d : -d
      }
    }
    ```

   This visits exactly as many storage chunks as exist between the indices, so it is the most efficient way to calculate the distance. (Without knowing more about the internals of the container.)

2. Require `start` to precede `end`, but with no easy way to validate this other than letting iteration go all the way to the end of the container.

    ```swift
    extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
      func distance(from start: Index, to end: Index) -> Int {
        var i = start
        var d = 0
        while true {
          let c = self.nextSpan(after: &i, maxCount: .max, limitedBy: end).count
          d += c
          if i == end { break }
          precondition(c > 0, "Invalid Container or 'start' does not precede 'end'")
        }
        return d
      }
    }
    ```

    This option is equivalent to the previous one if `start` happens to come before `end`, but it runs all the way to the end of the container and then traps if they are in the wrong order. `Collection`'s original `distance` had no trouble returning negative values, so choosing this option could invite accidental misuse.

3. Allow `start` and `end` to be in any order, but iterate forward from both ends until we find the other:

    ```swift
    extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
      func distance(from start: Index, to end: Index) -> Int {
        // This variant allows start to follow end, but as indices aren't
        // comparable, we have to measure distances from both ends.
        var d1 = 0
        var d2 = 0
        var i1 = start
        var i2 = end
        var forward = true
        var backward = true
        while forward || backward {
          if forward {
            let c = self.nextSpan(after: &i1, limitedBy: end).count
            d1 += c
            if i1 == end { return d1 }
            if c == 0 { forward = false }
          }
          if backward {
            let c = self.nextSpan(after: &i2, limitedBy: start).count
            d2 -= c
            if i2 == start { return d2 }
            if c == 0 { backward = false }
          }
        }
        fatalError("Invalid Container")
      }
    }
    ```

    This option has to visit (at worst) twice as many items as the previous two in their regular execution, as the `limitedBy:` arguments [have no effect if the specified `limit` lies behind the start position](#limiting-index-semantics).

To preserve continuity/interoperability with `Collection` (whose `distance` operation allows any ordering), `Container` implements option 3, while also providing the simpler/faster implementation from option 1, for the common case when `Index` is `Comparable`.

### Subscripting

Bulk iteration is nice, but sometimes we do just want to access an individual element addressed by a specific index. For these cases, `Container` provides an indexing subscript with a [`borrow` accessor][BorrowAndMutate]:

```swift
protocol Container<Element>: ... {
  ...
  subscript(index: Index) -> Element { borrow }
  ...
}
```

This (alongside all the shared index operations) makes `Container` instantly familiar to developers who have used `Collection`. Of course, this indexing subscript is not the same as the classic `Collection` subscript: it has a `borrow` accessor, not a getter. As of Swift 6.4, we cannot even put its borrowed result in a local variable; to do that, we need to manually create a borrowing reference by wrapping the result in a `Ref` instance:

```swift
let item = someContainer[index]
      // ^ error: 'someContainer.subscript' is borrowed and cannot be consumed
let item2 = Ref(someContainer[index]) // OK
```

### Interaction with `Iterable`

#### `ContainerIterator`

`Container` refines `Iterable`, so it comes with all requirements of the `Iterable` protocol. The native container operations allow us to create standard implementations for these requirements, so that developers don't need to create a custom iterator type from scratch each time they work on a new container type. The standard iterator adapter is called `ContainerIterator`, and it serves the same purpose in the `Container` world as `IndexingIterator` does for `Collection`.

A `ContainerIterator` instance stores a borrowing reference to a container value, alongside a current position inside it:

```swift
struct ContainerIterator<
  Base: Container & ~Copyable /*& ~Escapable*/
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable
{
  typealias Element = Base.Element

  internal let _base: Ref<Base> // Note: This requires an escapable Base
  internal let _end: Base.Index
  internal var _position: Base.Index

  init(base: borrowing Base, from start: Base.Index, to end: Base.Index)
}

@available(SwiftStdlib 6.4, *)
extension ContainerIterator: BorrowingIteratorProtocol
where
  Base: ~Copyable /*& ~Escapable*/,
  Base.Element: ~Copyable
{

  @_lifetime(&self)
  mutating func nextSpan(maxCount: Int) -> Span<Element> {
    _base.value.nextSpan(after: &self._position, maxCount: maxCount, limitedBy: _end)
  }

  @_lifetime(self: copy self)
  mutating func skip(by maximumOffset: Int) -> Int { ... }
}
```

Compare this to `IndexingIterator`, which holds a _copy_ of its base collection, plus a current index. `ContainerIterator` implements the same idea, adapted for the borrowing ownership model. (It adds a limiting index to allow iterating over a subrange of elements in a container -- this is intended to substitute for a common use case of `Collection` slices.)

#### Conversions Between Indices and Iterators

`Container` resolves a long-standing `Collection` limitation by providing standard operations to start an iterator from a specific index (or between two indices), and to retrieve the current index of an existing iterator:

```swift
protocol Container<Element>: ... {
  ...
  @_lifetime(borrow self)
  func makeBorrowingIterator(from start: Index, to end: Index) -> BorrowingIterator
  func currentIndex(of iterator: borrowing BorrowingIterator) -> Index
  ...
}

extension Container
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_lifetime(borrow self)
  func makeBorrowingIterator() -> BorrowingIterator {
    self.makeBorrowingIterator(from: self.startIndex, to: self.endIndex)
  }

  @_lifetime(borrow self)
  func makeBorrowingIterator(from start: Index) -> BorrowingIterator {
    self.makeBorrowingIterator(from: start, to: self.endIndex)
  }
}
```

#### Default Implementations of `Iterable` requirements

The `underestimatedCount` of a `Container` is simply its count:

```swift
extension Container
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  var underestimatedCount: Int { self.count }
}
```

We'd like the `Container` protocol to declare `ContainerIterator` as its default borrowing iterator type:

```swift
protocol Container<Element>: ... {
  ...
  associatedtype BorrowingIterator = ContainerIterator<Self>
  ...
}
```

Unfortunately, this isn't currently possible, as `Ref` is not yet able to address nonescapable targets, and `Container` does need to allow nonescapable conforming types (such as `Span`). In its current form, `ContainerIterator` does not work for those, so nonescapable containers will need to manually implement a suitable iterator type.

However, we can at least supply default implementations for all `Iterable`-related operations when `Iterator` happens to be `ContainerIterator`:

```swift
extension Container
where
  Self: ~Copyable,
  Element: ~Copyable,
  BorrowingIterator == ContainerIterator<Self>
{
  @_lifetime(borrow self)
  func makeBorrowingIterator(from start: Index, to end: Index) -> BorrowingIterator {
    ContainerIterator(_borrowing: self, from: start, to: end)
  }

  func currentIndex(of iterator: borrowing BorrowingIterator) -> Index {
    iterator._position
  }
}
```

### Optional Lookup Hooks

`Collection` defines two customization hooks for quickly looking up the first and last indices of an `Equatable` element instance. We directly include the same requirements on `Container`:

```swift
protocol Container<Element>: ... {
  ...
  func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  ...
}
```

On `Collection`, these hooks allow conforming types to customize the standard `firstIndex(of:)` and `lastIndex(of:)` operations to implement more efficient algorithms than linear search. For instance, a hashed set type may implement these hooks to provide lookup operations with an expected complexity of O(1).

Like with `Collection`, these operations come with default implementations that simply return `nil`, indicating that there is no shortcut available for looking up elements.

### Performance Requirements

To achieve predictable performance, `Container` operations are expected to have the following worst-case complexities:

| Operation | Complexity |
|---|---|
| `Index.==` | O(1) |
| `Index.hash(into:)` | O(1) |
| `isEmpty` | O(1) |
| `count` | O(1) |
| `endIndex` | O(1) (non-negotiable requirement) |
| `startIndex` | O(1) |
| `nextSpan(...)` | O(1) |
| `subscript(_:)` | O(1) |
| `index(after:)` | O(1) |
| `formIndex(after:)` | O(1) |
| `index(_:offsetBy:)` | O(`n`) |
| `formIndex(_:offsetBy:)` | O(`n`) |
| `formIndex(_:offsetBy:limitedBy:)` | O(`n`) |
| `distance(from:to:)` | O(*d*) where *d* is the absolute value of the actual distance |
| `makeBorrowingIterator(...)` | O(1) |
| `currentIndex(of:)` | O(1) |
| `_customIndexOfEquatableElement(_:)` | O(1) |
| `_customLastIndexOfEquatableElement(_:)` | O(1) |

These correspond to similar (sometimes implicit) expectations on `Collection`'s operations, stated more consistently. Of these, only the constant complexity of `endIndex` is a hard requirement; the others are setting rough expectations that may sometimes need to be violated. All containers are required to clearly document any deviations from the expectations above.

Common examples of containers with unusually high index navigation costs:

- Containers with sparsely populated storage may need to scan an arbitrarily large number of empty storage slots between valid elements.

   Hashed containers like the standard `Set` and `Dictionary` types are prominent examples of this -- their `index(after:)` implementation has a worst-case complexity that's linear in their storage capacities, which can be arbitrarily larger than their count. (Even when averaged over iterating over the entire contents of a dictionary, `index(after:)`'s amortized complexity is still O(`capacity`/`count`) i.e., the inverse of the current load factor -- which still has no constant upper bound.) This is difficult to mitigate in practice; for example, implementing a minimum load factor would resolve this, but it would lead to constant allocation churn that (in most cases) would be considered much worse than inconsistent iteration speed.

- Container types built around balanced trees (such as sorted sets or ropes) commonly need to replace/augment many of these complexities with "O(log(`count`))" terms.

### The Full `Container` protocol

```swift
protocol Container<Element>:
  Iterable, ~Copyable, ~Escapable
  where Element: ~Copyable, Failure == Never
{
  associatedtype Index: Equatable, Hashable
  /*associatedtype BorrowingIterator = ContainerIterator<Self>*/

  @_lifetime(borrow self)
  func makeBorrowingIterator(from start: Index, to end: Index) -> BorrowingIterator

  func currentIndex(of iterator: borrowing BorrowingIterator) -> Index

  var isEmpty: Bool { get }
  var count: Int { get }
  var startIndex: Index { get }
  var endIndex: Index { get }

  @_lifetime(borrow self)
  func nextSpan(after index: inout Index) -> Span<Element>

  @_lifetime(borrow self)
  func nextSpan(
    after index: inout Index,
    maxCount: Int,
    limitedBy limit: Index
  ) -> Span<Element>

  subscript(index: Index) -> Element { borrow }

  func index(after index: Index) -> Index
  func formIndex(after index: inout Index)
  func index(_ index: Index, offsetBy n: Int) -> Index
  func formIndex(_ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index)
  func distance(from start: Index, to end: Index) -> Int

  func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index??
}
```

### Conforming to `Container`

Types that wish to conform to protocol `Container` must, at minimum, complete the following tasks:

1. Implement an `Index` type, and an index validation strategy. Dereferencing an index must be both safe and highly efficient: it must be possible to reliably and quickly check that an index represents a valid position in the container, and then use the data inside the index to efficiently find the correct element in the container's storage.

2. Implement `startIndex` and `endIndex` properties. `endIndex` must be as efficient as possible; it is required to have O(1) complexity, on every container type.

3. Implement a `count` property with O(1) complexity. Often, this requires backing it by a stored property that gets incrementally updated every time the container changes its size.

4. Choose a `BorrowingIterator` type, and implement the related methods `makeBorrowingIterator(from:to:)` and `currentIndex(of:)`. The most straightforward choice is to use the standard `ContainerIterator` type; it provides a reasonable default for most container types.

5. Implement the `nextSpan(after:maxCount:limitedBy:)` method. This is the core container primitive: the rest of container operations all come with default implementations based on this one.

6. If the container is able to look up elements by value, provide custom implementations of `_custom[Last]IndexOfEquatableElement` so that standard algorithms can avoid falling back to linear searching.

7. Implement custom implementations for additional container requirements, as needed. It is often possible to supply hand-optimized implementations that exploit the specific details of the container to provide measurably more efficient code than what the standard implementations achieve. Whether it is worth taking the extra effort to do this up front depends on the kind of container we're building, and its intended target use cases.

Once a container type ships in source (or ABI) stable code base, its choices for `Index` and `BorrowingIterator` types get baked into its interface, and become tricky (or impossible) to change in future releases. However, the implementations of specific operations can usually be updated; for example, it is usually possible to have a subsequent version replace the default implementation of an operation with a more efficient alternative that is tailor-made for the specific data structure.

### Bidirectional Containers

The `Container` protocol only allows iterating forward -- towards the end index. Some container types also support going the other way, and modeling that with a protocol allows generic algorithms to exploit this capability to solve more problems that they can solve with forward iteration alone.

Our `Container` model follows in the footsteps of `Collection`, so we model backwards iteration as a refinement of forward iteration, by introducing a protocol `BidirectionalContainer`:

```swift
protocol BidirectionalContainer<Element>: Container, ~Copyable, ~Escapable
where Element: ~Copyable, Index: Comparable
{
  func index(before i: Index) -> Index
  func formIndex(before i: inout Index)

  func spanBoundary(before index: Index) -> (index: Index, distance: Int)

  func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int)

  @_nonoverride func index(_ index: Index, offsetBy n: Int) -> Index
  @_nonoverride func formIndex(_ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index)
}
```

`index(before:)` and `formIndex(before:)` match their equivalent `BidirectionalCollection` operations, although containers do come with an expectation that they both have O(1) complexity. (Container types that cannot provide these with constant complexity must explicitly document this deviation.)

Given that `Container` defines `nextSpan` operations, it is not unreasonable to expect that `BidirectionalContainer` would come with a `previousSpan` requirement. That's not the case -- we only provide operations that return indices to the nearest span boundary before the given position. `BidirectionalContainer` does come with `previousSpan` operations, but they are expressed as standard algorithms defined in terms of `spanBoundary` and `nextSpan`; they aren't customizable entry points themselves.

```swift
extension BidirectionalContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_lifetime(borrow self)
  func previousSpan(before index: inout Index, maxCount: Int = Int.max) -> Span<Element> {
    self.previousSpan(before: &index, maxCount: maxCount, limitedBy: self.endIndex)
  }

  @_lifetime(borrow self)
  func previousSpan(
    before index: inout Index,
    maxCount: Int = Int.max,
    limitedBy limit: Index
  ) -> Span<Element> {
    let (i, d) = spanBoundary(before: index, maxDistance: maxCount, limitedBy: limit)
    if d == 0 { return .init() }
    var j = i
    let span = nextSpan(after: &j, limitedBy: index)
    precondition(j == index && span.count <= maxCount, "Invalid BidirectionalContainer")
    index = i
    return span
  }
}
```

To iterate backwards over a container, we call `spanBoundary(before:)` to get a suitable start position, then feed it to `nextSpan(after:)` to get a `Span` over the next (or rather, previous) batch of elements.

This asymmetry is designed to help us define a mutating iteration model ([protocol `MutableContainer`, with a `nextMutableSpan` method](#protocol-mutablecontainer)) without having to also define a `BidirectionalMutableContainer` to supply a `previousMutableSpan` operation.

`BidirectionalContainer` redeclares a couple of `Container` operations with a `@_nonoverride` attribute: `index(_:offsetBy:)` and `formIndex(_:offsetBy:limitedBy:)`. The bidirectional variants of these allow the offset `n` to be negative, deviating from `Container`'s requirements. Redeclaring these as nonoverriding methods allows types that conform to `BidirectionalContainer` to provide distinct implementations for the forward-only and bidirectional cases. This is especially useful for types (such as container adapters) that want to be _conditionally bidirectional_, and can only support negative offsets if (say) their type arguments happen to conform to specific protocols. For example, take a hypothetical container adapter that concatenates two container instances:

```swift
struct Concatenated<C1: Container, C2: Container>: Container
where C1.Element == C2.Element {
  typealias Element = C1.Element

  enum Index: Hashable {
    case first(C1.Index)
    case second(C2.Index)
  }

  internal var _first: C1
  internal var _second: C2
  init(_ first: consuming C1, _ second: consuming C2) {...}
  ...

  func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(n >= 0)
    switch index {
    case .first(var i):
      var n = n
      _first.formIndex(&i, offsetBy: &n, limitedBy: _first.endIndex)
      if n == 0 { return .first(i) }
      return .second(_second.index(_second.startIndex, offsetBy: n))
    case .second(var i):
      return .second(_second.index(i, offsetBy: n))
    }
  }
}
```

It would be desirable for this type to conform to `BidirectionalContainer` if both of its components do:

```swift
extension Concatenated: BidirectionalContainer
where C1: BidirectionalContainer, C2: BidirectionalContainer {
  ...
  func index(_ index: Index, offsetBy n: Int) -> Index {
    if n >= 0 {
      switch index {
      case .first(var i):
        var n = n
        _first.formIndex(&i, offsetBy: &n, limitedBy: _first.endIndex)
        if n == 0 { return .first(i) }
        return .second(_second.index(_second.startIndex, offsetBy: n))
      case .second(var i):
        return .second(_second.index(i, offsetBy: n))
      }
    } else {
      switch index {
      case .first(var i):
        return .first(_first.index(i, offsetBy: n))
      case .second(var i):
        var r = n
        _second.formIndex(&i, offsetBy: &r, limitedBy: _second.startIndex)
        if r == 0 { return .second(i) }
        return .first(_first.index(_first.endIndex, offsetBy: r))
      }
    }
  }
}
```

However, unless we redeclare `index(_:offsetBy:)` in the refining protocol, the `Container` and `BidirectionalContainer` protocols would share a single `index(_:offsetBy:)` requirement, and it must resolve to the unconditional forward-only definition. Swift types can only provide a single implementation for each protocol requirement; therefore the second `index(_:offsetBy:)` would be ignored by conformance resolutions, and it would only be considered an auxiliary overload of the primary definition. Therefore callers that are generic over `BidirectionalContainer` would end up only able to call the forward-only implementation. `@_nonoverride` allows us to let the two definitions be both visible to such clients, without having to invent distinct names for these two operations.

(Of course, we could also have decided to break continuity with `Collection`, and introduce new names, such as `Container.index(_:advancedBy:)` and `BidirectionalContainer.index(_:decrementedBy:)`. This makes for fewer surprises for clients, but it results in a messier API surface if a type happens to conform to both `Container` and `Collection` protocol hierarchies. Additionally, clients may find it needlessly pedantic to have to invoke distinct operations when navigating forward or back.)

This `@_nonoverride` business is largely irrelevant for types that conform to `BidirectionalContainer` without conditions, as such types typically only want to define `index(_:offsetBy:)`/`formIndex(_:offsetBy:limitedBy:)` once, with bidirectional semantics.

### Random-Access Containers

We also provide a named abstraction for random-access containers that can provide constant complexity operations for finding the element at an arbitrary offset from an index, and for measuring distances between arbitrary indices.

Protocol `RandomAccessContainer` refines `BidirectionalContainer`, with minimal new API:

```
protocol RandomAccessContainer<Element>
: BidirectionalContainer, ~Copyable, ~Escapable
where Element: ~Copyable, Index: Comparable {
  @_nonoverride func index(_ index: Index, offsetBy n: Int) -> Index
  @_nonoverride func formIndex(_ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index)
  @_nonoverride func distance(from start: Index, to end: Index) -> Int
}
```

However, the protocol adds strong semantic complexity requirements across all operations -- basically everything has to be O(1):

| Operation | Complexity |
|---|---|
| <code>Index.&#61;&#61;</code> | O(1) |
| `Index.<` | O(1) |
| `Index.hash(into:)` | O(1) |
| `isEmpty` | O(1) |
| `count` | O(1) |
| `endIndex` | O(1) |
| `startIndex` | O(1) |
| `nextSpan(...)` | O(1) |
| `subscript(_:)` | O(1) |
| `index(after:)` | O(1) |
| `index(before:)` | O(1) |
| `formIndex(after:)` | O(1) |
| `formIndex(before:)` | O(1) |
| `index(_:offsetBy:)` | O(1) |
| `formIndex(_:offsetBy:)` | O(1) |
| `formIndex(_:offsetBy:limitedBy:)` | O(1) |
| `distance(from:to:)` | O(1) |
| `makeBorrowingIterator(...)` | O(1) |
| `currentIndex(of:)` | O(1) |
| `_customIndexOfEquatableElement(_:)` | O(1) |
| `_customLastIndexOfEquatableElement(_:)` | O(1) |

Random-access containers must have a `Comparable` index type. This is mostly a consequence of an O(1) `distance(from:to:)`: if we can measure distances between indices in constant time, then we can simply use the sign of the resulting distance to decide their ordering. Requiring indices to be `Comparable` only take a little bit of additional effort, in that it requires that we can do this based on just the indices themselves, without consulting the container.

Random-access container (and collection) indices are largely isomorphic to integer offsets, and we are often able to increment/decrement them independent of their container. Indeed, well-designed random-access containers often use simple `Int` values as their index; `Span`, `InlineArray`, `UniqueArray` all use integer indices, and so do `RigidArray`, `RigidDeque` and `UniqueDeque` in swift-collections. To exploit this, and to simplify creating conforming types, `RandomAccessContainer` provides efficient default implementations for most indexing operations if `Index` is `Strideable`:

```swift
extension RandomAccessContainer
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable,
  Index: Strideable,
  Index.Stride == Int
{
  var isEmpty: Bool { startIndex == endIndex }
  var count: Int { startIndex.distance(to: endIndex) }
  func index(after index: Index) -> Index { index.advanced(by: 1) }
  func index(before index: Index) -> Index { index.advanced(by: -1) }
  public func formIndex(after index: inout Index) { index = index.advanced(by: 1) }
  public func formIndex(before index: inout Index) { index = index.advanced(by: -1) }
  func distance(from start: Index, to end: Index) -> Int { start.distance(to: end) }
  func index(_ index: Index, offsetBy n: Int) -> Index { index.advanced(by: n) }
  func formIndex(
    _ index: inout Index, offsetBy distance: inout Int, limitedBy limit: Index
  ) {
    index.advance(by: &distance, limitedBy: limit)
  }
}
```

These definitions avoid traversing container storage (like the `nextSpan`-based implementations did in earlier sections), and we expect their simpler definitions to optimize better. However, they do not check that their input indices are valid in the container, and when given invalid input, they tend to return invalid indices. (For instance, an `index(_:offsetBy:)` defined this way typically allows offsetting the index beyond the end of the container.) The idea is that index validation is deferred until the client attempts to actually use the index to access an element. This saves some index validation overhead, while still fully guaranteeing memory safety. However, delaying the detection of errors makes debugging a little harder, as mistakes are not be caught by (and reported as coming from) the specific operations that actually trigger them.

Based on our expectations for predictably good container performance, we believe this to be a good compromise. Luckily, `Collection` types already routinely behave the same way, so the looser validation is not going to come as a surprise.

## Mutable Containers

### `protocol PermutableContainer`

```swift
protocol PermutableContainer<Element>: Container, ~Copyable, ~Escapable
where Element: ~Copyable
{
  @_lifetime(self: copy self)
  mutating func swapAt(_ i: Index, _ j: Index)
}
```

### `protocol MutableContainer`

```swift
protocol MutableContainer<Element>:
  PermutableContainer, ~Copyable, ~Escapable
where
  Element: ~Copyable
{
  subscript(index: Index) -> Element { borrow mutate }

  @_lifetime(&self)
  mutating func nextMutableSpan(after index: inout Index) -> MutableSpan<Element>

  @_lifetime(&self)
  mutating func nextMutableSpan(
    after index: inout Index,
    maxCount: Int,
    limitedBy limit: Index
  ) -> MutableSpan<Element>
}
```

## Producers

```swift
/// A type that supplies the values of a generative sequence by populating
/// a client-supplied series of `OutputSpan` instances. "Generative" sequences
/// transfer the ownership of items they produce to their clients, rather than
/// merely providing borrowing access to them. A `Producer` instance represents
/// an ongoing iteration over such a generative sequence.
public protocol Producer<Element, Failure>: ~Copyable, ~Escapable {
  /// The type of the items that this producer generates.
  associatedtype Element: ~Copyable

  /// The error that this producer may throw, or `Never` if this producer
  /// always succeeds.
  associatedtype Failure: Error = Never

  /// A value less than or equal to the number of remaining items that this
  /// producer is able to generate until it reaches its end.
  ///
  /// The default implementation returns 0. If you provide your own
  /// implementation, make sure to compute the value nondestructively.
  var underestimatedCount: Int { get }

  /// Generate the next batch of items into the supplied output span instance,
  /// which must have room for at least one new element.
  ///
  /// Repeatedly calling this method produces, in order, all the elements of the
  /// underlying generative sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return false without appending any new
  /// items to their target. This method is not guaranteed to fully populate the
  /// given output span, but it always appends at least one item until the end
  /// of the underlying generative sequence.
  ///
  /// The ownership of all generated elements is transferred to the caller of
  /// this method -- it can arbitrarily store, mutate, consume or discard them
  /// as needed, even across invocations of this method, or after the producer
  /// is destroyed.
  ///
  /// The returned Boolean value can be used to easily determine if the
  /// method was able to make progress towards filling `target` without hitting
  /// the end of the underlying sequence.
  ///
  /// If `target` is a full span, this method is allowed to unconditionally
  /// return true. Passing an empty span is not a reliable way to test if the
  /// producer has reached its end. (Some producers may only be able to detect
  /// that they are finished while trying to generate the next item.)
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to generate
  /// the upcoming next item in the sequence. Failure may happen midway through
  /// populating `target`, in which case the output span will still gain
  /// new items despite the error. (Those items are successfully
  /// generated, and do not necessarilly need to be discarded.)
  ///
  /// This protocol does not specify the meaning of a failure, or the
  /// precise state of the iterator after an error is thrown; however, the
  /// error must not trigger runtime traps in subsequent attempts at iteration.
  /// (After a failure, conforming types may choose to produce new items, or
  /// signal the end of the iteration, or throw another error, which may or may
  /// not match the first.)
  ///
  /// Absent of more specific information, generic code should stop
  /// iterating, discard the producer and rethrow the error when it encounters
  /// a failure. Generic code is encouraged to preserve the items that got
  /// successfully produced before the throw (including ones appended by
  /// the call that ultimately ended in failure); however, whether this is
  /// possible (or desirable) ultimately depends on the specific problem that
  /// the algorithm is solving.
  ///
  /// - Parameter target: An output span ready to take newly generated items.
  /// - Returns: A boolean value indicating whether the operation was able to
  ///    append at least one item to the supplied output span without hitting
  ///    the end of the underlying sequence.
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Bool

  /// Skip the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped before hitting
  /// the end of the sequence or an error.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing the elements.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `n` and return false.
  ///
  /// The default implementation of this method repeatedly calls
  /// `generate(into:)` with a small temporary buffer, immediately discarding
  /// all generated items. Conforming types are encouraged to replace this
  /// default approach with a more efficient implementation whenever it is
  /// possible to do so.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// an upcoming item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case `n` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem. This can be used to precisely track
  /// the current position of the failed producer, allowing better diagnostics,
  /// and allowing iteration to continue if the failure is resolvable.
  ///
  /// - Parameter n: The number of items to skip. This must be greater than
  ///     zero. This method decrements this value by the number of items it
  ///     successfully skipped before returning.
  @_lifetime(self: copy self)
  mutating func skip(by n: inout Int) throws(Failure)

  /// Generate and return the next element in the underlying generative
  /// sequence.
  ///
  /// Repeatedly calling this method produces, in order, all the elements of the
  /// underlying generative sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return `nil`.
  ///
  /// The ownership of all generated elements is transferred to the
  /// caller of this method -- it can arbitrarily store, mutate,
  /// consume or discard them as needed, even across invocations of this method,
  /// or after the producer is destroyed.
  ///
  /// This method throws an error to indicate a failure. This protocol does not
  /// specify the meaning of such errors, or the precise state of the
  /// iterator after an error is thrown; however, the error must not trigger
  /// runtime traps in subsequent attempts at iteration.
  /// (Conforming types may choose to produce new items, or signal the end of
  /// the iteration, or throw another error, which may or may not match the
  /// first.) Absent of more specific information, generic code should stop
  /// iterating, discard the producer and rethrow the error when it encounters
  /// a failure.
  ///
  /// The default implementation of this method calls `generate(into:)` with
  /// a temporary output span with room for a single item, and returns the
  /// resulting contents. This often produces satisfactory results; but the
  /// protocol allows conformances to customize this entry point if they believe
  /// it to be necessary (for example, if they can take shortcuts that aren't
  /// available in the bulk method). Custom implementations of `next()`
  /// must produce results that are indistinguishable from the default
  /// implementation, but they may exhibit observably different performance
  /// metrics.
  @_lifetime(self: copy self)
  mutating func next() throws(Failure) -> Element?
}
```

### Default Implementations on `Producer`

```
  /// Return the nearest valid index in this container less than or equal to
  /// the given index value, which must be valid in at least one view of self.
  ///
  /// This operation is important for container types that provide multiple
  /// alternative projections (or "views") over the same underlying
  /// representation, with each view conforming to `Container`, and sharing
  /// the same `Index`. (Like `String` does with its UTF-8, UTF-16,
  /// Unicode scalar and character views in the `Collection` world.)
  /// This rounding operation enables clients to convert/normalize valid index
  /// values in one container view into valid indices in another, allowing them
  /// to (easily) decide whether two (potentially misaligned) index values
  /// address the same element.
  ///
  /// The default implementation of this operation simply returns `index`.
  ///
  /// - Complexity: Recommended to be O(1). Conforming types must clearly
  ///    document deviations from this expectation.
  func index(alignedDown index: Index) -> Index

  /// Return the nearest valid index in this container greater than or equal to
  /// the given index value, which must be valid in at least one view of self.
  ///
  /// This operation is important for container types that provide multiple
  /// alternative projections (or "views") over the same underlying
  /// representation, with each view conforming to `Container`, and sharing
  /// the same `Index`. (Like `String` does with its UTF-8, UTF-16,
  /// Unicode scalar and character views in the `Collection` world.)
  /// This rounding operation enables clients to convert/normalize valid index
  /// values in one container view into valid indices in another, allowing them
  /// to (easily) decide whether two (potentially misaligned) index values
  /// address the same element.
  ///
  /// The default implementation of this operation simply returns `index`.
  ///
  /// - Complexity: Recommended to be O(1). Conforming types must clearly
  ///    document deviations from this expectation.
  func index(alignedUp index: Index) -> Index
```

```swift
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  var underestimatedCount: Int { 0 }

  mutating func skip(by n: inout Int) throws(Failure) {
    precondition(n > 0, "Cannot skip fewer than one item")
    let maxBufferSize = _producerBufferSize
    return try withTemporaryAllocation(
      of: Element.self,
      capacity: Swift.min(maxBufferSize, n)
    ) { buffer throws(Failure) in
      repeat {
        defer { n &-= buffer.count }
        guard try self.generate(into: &buffer) else { return }
        buffer.removeAll()
      } while n > 0
    }
  }

  mutating func skip(by n: Int) throws(Failure) -> Int {
    var remainder = n
    try self.skip(by: &remainder)
    return n - remainder
  }

  mutating func next() throws(Failure) -> Element? {
    try withTemporaryAllocation(
      of: Element.self, capacity: 1
    ) { buffer throws(Failure) in
      guard try self.generate(into: &buffer) else { return nil }
      return buffer.removeLast()
    }
  }
}
```

## In-Place Consumption

### `struct InputSpan`

```swift
struct InputSpan<Element: ~Copyable>: ~Copyable, ~Escapable {
  deinit
  init()
  init(buffer: UnsafeMutableBufferPointer<Element>, initializedCount: Int)
  consuming func finalize(for buffer: UnsafeMutableBufferPointer<Element>) -> Int

  var count: Int { get }
  var freeCapacity: Int { get }
  var isEmpty: Bool { get }
  var isFull: Bool { get }

  typealias Index = Int
  var startIndex: Index { get }
  var endIndex: Index { get }
  var indices: Range<Index> { get }

  subscript(_ index: Int) -> Element { borrow mutate }
  subscript(unchecked index: Int) -> Element { borrow mutate }

  mutating func swapAt(_ i: Index, _ j: Index)
  mutating func swapAt(unchecked i: Index, unchecked j: Index)

  mutating func prepend(_ value: consuming Element)
  mutating func removeFirst() -> Element
  mutating func removeFirst(_ k: Int)
  mutating func popFirst() -> Element?
  mutating func removeAll()
  mutating func prepend(moving source: UnsafeMutableBufferPointer<Element>)
  mutating func prepend(repeating repeatedValue: Element, count: Int) where Element: Copyable
  mutating func prepend(copying source: UnsafeBufferPointer<Element>) where Element: Copyable
  mutating func prepend(copying source: borrowing Span<Element>) where Element: Copyable

  var span: Span<Element> { get }
  var mutableSpan: MutableSpan<Element> { @_lifetime(&self) mutating get }

  @_lifetime(self: copy self)
  mutating func withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>, inout Int) throws(E) -> R
  ) throws(E) -> R

  mutating func consumePrefix(upTo n: Int) -> InputSpan<Element>
}
```

### `protocol Drain`

```swift
/// A type that supplies the values of an in-place consumable sequence through
/// a series of `InputSpan` instances. This iterator-like construct allows
/// directly consuming elements from some container's storage, in bulk,
/// without requiring them to be moved into any temporary buffer.
///
/// Drains are inherently also producers -- they can produce items by simply
/// moving their consumable contents to the client-supplied series of
/// output spans.
protocol Drain<Element>: CountedProducer, ~Copyable, ~Escapable
where Element: ~Copyable, Failure == Never
{
  /// Returns the next span of consumable items in the sequence underlying this
  /// drain, of at most the specified maximum count. A `maxCount` of nil
  /// indicates no limit, meaning that the client is able to process an
  /// arbitrarily large number of elements.
  ///
  /// Repeatedly calling this method returns, in order, all the elements of the
  /// underlying consumable sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return empty spans.
  ///
  /// While the returned input spans exist, they continue to mutate the drain,
  /// extending the exclusive access initiated by the call to
  /// `drainNext(maxCount:)`. To call this (or any other) method again, the
  /// returned input span needs to be consumed or otherwise destroyed.
  ///
  /// Once this method returns, the contents of the resulting input span are
  /// already destined for consumption, either gradually by invoking explicit
  /// methods such as `InputSpan.popFirst`, or all at once when
  /// the input span is destroyed. There is no way to "put items back" into
  /// the consumable sequence, other than by moving them into a
  /// temporary location and later reinserting them into the underlying
  /// construct through some type-specific operations.
  ///
  /// - Parameter maxCount: The maximum number of items that the client
  ///       is prepared to consume, or nil if the client is able to process an
  ///       arbitrary number of elements. If this is non-nil, then it must be a
  ///       positive integer.
  /// - Returns: An input span of at most the specified maximum count (if any),
  ///       containing the next elements of the underlying consumable sequence.
  ///       This method returns an empty span to indicate that it has reached
  ///       the end of the sequence.
  @_lifetime(&self)
  @_lifetime(self: copy self)
  mutating func drainNext(maxCount: Int) -> InputSpan<Element>
  // TODO: The primary use case does not need this to throw; do we need to allow that?
  // Note: making this failable is not entirely straightforward, as there is no
  // easy way to signal partial success -- conforming implementations
  // would likely need to store errors they encounter midway through a
  // chunk and report them at the beginning of the next iteration.
  // I take this as an indication that we don't need to do that.
  // (Contrast with this `Producer.generate(into:)`; the shape of that method
  // allows it to partially populate its client-supplied target and still
  // report an error.)
  //
  // Note: We can also express this with a higher-order shape:
  //
  //     mutating func drainNext<E: Error, R: ~Copyable>(
  //       _ body: (inout InputSpan<Element>) throws(E) -> R
  //     ) throws(E) -> R
  //
  // This would allow partial consumption, eliminating the need for
  // `maxCount`, but at the cost of having to deal with closures --
  // it can be tricky to elegantly flow data/control in & out higher-order
  // functions. Allowing the function argument to throw also precludes
  // the drain itself from throwing, unless they are both required
  // to use the same error type, which would be impractical.
}
```

```swift
extension Drain where Self: ~Copyable & ~Escapable, Element: ~Copyable  {
  @_lifetime(&self)
  mutating func drainNext() -> InputSpan<Element> {
    drainNext(maxCount: Int.max)
  }

  @_lifetime(target: copy target)
  mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Never) -> Bool {
    var source = self.drainNext(maxCount: target.freeCapacity)
    if source.isEmpty { return false }
    target._append(moving: &source)
    return true
  }

  @_lifetime(self: copy self)
  public mutating func skip(by n: inout Int) {
    precondition(n >= 0, "Cannot skip a negative number of elements")
    while n > 0 {
      let span = drainNext(maxCount: n)
      guard !span.isEmpty else { return }
      n &-= span.count
    }
  }
}
```

## Range-Replaceable Containers

```swift
protocol RangeReplaceableContainer<Element>
: Container, ~Copyable, ~Escapable
where
  Element: ~Copyable,
  Index: Comparable // For `Range<Index>`
{
  // MARK: Core requirements

  var freeCapacity: Int { get }

  mutating func replace<E: Error>(
    removing subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  associatedtype SubrangeConsumer: Drain<Element> & ~Copyable & ~Escapable

  @_lifetime(&self)
  mutating func consume(_ subrange: Range<Index>) -> SubrangeConsumer

  // MARK: Requirements with default implementations

  mutating func remove(at index: Index) -> Element
  mutating func removeSubrange(_ bounds: Range<Index>)
  mutating func removeAll()
  mutating func removeFirst() -> Element
  mutating func removeFirst(_ n: Int)
  mutating func _customRemoveLast() -> Element?
  mutating func _customRemoveLast(_ n: Int) -> Bool

  mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Index,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  mutating func insert(_ item: consuming Element, at index: Index)

  mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  mutating func append(_ item: consuming Element)
}
```

(TODO: Go through the myriad standard algorithms, either here or in thematic sections below.)

### Index Ranges and Range Expressions

```swift
protocol RangeExpression2<Bound>: RangeExpression { // Oof
  override associatedtype Bound: Comparable

  func relative<C: Container & ~Copyable & ~Escapable>(
    to container: borrowing C
  ) -> Range<Bound> where C.Index == Bound, C.Element: ~Copyable

  override func contains(_ element: Bound) -> Bool
}

extension Range: RangeExpression2 {...}
extension ClosedRange: RangeExpression2 {...}
extension PartialRangeFrom: RangeExpression2 {...}
extension PartialRangeUpTo: RangeExpression2 {...}
extension PartialRangeThrough: RangeExpression2 {...}
```

### Adding Elements to a Container

### Replacing Subranges

### Consuming Subranges

### Removing Subranges

### Dynamic Containers

```swift
public protocol DynamicContainer<Element>: RangeReplaceableContainer, ~Copyable
where Element: ~Copyable
{
  init()
  init(minimumCapacity: Int)

  mutating func reserveCapacity(_ minimumCapacity: Int)

  /// The number of items that can be added to the container without forcing
  /// it to allocate extra storage. This is primarily intended to serve as a
  /// hint for the batch size of appends, to allow bulk operation even if
  /// the number of items to be appended is not known in advance.
  ///
  /// If the container does not have simple, predictable allocation behavior,
  /// then this should return the size of the container's primitive allocation
  /// unit. For example, in a balanced rope that organizes its contents into a
  /// tree of fixed-capacity nodes, it may be a good choice to use the maximum
  /// node size as the (constant) free capacity, even though it may not
  /// correlate exactly with actual allocation behavior.
  ///
  /// If a container always reports a free capacity of 0, then appending a
  /// sequence of items of an unknown size may run slower than expected.
  ///
  /// - Complexity: O(1)
  var freeCapacity: Int { get }
}
```

(TODO: Describe the standard algorithms.)

## Rejected Directions

### Cursors

### Index Rounding Operations

## Potential Future Directions

### Support for Nonescapable `Element` Types

### Factoring Indexing Out of Containers

(`protocol Indexable` with no element access; allows indexable producers, with the cost of greatly increased conceptual complexity.)

### A Protocol for Directly Initializing Storage
