# ``HashTreeCollections/TreeSet``

### Implementation Details

`TreeSet` and `TreeDictionary` are based on a Swift adaptation
of the *Compressed Hash-Array Mapped Prefix Tree* (CHAMP) data structure.

- Michael J Steindorfer and Jurgen J Vinju. Optimizing Hash-Array Mapped
   Tries for Fast and Lean Immutable JVM Collections. In *Proc.
   International Conference on Object-Oriented Programming, Systems,
   Languages, and Applications,* pp. 783-800, 2015.
   https://doi.org/10.1145/2814270.2814312

In this setup, the members of such a collection are organized into a tree
data structure based on their hash values. For example, assuming 16 bit hash
values sliced into 4-bit chunks, each node in the prefix tree would have
sixteen slots (one for each digit), each of which may contain a member, a
child node reference, or it may be empty. A `TreeSet` containing the
three items `Maximo`, `Julia` and `Don Pablo` (with hash values of `0x2B65`,
`0xA69F` and `0xADA1`, respectively) may be organized into a prefix tree of
two nodes:

```
┌0┬1┬2───────┬3┬4┬5┬6┬7┬8┬9┬A──┬B┬C┬D┬E┬F┐
│ │ │ Maximo │ │ │ │ │ │ │ │ • │ │ │ │ │ │
└─┴─┴────────┴─┴─┴─┴─┴─┴─┴─┴─┼─┴─┴─┴─┴─┴─┘
                             ╎
                             ╎
            ┌0┬1┬2┬3┬4┬5┬6───┴──┬7┬8┬9┬A┬B┬C┬D──────────┬E┬F┐
            │ │ │ │ │ │ │ Julia │ │ │ │ │ │ │ Don Pablo │ │ │
            └─┴─┴─┴─┴─┴─┴───────┴─┴─┴─┴─┴─┴─┴───────────┴─┴─┘
```

The root node directly contains `Maximo`, because it is the only set member
whose hash value starts with `2`. However, the first digits of the hashes of
`Julia` and `Don Pablo` are both `A`, so these items reside in a separate
node, one level below the root.

(To save space, nodes are actually stored in a more compact form, with just
enough space allocated to store their contents: empty slots do not take up
any room. Hence the term "compressed" in "Compressed Hash-Array Mapped
Prefix Tree".)

The resulting tree structure lends itself well to sharing nodes across
multiple collection values. Inserting or removing an item in a completely
shared tree requires copying at most log(n) nodes -- every node along the
path to the item needs to be uniqued, but all other nodes can remain shared.
While the cost of copying this many nodes isn't trivial, it is dramatically
lower than the cost of having to copy the entire data structure, like the
standard `Set` has to do.

When looking up a particular member, we descend from the root node,
following along the path specified by successive digits of the member's hash
value. As long as hash values are unique, we will either find the member
we're looking for, or we will know for sure that it does not exist in the
set.

In practice, hash values aren't guaranteed to be unique though. Members with
conflicting hash values need to be collected in special collision nodes that
are able to grow as large as necessary to contain all colliding members that
share the same hash. Looking up a member in one of these nodes requires a
linear search, so it is crucial that such collisions do not happen often.

As long as `Element` properly implements `Hashable`, lookup operations in a
`TreeSet` are expected to be able to decide whether the set contains a
particular item by looking at no more than a constant number of items on
average -- typically they will need to compare against just one member.

## Topics

### Creating a Set

- ``init()``
- ``init(_:)-2uun3``
- ``init(_:)-714nu``
- ``init(_:)-6lt4a``

### Finding Elements

- ``contains(_:)``
- ``firstIndex(of:)``
- ``lastIndex(of:)``

### Adding and Updating Elements

- ``insert(_:)``
- ``update(with:)``
- ``update(_:at:)``

### Removing Elements

- ``remove(_:)``
- ``remove(at:)``
- ``filter(_:)``
- ``removeAll(where:)``

### Combining Sets

All the standard combining operations (intersection, union, subtraction and
symmetric difference) are supported, in both non-mutating and mutating forms.
`SetAlgebra` only requires the ability to combine one set instance with another,
but `TreeSet` follows the tradition established by `Set` in providing
additional overloads to each operation that allow combining a set with
additional types, including arbitrary sequences.

- ``intersection(_:)-8ltpr``
- ``intersection(_:)-9kwc0``
- ``intersection(_:)-4u7ew``

- ``union(_:)-89jj2``
- ``union(_:)-9yvze``
- ``union(_:)-7p0m2``

- ``subtracting(_:)-cnsi``
- ``subtracting(_:)-3yfac``
- ``subtracting(_:)-90wrb``

- ``symmetricDifference(_:)-5bz4f``
- ``symmetricDifference(_:)-6p8n5``
- ``symmetricDifference(_:)-3qk9w``

- ``formIntersection(_:)-1zcar``
- ``formIntersection(_:)-4xkf0``
- ``formIntersection(_:)-6jb2z``

- ``formUnion(_:)-420zl``
- ``formUnion(_:)-8zu6q``
- ``formUnion(_:)-423id``

- ``subtract(_:)-49o9``
- ``subtract(_:)-3ebkc``
- ``subtract(_:)-87rhs``

- ``formSymmetricDifference(_:)-94f6x``
- ``formSymmetricDifference(_:)-4x7vw``
- ``formSymmetricDifference(_:)-6ypuy``

### Comparing Sets

`TreeSet` supports all standard set comparisons (subset tests, superset
tests, disjunctness test), including the customary overloads established by
`Set`. As an additional extension, the `isEqualSet` family of member functions
generalize the standard `==` operation to support checking whether a
`TreeSet` consists of exactly the same members as an arbitrary sequence.
Like `==`, the `isEqualSet` functions ignore element ordering and duplicates (if
any).

- ``==(_:_:)`` 
- ``isEqualSet(to:)-4bc1i`` 
- ``isEqualSet(to:)-7x4yi`` 
- ``isEqualSet(to:)-44fkf`` 

- ``isSubset(of:)-2ktpu`` 
- ``isSubset(of:)-5oufi`` 
- ``isSubset(of:)-9tq5c`` 

- ``isSuperset(of:)-3zd41`` 
- ``isSuperset(of:)-6xa75`` 
- ``isSuperset(of:)-6vw4t`` 

- ``isStrictSubset(of:)-6xuil`` 
- ``isStrictSubset(of:)-22f80`` 
- ``isStrictSubset(of:)-5f78e`` 

- ``isStrictSuperset(of:)-4ryjr`` 
- ``isStrictSuperset(of:)-3ephc``
- ``isStrictSuperset(of:)-9ftlc`` 

- ``isDisjoint(with:)-4a9xa``
- ``isDisjoint(with:)-12a64``
- ``isDisjoint(with:)-5lvdr``
