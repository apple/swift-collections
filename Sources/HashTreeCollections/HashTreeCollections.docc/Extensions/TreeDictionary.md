# ``HashTreeCollections/TreeDictionary``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Collection Views

`TreeDictionary` provides the customary dictionary views, `keys` and
`values`. These are collection types that are projections of the dictionary
itself, with elements that match only the keys or values of the dictionary,
respectively. The `Keys` view is notable in that it provides operations for
subtracting and intersecting the keys of two dictionaries, allowing for easy
detection of inserted and removed items between two snapshots of the same
dictionary. Because `TreeDictionary` needs to invalidate indices on every
mutation, its `Values` view is not a `MutableCollection`.

- ``Keys``
- ``Values``
- ``keys``
- ``values``

### Creating a Dictionary

- ``init()``
- ``init(_:)-(TreeDictionary<Key,Value>)``
- ``init(_:)-([Key:Value])``
- ``init(uniqueKeysWithValues:)-(Sequence<Element>)``
- ``init(uniqueKeysWithValues:)-(Sequence<(Key,Value)>)``
- ``init(_:uniquingKeysWith:)-(Sequence<Element>,_)``
- ``init(_:uniquingKeysWith:)-(Sequence<(Key,Value)>,_)``
- ``init(grouping:by:)-a4ma``
- ``init(grouping:by:)-4he86``
- ``init(keys:valueGenerator:)``


### Inspecting a Dictionary

- ``isEmpty``
- ``count``

### Accessing Keys and Values

- ``subscript(_:)->TreeDictionary<Key,Value>.Element``
- ``subscript(_:default:)``
- ``subscript(_:)->Value?``
- ``index(forKey:)``

### Adding or Updating Keys and Values

Beyond the standard `updateValue(_:forKey:)` method, `TreeDictionary` also
provides additional `updateValue` variants that take closure arguments. These
provide a more straightforward way to perform in-place mutations on dictionary
values (compared to mutating values through the corresponding subscript
operation.) `TreeDictionary` also provides the standard `merge` and
`merging` operations for combining dictionary values.

- ``updateValue(_:forKey:)``
- ``updateValue(forKey:with:)``
- ``updateValue(forKey:default:with:)``
- ``merge(_:uniquingKeysWith:)-(TreeDictionary,_)``
- ``merge(_:uniquingKeysWith:)-(Sequence<Element>,_)``
- ``merge(_:uniquingKeysWith:)-(Sequence<(Key,Value)>,_)``
- ``merging(_:uniquingKeysWith:)-(TreeDictionary,_)``
- ``merging(_:uniquingKeysWith:)-(Sequence<Element>,_)``
- ``merging(_:uniquingKeysWith:)-(Sequence<(Key,Value)>,_)``

### Removing Keys and Values

- ``removeValue(forKey:)``
- ``remove(at:)``
- ``filter(_:)``

### Comparing Dictionaries

- ``==(_:_:)``

### Transforming a Dictionary

- ``mapValues(_:)``
- ``compactMapValues(_:)``

