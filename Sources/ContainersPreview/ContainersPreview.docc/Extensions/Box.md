# ``BasicContainers/RigidArray``

## Topics

### Creating a rigid array

- ``init()``
- ``init(capacity:)``
- ``init(capacity:initializingWith:)``
- ``init(repeating:count:)``
- ``init(capacity:copying:)-(_,Sequence<Element>)``
- ``init(capacity:copying:)-(_,Collection<Element>)``

### Inspecting a rigid array

- ``isEmpty``
- ``isFull``
- ``count``
- ``capacity``
- ``freeCapacity``

### Indices

- ``startIndex``
- ``endIndex``
- ``indices``

### Accessing elements

- ``subscript(position:)``
- ``swapAt(_:_:)``
- ``edit(_:)``

### Memory management

- ``reallocate(capacity:)``
- ``reserveCapacity(_:)``
- ``copy()``
- ``copy(capacity:)``

### Spans

- ``span``
- ``span(after:)``
- ``span(before:)``
- ``mutableSpan``
- ``mutableSpan(after:)``
- ``mutableSpan(before:)``

### Appending items

- ``append(_:)``
- ``pushLast(_:)``
- ``append(count:initializingWith:)``
- ``append(moving:)-(UnsafeMutableBufferPointer<Element>)``
- ``append(moving:)-(OutputSpan<Element>)``
- ``append(moving:)-(RigidArray<Element>)``
- ``append(copying:)-(Sequence<Element>)``
- ``append(copying:)-(Span<Element>)``
- ``append(copying:)-(UnsafeBufferPointer<Element>)``
- ``append(copying:)-(UnsafeMutableBufferPointer<Element>)``

### Inserting items

- ``insert(_:at:)``
- ``insert(count:at:initializingWith:)``
- ``insert(moving:at:)-(OutputSpan<Element>,_)``
- ``insert(moving:at:)-(RigidArray<Element>,_)``
- ``insert(moving:at:)-(UnsafeMutableBufferPointer<Element>,_)``
- ``insert(consuming:at:)``
- ``insert(copying:at:)-(Collection<Element>,_)``
- ``insert(copying:at:)-(Span<Element>,_)``
- ``insert(copying:at:)-(UnsafeBufferPointer<Element>,_)``
- ``insert(copying:at:)-(UnsafeMutableBufferPointer<Element>,_)``

### Replacing items

- ``replaceSubrange(_:newCount:initializingWith:)``
- ``replaceSubrange(_:moving:)-(_,OutputSpan<Element>)``
- ``replaceSubrange(_:moving:)-(_,RigidArray<Element>))``
- ``replaceSubrange(_:moving:)-(_,UnsafeMutableBufferPointer<Element>)``
- ``replaceSubrange(_:consuming:)``
- ``replaceSubrange(_:copying:)-(_,Collection<Element>)``
- ``replaceSubrange(_:copying:)-(_,Span<Element>)``
- ``replaceSubrange(_:copying:)-(_,UnsafeBufferPointer<Element>)``
- ``replaceSubrange(_:copying:)-(_,UnsafeMutableBufferPointer<Element>)``

### Removing items

- ``removeAll()``
- ``removeLast()``
- ``popLast()``
- ``removeLast(_:)``
- ``remove(at:)``
- ``removeSubrange(_:)-(Range<Int>)``
- ``removeSubrange(_:)-(RangeExpression<Int>)``
