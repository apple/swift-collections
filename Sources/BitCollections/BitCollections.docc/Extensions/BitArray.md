# ``BitCollections/BitArray``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Creating a Bit Array

- ``init()``
- ``init(minimumCapacity:)``
- ``init(_:)-(Sequence<Bool>)``
- ``init(repeating:count:)``
- ``init(_:)-(BitArray)``
- ``init(_:)-(BitArray.SubSequence)``
- ``init(_:)-(BitSet)``
- ``init(bitPattern:)``
- ``randomBits(count:)``
- ``randomBits(count:using:)``

### Accessing Elements

- ``subscript(position:)`
- ``first``
- ``last``

### Adding Elements

- ``append(_:)``
- ``append(contentsOf:)-(BitArray)``
- ``append(contentsOf:)-(BitArray.SubSequence)``
- ``append(contentsOf:)-(Sequence<Bool>)``
- ``append(repeating:count:)``
- ``insert(_:at:)``
- ``insert(contentsOf:at:)-(Collection<Bool>,_)``
- ``insert(contentsOf:at:)-(BitArray,_)``
- ``insert(contentsOf:at:)-(BitArray.SubSequence,_)``
- ``insert(repeating:count:at:)``
- ``truncateOrExtend(toCount:with:)``

### Removing Elements

- ``remove(at:)``
- ``removeAll(keepingCapacity:)``
- ``removeAll(where:)``
- ``removeSubrange(_:)``
- ``removeLast()``
- ``removeLast(_:)``
- ``removeFirst()``
- ``removeFirst(_:)``
- ``popLast()``

### Replacing Elements

- ``fill(in:with:)-(RangeExpression<Int>,_)``
- ``fill(in:with:)-(Range<Int>,_)``
- ``fill(with:)``
- ``replaceSubrange(_:with:)-(_,Collection<Bool>)``
- ``replaceSubrange(_:with:)-(_,BitArray)``
- ``replaceSubrange(_:with:)-(_,BitArray.SubSequence)``

### Bitwise Operations

- ``toggleAll()``
- ``toggleAll(in:)-(Range<Int>)``
- ``toggleAll(in:)-(RangeExpression<Int>)``
- ``maskingShiftLeft(by:)``
- ``maskingShiftRight(by:)``
- ``resizingShiftLeft(by:)``
- ``resizingShiftRight(by:)``
