# Deque

A collection implementing a double-ended queue with support for both unlimited and fixed-capacity variants.

## Declaration

```swift
import DequeModule

@frozen struct Deque<Element>
```

## Overview

`Deque` (pronounced "deck") implements an ordered random-access
collection that supports efficient insertions and removals from both
ends. Deques can be created with unlimited capacity (default behavior) or
with a fixed maximum capacity for use as ring buffers.

```swift
var colors: Deque = ["red", "yellow", "blue"]
var ringBuffer = Deque<Int>(fixedCapacity: 100)
```

Deques implement the same indexing semantics as arrays: they use integer
indices, and the first element of a nonempty deque is always at index zero.
Like arrays, deques conform to `RangeReplaceableCollection`,
`MutableCollection` and `RandomAccessCollection`, providing a familiar
interface for manipulating their contents:

```swift
print(colors[1]) // "yellow"
print(colors[3]) // Runtime error: Index out of range

colors.insert("green", at: 1)
// ["red", "green", "yellow", "blue"]

colors.remove(at: 2) // "yellow"
// ["red", "green", "blue"]
```

Like all variable-size collections on the standard library, `Deque`
implements value semantics: each deque has an independent value that
includes the values of its elements. Modifying one deque does not affect any
others:

```swift
var copy = deque
copy[1] = "violet"
print(copy)  // ["red", "violet", "blue"]
print(deque) // ["red", "green", "blue"]
```

This is implemented with the copy-on-write optimization. Multiple copies of
a deque share the same underlying storage until you modify one of the
copies. When that happens, the deque being modified replaces its storage
with a uniquely owned copy of itself, which is then modified in place.

`Deque` stores its elements in a circular buffer, which allows efficient
insertions and removals at both ends of the collection; however, this comes
at the cost of potentially discontiguous storage. In contrast, `Array` is
(usually) backed by a contiguous buffer, where new data can be efficiently
appended to the end, but inserting at the front is relatively slow, as
existing elements need to be shifted to make room.

This difference in implementation means that while the interface of a deque
is very similar to an array, the operations have different performance
characteristics. Mutations near the front are expected to be significantly
faster in deques, but arrays may measure slightly faster for general
random-access lookups.

Deques provide a handful of additional operations that make it easier to
insert and remove elements at the front. This includes queue operations such
as `popFirst` and `prepend`, including the ability to directly prepend a
sequence of elements:

```swift
colors.append("green")
colors.prepend("orange")
// colors: ["orange", "red", "blue", "yellow", "green"]

colors.popLast() // "green"
colors.popFirst() // "orange"
// colors: ["red", "blue", "yellow"]

colors.prepend(contentsOf: ["purple", "teal"])
// colors: ["purple", "teal", "red", "blue", "yellow"]
```

## Fixed-Capacity Deques

Deques can be created with a fixed maximum capacity, making them ideal for use
as ring buffers where memory allocation must be controlled or avoided.

```swift
var buffer = Deque<String>(fixedCapacity: 3)
buffer.append("A")     // ["A"]
buffer.append("B")     // ["A", "B"]
buffer.append("C")     // ["A", "B", "C"]
buffer.append("D")     // ["B", "C", "D"] - "A" was automatically removed

buffer.prepend("X")    // ["X", "B", "C"] - "D" was automatically removed
```

When a fixed-capacity deque reaches its maximum size, new elements automatically
replace the oldest elements. Appending removes elements from the front, while
prepending removes elements from the back.

Fixed-capacity deques provide several properties to monitor their state:

```swift
let buffer = Deque<Int>(fixedCapacity: 10)

print(buffer.isFixedCapacity)      // true
print(buffer.maxCapacity)          // Optional(10)
print(buffer.isFull)               // false
print(buffer.remainingCapacity)    // 10
```

This makes fixed-capacity deques particularly useful for audio/video processing,
logging systems with automatic rotation, real-time systems requiring predictable
memory usage, and embedded systems with memory constraints.

Unlike arrays, deques do not currently provide direct unsafe access to their
underlying storage. Regular deques lack a `capacity` property since the size of
the storage buffer is an implementation detail. However, deques do provide a
`reserveCapacity` method, and fixed-capacity deques expose their capacity
information through `maxCapacity`, `isFull`, and `remainingCapacity` properties.
