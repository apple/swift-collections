# ``Collections``

**Swift Collections** is an open-source package of data structure implementations for the Swift programming language.

This package provides separate modules for each group of data structures it implements. For instance, if you only need a double-ended queue type, you can pull in only that by importing `DequeModule`.

The top-level module `Collections` imports and reexports each of these smaller packages. Importing this module is a useful shortcut if you want to import all data structures, or if you don't care about bringing in more code than you need.

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
