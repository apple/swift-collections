# ``BasicContainers/TemporaryArray``

## Topics

### Creating a Temporary Array

- ``withTemporaryArray(of:capacity:_:)``
- ``init()``
- ``init(capacity:)``
- ``init(capacity:initializingWith:)``

### Inspecting a Temporary Array

- ``isEmpty``
- ``count``
- ``capacity``
- ``freeCapacity``
- ``isTriviallyIdentical(to:)``

### Indices

- ``Index``
- ``startIndex``
- ``endIndex``
- ``indices``

### Accessing Elements

- ``subscript(_:)``
- ``swapAt(_:_:)``
- ``edit(_:)``

### Memory Management

- ``reallocate(capacity:)``
- ``reserveCapacity(_:)``

### Moving and Copying Out

- ``take()``
- ``clone()``
- ``clone(capacity:)``

### Spans

- ``span``
- ``mutableSpan``
- ``nextSpan(after:maximumCount:)``
- ``nextMutableSpan(after:maximumCount:)``
- ``previousSpan(before:maximumCount:)``

### Appending Items

- ``append(_:)``
- ``append(addingCount:initializingWith:)``
- ``append(repeating:count:)``
- ``append(moving:)-(UnsafeMutableBufferPointer<Element>)``
- ``append(moving:)-(OutputSpan<Element>)``
- ``append(copying:)-(Sequence<Element>)``
- ``append(copying:)-(Span<Element>)``
- ``append(copying:)-(UnsafeBufferPointer<Element>)``
- ``append(copying:)-(UnsafeMutableBufferPointer<Element>)``
