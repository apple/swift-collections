# ``BitCollections/BitSet``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Creating a Bit Set

- ``init()``
- ``init(reservingCapacity:)``
- ``init(_:)-(Sequence<Int>)``
- ``init(_:)-(Range<Int>)``
- ``init(_:)-(BitArray)``
- ``init(_:)-(BitSet.Counted)``
- ``init(bitPattern:)``
- ``init(words:)``
- ``random(upTo:)``
- ``random(upTo:using:)``

### Finding Elements

- ``contains(_:)``
- ``firstIndex(of:)``
- ``lastIndex(of:)``

### Adding and Updating Elements

- ``insert(_:)``
- ``update(with:)``

### Removing Elements

- ``filter(_:)``
- ``remove(_:)``
- ``remove(at:)``

### Sorted Set Operations

- ``subscript(position:)``
- ``subscript(member:)``
- ``subscript(members:)-(RangeExpression<Int>)``
- ``subscript(members:)-(Range<Int>)``
- ``min()``
- ``max()``
- ``sorted()``

### Combining Sets

- ``intersection(_:)-(Self)``
- ``intersection(_:)-(Range<Int>)``
- ``intersection(_:)-(BitSet.Counted)``
- ``intersection(_:)-(Sequence<Int>)``

- ``union(_:)-(Self)``
- ``union(_:)-(Range<Int>)``
- ``union(_:)-(BitSet.Counted)``
- ``union(_:)-(Sequence<Int>)``

- ``subtracting(_:)-(Self)``
- ``subtracting(_:)-(Range<Int>)``
- ``subtracting(_:)-(BitSet.Counted)``
- ``subtracting(_:)-(Sequence<Int>)``

- ``symmetricDifference(_:)-(Self)``
- ``symmetricDifference(_:)-(Range<Int>)``
- ``symmetricDifference(_:)-(Counted)``
- ``symmetricDifference(_:)-(Sequence<Int>)``

- ``formIntersection(_:)-(Self)``
- ``formIntersection(_:)-(Range<Int>)``
- ``formIntersection(_:)-(BitSet.Counted)``
- ``formIntersection(_:)-(Sequence<Int>)``

- ``formUnion(_:)-72o7q``
- ``formUnion(_:)-370hb``
- ``formUnion(_:)-7tw8j``
- ``formUnion(_:)-12ll3``

- ``subtract(_:)-(Self)``
- ``subtract(_:)-(Range<Int>)``
- ``subtract(_:)-(BitSet.Counted)``
- ``subtract(_:)-(Sequence<Int>)``

- ``formSymmetricDifference(_:)-(Self)``
- ``formSymmetricDifference(_:)-(Range<Int>)``
- ``formSymmetricDifference(_:)-(BitSet.Counted)``
- ``formSymmetricDifference(_:)-(Sequence<Int>)``

### Comparing Sets

- ``==(_:_:)``
- ``isEqualSet(to:)-(Self)``
- ``isEqualSet(to:)-(Range<Int>)``
- ``isEqualSet(to:)-(BitSet.Counted)``
- ``isEqualSet(to:)-(Sequence<Int>)``

- ``isSubset(of:)-(Self)``
- ``isSubset(of:)-(Range<Int>)``
- ``isSubset(of:)-(BitSet.Counted)``
- ``isSubset(of:)-(Sequence<Int>)``

- ``isSuperset(of:)-(Self)
- ``isSuperset(of:)-(Range<Int>)``
- ``isSuperset(of:)-(BitSet.Counted)``
- ``isSuperset(of:)-(Sequence<Int>)``

- ``isStrictSubset(of:)-(Self)``
- ``isStrictSubset(of:)-(Range<Int>)``
- ``isStrictSubset(of:)-(BitSet.Counted)``
- ``isStrictSubset(of:)-(Sequence<Int>)``

- ``isStrictSuperset(of:)-(Self)``
- ``isStrictSuperset(of:)-(Range<Int>)``
- ``isStrictSuperset(of:)-(BitSet.Counted)``
- ``isStrictSuperset(of:)-(Sequence<Int>)``

- ``isDisjoint(with:)-(Self)
- ``isDisjoint(with:)-(Range<Int>)``
- ``isDisjoint(with:)-(BitSet.Counted)``
- ``isDisjoint(with:)-(Sequence<Int>)``

### Memory Management

- ``reserveCapacity(_:)``

### Collection Views

- ``Counted``
- ``counted``
