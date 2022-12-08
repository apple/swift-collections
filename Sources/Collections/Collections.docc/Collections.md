# ``Collections``

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

The package currently provides the following implementations:

- ``Deque``, a double-ended queue backed by a ring buffer. Deques are range-replaceable, mutable, random-access collections.

- ``OrderedSet``, a variant of the standard `Set` where the order of items is well-defined and items can be arbitrarily reordered. Uses a `ContiguousArray` as its backing store, augmented by a separate hash table of bit packed offsets into it.

- ``OrderedDictionary``, an ordered variant of the standard `Dictionary`, providing similar benefits.

## Modules

This package provides separate products for each group of data structures it implements:

- ``Collections``. This is an umbrella module that exports every other public module in the package.
- ``DequeModule``. Defines ``Deque``.
- ``OrderedCollections``. Defines the ordered collection types ``OrderedSet`` and ``OrderedDictionary``.

If you aren't constrained by code size limitations, then importing ``Collections`` is the simplest way to start using the package.

```swift
import Collections

var deque: Deque = ["Ted", "Rebecca"]
deque.prepend("Keeley")

let people = OrderedSet(deque)
people.contains("Rebecca") // true
```

#### Additional Resources

- [`Swift Collections` on GitHub](https://github.com/apple/swift-collections/)
- [`Swift Collections` on the Swift Forums](https://forums.swift.org/c/related-projects/collections/72)

## Topics

### Deque Module

- ``Deque``

### Ordered Collections

- ``OrderedSet``
- ``OrderedDictionary``
