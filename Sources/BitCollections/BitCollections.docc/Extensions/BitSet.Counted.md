# ``BitCollections/BitSet/Counted-swift.struct``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Collection Views

- ``uncounted``

### Creating a Set

- ``init()``
- ``init(reservingCapacity:)``
- ``init(_:)-(BitSet)``
- ``init(_:)-(BitArray)``
- ``init(_:)-(Range<Int>)``
- ``init(_:)-(Sequence<Int>)``
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

- ``subscript(member:)``
- ``subscript(members:)-(Range<Int>)``
- ``subscript(members:)-(RangeExpression<Int>)``
- ``min()``
- ``max()``
- ``sorted()``

### Binary Set Operations

- ``intersection(_:)-(BitSet.Counted)``
- ``intersection(_:)-(BitSet)``
- ``intersection(_:)-(Range<Int>)``
- ``intersection(_:)-(Sequence<Int>)``

- ``union(_:)-(BitSet.Counted)``
- ``union(_:)-(BitSet)``
- ``union(_:)-(Range<Int>)``
- ``union(_:)-(Sequence<Int>)``

- ``subtracting(_:)-(BitSet.Counted)``
- ``subtracting(_:)-(BitSet)``
- ``subtracting(_:)-(Range<Int>)``
- ``subtracting(_:)-(Sequence<Int>)``

- ``symmetricDifference(_:)-(BitSet.Counted)``
- ``symmetricDifference(_:)-(BitSet)``
- ``symmetricDifference(_:)-(Range<Int>)``
- ``symmetricDifference(_:)-(Sequence<Int>)``

- ``formIntersection(_:)-(BitSet.Counted)``
- ``formIntersection(_:)-(BitSet)``
- ``formIntersection(_:)-(Range<Int>)``
- ``formIntersection(_:)-(Sequence<Int>)``

- ``formUnion(_:)-(BitSet.Counted)``
- ``formUnion(_:)-(BitSet)``
- ``formUnion(_:)-(Range<Int>)``
- ``formUnion(_:)-(Sequence<Int>)``

- ``subtract(_:)-(BitSet.Counted)``
- ``subtract(_:)-(BitSet)``
- ``subtract(_:)-(Range<Int>)``
- ``subtract(_:)-(Sequence<Int>)``

- ``formSymmetricDifference(_:)-(BitSet.Counted)``
- ``formSymmetricDifference(_:)-(BitSet)``
- ``formSymmetricDifference(_:)-(Range<Int>)``
- ``formSymmetricDifference(_:)-(Sequence<Int>)``

### Binary Set Predicates

- ``==(_:_:)``
- ``isEqualSet(to:)-(BitSet.Counted)``
- ``isEqualSet(to:)-(BitSet)``
- ``isEqualSet(to:)-(Range<Int>)``
- ``isEqualSet(to:)-(Sequence<Int>)``

- ``isSubset(of:)-(BitSet.Counted)``
- ``isSubset(of:)-(BitSet)``
- ``isSubset(of:)-(Range<Int>)``
- ``isSubset(of:)-(Sequence<Int>)``

- ``isSuperset(of:)-(BitSet.Counted)``
- ``isSuperset(of:)-(BitSet)``
- ``isSuperset(of:)-(Range<Int>)``
- ``isSuperset(of:)-(Sequence<Int>)``

- ``isStrictSubset(of:)-(BitSet.Counted)``
- ``isStrictSubset(of:)-(BitSet)``
- ``isStrictSubset(of:)-(Range<Int>)``
- ``isStrictSubset(of:)-(Sequence<Int>)``

- ``isStrictSuperset(of:)-(BitSet.Counted)``
- ``isStrictSuperset(of:)-(BitSet)``
- ``isStrictSuperset(of:)-(Range<Int>)``
- ``isStrictSuperset(of:)-(Sequence<Int>)``

- ``isDisjoint(with:)-(BitSet.Counted)``
- ``isDisjoint(with:)-(BitSet)``
- ``isDisjoint(with:)-(Range<Int>)``
- ``isDisjoint(with:)-(Sequence<Int>)``
