# ``Collections``

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

## Overview

### Modules

- [**Basic Containers**](./basiccontainers) - Defines [`UniqueArray`][UniqueArray] and [`RigidArray`][RigidArray], noncopyable array variants trading some of `Array`'s flexibility for more predictable performance.
- [**Bit Collections**](./bitcollections) - Defines [`BitSet`](./bitcollections/bitset) and [`BitArray`](./bitcollections/bitarray), dynamic bit collections.
- [**Deque Module**](./dequemodule) - Defines [`Deque<Element>`](./dequemodule/deque), a double-ended queue backed by a ring buffer. Deques are range-replaceable, mutable, random-access collections.
- [**Heap Module**](./heapmodule) - Defines [`Heap`](./heapmodule/heap), a min-max heap backed by an array, suitable for use as a priority queue.
- [**Ordered Collections**](./orderedcollections) - Defines [`OrderedSet<Element>`](./orderedcollections/orderedset), a variant of the standard `Set` where the order of items is well-defined and items can be arbitrarily reordered. Uses a `ContiguousArray` as its backing store, augmented by a separate hash table of bit packed offsets into it. [`OrderedDictionary<Key, Value>`](./orderedcollections/ordereddictionary), an ordered variant of the standard `Dictionary`, providing similar benefits.
- [**Hash Tree Collections**](./hashtreecollections) - Defines [`TreeSet`](./hashtreecollections/treeset) and [`TreeDictionary`](./hashtreecollections/treedictionary), persistent hashed collections implementing Compressed Hash-Array Mapped Prefix Trees (CHAMP). These work similar to the standard `Set` and `Dictionary`, but they excel at use cases that mutate shared copies, offering dramatic memory savings and radical time improvements.
- [**Trailing Elements Module**](./trailingelementsmodule) - Defines [`TrailingArray`](./trailingarray), a low-level, ownership-aware variant of `ManagedBuffer`, for interoperability with C constructs that consist of a fixed-size header directly followed by variable-size storage buffer.

### Additional Resources

- [`Swift Collections` on GitHub](https://github.com/apple/swift-collections/)
- [`Swift Collections` on the Swift Forums](https://forums.swift.org/c/related-projects/collections/72)
