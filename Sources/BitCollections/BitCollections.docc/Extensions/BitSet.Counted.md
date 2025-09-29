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

- ``intersection(_:)-(Self)``
- ``intersection(_:)-(BitSet)``
- ``intersection(_:)-(Range<Int>)``
- ``intersection(_:)-(Sequence<Int>)

- ``union(_:)-(Self)``
- ``union(_:)-(BitSet)``
- ``union(_:)-(Range<Int>)``
- ``union(_:)-(Sequence<Int>)``

- ``subtracting(_:)-(Self)``
- ``subtracting(_:)-(BitSet)``
- ``subtracting(_:)-(Range<Int>)``
- ``subtracting(_:)-(Sequence<Int>)``

- ``symmetricDifference(_:)-(Self)``
- ``symmetricDifference(_:)-(BitSet)``
- ``symmetricDifference(_:)-(Range<Int>)``
- ``symmetricDifference(_:)-(Sequence<Int>)``

- ``formIntersection(_:)-(Self)``
- ``formIntersection(_:)-(BitSet)``
- ``formIntersection(_:)-(Range<Int>)``
- ``formIntersection(_:)-(Sequence<Int>)``

- ``formUnion(_:)-(Self)``
- ``formUnion(_:)-(BitSet)``
- ``formUnion(_:)-(Range<Int>)``
- ``formUnion(_:)-(Sequence<Int>)``

- ``subtract(_:)-(Self)``
- ``subtract(_:)-(BitSet)``
- ``subtract(_:)-(Range<Int>)``
- ``subtract(_:)-(Sequence<Int>)``

- ``formSymmetricDifference(_:)-(Self)``
- ``formSymmetricDifference(_:)-(BitSet)``
- ``formSymmetricDifference(_:)-(Range<Int>)``
- ``formSymmetricDifference(_:)-(Sequence<Int>)``

### Binary Set Predicates

- ``==(_:_:)``
- ``isEqualSet(to:)-(Self)``
- ``isEqualSet(to:)-(BitSet)``
- ``isEqualSet(to:)-(Range<Int>)``
- ``isEqualSet(to:)-(Sequence<Int>)``

- ``isSubset(of:)-(Self)``
- ``isSubset(of:)-(BitSet)``
- ``isSubset(of:)-(Range<Int>)``
- ``isSubset(of:)-(Sequence<Int>)``

- ``isSuperset(of:)-(Self)``
- ``isSuperset(of:)-(BitSet)``
- ``isSuperset(of:)-(Range<Int>)``
- ``isSuperset(of:)-(Sequence<Int>)``

- ``isStrictSubset(of:)-(Self)``
- ``isStrictSubset(of:)-(BitSet)``
- ``isStrictSubset(of:)-(Range<Int>)``
- ``isStrictSubset(of:)-(Sequence<Int>)``

- ``isStrictSuperset(of:)-(Self)``
- ``isStrictSuperset(of:)-(BitSet)``
- ``isStrictSuperset(of:)-(Range<Int>)``
- ``isStrictSuperset(of:)-(Sequence<Int>)``

- ``isDisjoint(with:)-(Self)``
- ``isDisjoint(with:)-(BitSet)``
- ``isDisjoint(with:)-(Range<Int>)``
- ``isDisjoint(with:)-(Sequence<Int>)``
