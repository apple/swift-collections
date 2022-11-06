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
- ``init(_:)-7jshe``
- ``init(_:)-8ls8p``
- ``init(uniqueKeysWithValues:)-65ax0``
- ``init(uniqueKeysWithValues:)-5ok18``
- ``init(_:uniquingKeysWith:)-7fuzu``
- ``init(_:uniquingKeysWith:)-4jee3``
- ``init(grouping:by:)-8ntzv``
- ``init(grouping:by:)-7cu86``
- ``init(keys:valueGenerator:)``


### Inspecting a Dictionary

- ``isEmpty-65s43``
- ``count-9cdqd``

### Accessing Keys and Values

- ``subscript(_:)-g0oi``
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
- ``merge(_:uniquingKeysWith:)-853bf``
- ``merge(_:uniquingKeysWith:)-19xxn``
- ``merge(_:uniquingKeysWith:)-2osh``
- ``merging(_:uniquingKeysWith:)-2a7cl``
- ``merging(_:uniquingKeysWith:)-1tq3e``
- ``merging(_:uniquingKeysWith:)-2kjqq``

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

