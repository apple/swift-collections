# ``ShareableHashedCollections/ShareableDictionary``

<!-- Summary -->

<!-- ## Overview -->

## Topics

### Collection Views

`ShareableDictionary` provides the customary dictionary views, `keys` and
`values`. These are collection types that are projections of the dictionary
itself, with elements that match only the keys or values of the dictionary,
respectively. The `Keys` view is notable in that it provides operations for
subtracting and intersecting the keys of two dictionaries, allowing for easy
detection of inserted and removed items between two snapshots of the same
dictionary. Because `ShareableDictionary` needs to invalidate indices on every
mutation, its `Values` view is not a `MutableCollection`.

- ``Keys-swift.struct``
- ``Values-swift.struct``
- ``keys-swift.property``
- ``values-swift.property``

### Creating a Dictionary

- ``init()``
- ``init(_:)-68s80``
- ``init(_:)-2ngkk``
- ``init(uniqueKeysWithValues:)-688fi``
- ``init(uniqueKeysWithValues:)-3h2xe``
- ``init(_:uniquingKeysWith:)-6t92n``
- ``init(_:uniquingKeysWith:)-9opgv``
- ``init(grouping:by:)-6ddmm``
- ``init(grouping:by:)-9rc24``
- ``init(keys:valueGenerator:)``


### Inspecting a Dictionary

- ``isEmpty-25p4``
- ``count-8s588``

### Accessing Keys and Values

- ``subscript(_:)-6jbab``
- ``subscript(_:default:)``
- ``index(forKey:)``

### Adding or Updating Keys and Values

Beyond the standard `updateValue(_:forKey:)` method, `ShareableDictionary` also
provides additional `updateValue` variants that take closure arguments. These
provide a more straightforward way to perform in-place mutations on dictionary
values (compared to mutating values through the corresponding subscript
operation.) `ShareableDictionary` also provides the standard `merge` and
`merging` operations for combining dictionary values.

- ``updateValue(_:forKey:)``
- ``updateValue(forKey:with:)``
- ``updateValue(forKey:default:with:)``
- ``merge(_:uniquingKeysWith:)-218dc``
- ``merge(_:uniquingKeysWith:)-8gdr2``
- ``merge(_:uniquingKeysWith:)-6j72k``
- ``merging(_:uniquingKeysWith:)-88sah``
- ``merging(_:uniquingKeysWith:)-2qknu``
- ``merging(_:uniquingKeysWith:)-3hao7``

### Removing Keys and Values

- ``removeValue(forKey:)``
- ``remove(at:)``
- ``filter(_:)``

### Non-mutating Dictionary Operations

- ``updatingValue(_:forKey:)``
- ``removingValue(forKey:)``

### Comparing Dictionaries

- ``==(_:_:)``

### Transforming a Dictionary

- ``mapValues(_:)``
- ``compactMapValues(_:)``

