# ``TrailingElementsModule``

## Overview

This module provides types that manage values consisting of a fixed-size header
plus variable-size storage that follows that header in memory. The types are
similar in design to the [`ManagedBuffer`](https://developer.apple.com/documentation/swift/managedbuffer) type in the standard library, but are non-copyable types that eliminate the need for reference counting and heap allocation.


The ``TrailingArray`` type can be used for types consisting of a header after which there are some (dynamic) number of elements. For example, we could have a `Coordinates` type that is followed by `Point` elements:

```swift
struct Point {
  var x: Int
  var y: Int
}

struct Coordinates {
  var numPoints: Int
  // Points will follow in memory
}
```

To use ``TrailingArray``, the `Coordinates` type must conform to the
``TrailingElements`` protocol, specifying the type of the trailing elements (`Point`) and the number of trailing elements (`numPoints`), like this:

```swift
extension Coordinates: TrailingElements {
    typealias Element = Point
    var trailingCount: Int { numPoints }
}
```

Now, we can create an intrusive managed buffer. The easiest way is to do so on the heap:

```swift
var coords = TrailingArray(header: Coordinates(numPoints: 3)) { outputSpan in 
  outputSpan.append(Point(x: 1, y: 2))
  outputSpan.append(Point(x: 2, y: 3))
  outputSpan.append(Point(x: 3, y: 4))
}
```

Subscripting an ``TrailingArray`` provides access to the elements. One can also use the ``TrailingArray.elements`` or ``TrailingArray.mutableElements`` properties to get a [`Span`](https://developer.apple.com/documentation/swift/span) or [`MutableSpan`](https://developer.apple.com/documentation/swift/mutablespan) over the elements, respectively. Once the `coords` value is no longer used, the buffer will be deallocated.

```swift
print(coords[0])    // displays Point(x: 1, y: 2)
```

### Stack allocation
If heap allocation is not acceptable, use the static method ``TrailingArray.withTemporaryValue`` to produce a temporary instance of ``TrailingArray`` that can be used within the given body closure, like this:

```swift
TrailingArray.withTemporaryValue(header: Coordinates(numPoints: 3), repeating: Point(x: 0, y: 0)) { coords in
    coords[0] = Point(x: 1, y: 2)
    coords[1] = Point(x: 2, y: 3)
    coords[2] = Point(x: 3, y: 4)

    // operate on coords
}
```

### Interoperability with unsafe C APIs
``TrailingArray`` provides facilities for working with the underlying unsafe pointers, which can be useful when interoperating with C APIs. ``TrailingArray`` can take ownership of a heap-allocated pointer to its `Header` type (such as one might get back from a C API api) using `init(consuming:)`:

```swift
init(consuming pointer: UnsafeMutablePointer<Header>)
```

or give up its pointer to hand off to C with `leakStorage`:

```swift
consuming func leakStorage() -> UnsafeMutablePointer<Header>
```

Unsafe pointers can be accessed via the `withUnsafeMutablePointer*` family of methods to access a pointer to the header, the trailing elements, or both.

### Flexible array members
One of the uses for this module is to work with C types that involve [flexible array members](https://en.wikipedia.org/wiki/Flexible_array_member), which are described via an incomplete array at the end of a struct. Here is the C equivalent to the `Coordinates` structure shown above:

```c
struct coordinates_t {
  unsigned num_points;
  struct point_t points[];
};
```

The C `coordinates_t` type can extended to conform to the ``TrailingElements`` protocol, allowing it to be used directly with ``TrailingArray``:

```swift
extension coordinates_t: TrailingElements {
    typealias Element = point_t
    var trailingCount: Int { num_points }
}
```

This provides safer access patterns for C flexible array members, introducing safe memory ownership and bounds-safety checking.

### ``TrailingPadding``

This module also provides a lower-level primitive called ``TrailingPadding`` that references heap- or stack-allocated data with a particular type (also called the `Header` type) but whose allocation is larger than the size of the header itself. The API is roughly similar to that of ``TrailingArray``, but it has no notion of what data might follow the `Header` instance. Instead, its initializer takes a "total size" for the allocation size, leaving the size calculation to the user:

```swift
var padded = TrailingPadding(header: SomeType(), totalSize: getSizeOfSomeTypeWithPadding())
```

## Topics

### Structures

- ``TrailingArray``
- ``TrailingPadding``

### Protocols
- ``TrailingElements`
