//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An ordered collection of unique elements.
///
/// Similar to the standard `Set`, ordered sets ensure that each element appears
/// only once in the collection, and they provide efficient tests for
/// membership. However, like `Array` (and unlike `Set`), ordered sets maintain
/// their elements in a particular user-specified order, and they support
/// efficient random-access traversal of their members.
///
/// `OrderedSet` is a useful alternative to `Set` when the order of elements is
/// important, or when you need to be able to efficiently access elements at
/// various positions within the collection. It can also be used instead of an
/// `Array` when each element needs to be unique, or when you need to be able to
/// quickly determine if a value is a member of the collection.
///
/// You can create an ordered set with any element type that conforms to the
/// `Hashable` protocol.
///
///     let buildingMaterials: OrderedSet = ["straw", "sticks", "bricks"]
///
///
/// # Equality of Ordered Sets
///
/// Two ordered sets are considered equal if they contain the same elements, and
/// *in the same order*. This matches the concept of equality of an `Array`, and
/// it is different from the unordered `Set`.
///
///     let a: OrderedSet = [1, 2, 3, 4]
///     let b: OrderedSet = [4, 3, 2, 1]
///     a == b // false
///     b.sort() // `b` now has value [1, 2, 3, 4]
///     a == b // true
///
/// # Set Operations
///
/// `OrderedSet` implements most, but not all, `SetAlgebra` requirements. In
/// particular, it supports the membership test `contains(_:)` as well as all
/// high-level set operations such as `union(_:)`, `intersection(_:)` or
/// `isSubset(of:)`.
///
///     buildingMaterials.contains("glass") // false
///     buildingMaterials.intersection(["brick", "straw"]) // ["straw", "brick"]
///
/// Operations that return an ordered set usually preserve the ordering of
/// elements in their input. For example, in the case of the `intersection` call
/// above, the ordering of elements in the result is guaranteed to match their
/// order in the first input set, `buildingMaterials`.
///
/// On the other hand, predicates such as `isSubset(of:)` tend to ignore element
/// ordering:
///
///     let moreMaterials: OrderedSet = ["bricks", "glass", "sticks", "straw"]
///     buildingMaterials.isSubset(of: moreMaterials) // true
///
/// However, `OrderedSet` does not implement `insert(_:)` nor `update(with:)` --
/// it provides its own variants for insertion that are more explicit about
/// where in the collection new elements gets inserted:
///
///     func insert(_ item: Element, at index: Int) -> (inserted: Bool, index: Int)
///     func append(_ item: Element) -> (inserted: Bool, index: Int)
///     func update(at index: Int, with item: Element) -> Element
///     func updateOrAppend(_ item: Element) -> Element?
///
/// Additionally,`OrderedSet` has an order-sensitive definition of equality (see
/// above) that is incompatible with `SetAlgebra`'s documented semantic
/// requirements. Accordingly, `OrderedSet` does not (cannot) itself conform to
/// `SetAlgebra`.
///
/// # Unordered Set View
///
/// For cases where `SetAlgebra` conformance is desired (such as when passing an
/// ordered set to a function that is generic over that protocol), `OrderedSet`
/// provides an efficient *unordered view* of its elements that conforms to
/// `SetAlgebra`. The unordered view implements the same concept of equality as
/// the standard `Set`, ignoring element ordering.
///
///     var a: OrderedSet = [0, 1, 2, 3]
///     let b: OrderedSet = [3, 2, 1, 0]
///     a == b // false
///     a.unordered == b.unordered // true
///
///     func frobnicate<S: OrderedSet>(_ set: S) { ... }
///     frobnicate(a) // error: `OrderedSet<String>` does not conform to `SetAlgebra`
///     frobnicate(a.unordered) // OK
///
/// The unordered view is mutable. Insertions into it implicitly append new
/// elements to the end of the collection.
///
///     buildingMaterials.unordered.insert("glass") // => inserted: true
///     // buildingMaterials is now ["straw", "sticks", "brick", "glass"]
///
/// Accessing the unordered view is an efficient operation, with constant
/// (minimal) overhead. Direct mutations of the unordered view (such as the
/// insertion above) are executed in place when possible. However, as usual with
/// copy-on-write collections, if you make a copy of the view (such as by
/// extracting its value into a named variable), the resulting values will share
/// the same underlying storage, so mutations of either will incur a copy of the
/// whole set.
///
/// # Sequence and Collection Operations
///
/// Ordered sets are random-access collections. Members are assigned integer
/// indices, with the first element always being at index `0`:
///
///     let buildingMaterials: OrderedSet = ["straw", "sticks", "bricks"]
///     buildingMaterials[1] // "sticks"
///     buildingMaterials.firstIndex(of: "bricks") // 2
///
///     for i in 0 ..< buildingMaterials.count {
///       print("Little piggie #\(i) built a house of \(buildingMaterials[i])")
///     }
///     // Little piggie #0 built a house of straw
///     // Little piggie #1 built a house of sticks
///     // Little piggie #2 built a house of bricks
///
/// Because `OrderedSet` needs to keep its members unique, it cannot conform to
/// the full `MutableCollection` or `RangeReplaceableCollection` protocols.
/// Operations such as `MutableCollection`'s subscript setter or
/// `RangeReplaceableCollection`'s `replaceSubrange` assume the ability to
/// insert/replace arbitrary elements in the collection, but allowing that could
/// lead to duplicate values.
///
/// However, `OrderedSet` is able to partially implement these two protocols;
/// namely, there is no issue with mutation operations that merely change the
/// order of elements, or just remove some subset of existing members:
///
///     // Permutation operations from MutableCollection:
///     func swapAt(_ i: Int, _ j: Int)
///     func partition(by predicate: (Element) throws -> Bool) -> rethrows Int
///     func sort() where Element: Comparable
///     func sort(by predicate: (Element, Element) throws -> Bool) rethrows
///     func shuffle()
///     func shuffle<T: RandomNumberGenerator>(using generator: inout T)
///     func reverse()
///
///     // Removal operations from RangeReplaceableCollection:
///     func removeAll(keepingCapacity: Bool = false)
///     func remove(at index: Int) -> Element
///     func removeSubrange(_ bounds: Range<Int>)
///     func removeLast() -> Element
///     func removeLast(_ n: Int)
///     func removeFirst() -> Element
///     func removeFirst(_ n: Int)
///     func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows
///
/// `OrderedSet` also implements `reserveCapacity(_)` from
/// `RangeReplaceableCollection`, to allow for efficient insertion of a known
/// number of elements. (However, unlike `Array` and `Set`, `OrderedSet` does
/// not provide a `capacity` property.)
///
/// # Accessing The Contents of an Ordered Set as an Array
///
/// In cases where you need to pass the contents of an ordered set to a function
/// that only takes an array value or (or something that's generic over
/// `RangeReplaceableCollection` or `MutableCollection`), then the best option
/// is usually to directly extract the members of the `OrderedSet` as an `Array`
/// value using its `elements` property. `OrderedSet` uses a standard array
/// value for element storage, so extracting the array value has minimal
/// overhead.
///
///     func pickyFunction(_ items: Array<Int>)
///
///     var set: OrderedSet = [0, 1, 2, 3]
///     pickyFunction(set) // error
///     pickyFunction(set.elements) // OK
///
/// It is also possible to mutate the set by updating the value of the
/// `elements` property. This guarantees that direct mutations happen in place
/// when possible (i.e., without spurious copy-on-write copies).
///
/// However, the set needs to ensure the uniqueness of its members, so every
/// update to `elements` includes a postprocessing step to detect and remove
/// duplicates over the entire array. This can be slower than doing the
/// equivalent updates with direct `OrderedSet` operations, so updating
/// `elements` is best used in cases where direct implementations aren't
/// available -- for example, when you need to call a `MutableCollection`
/// algorithm that isn't directly implemented by `OrderedSet` itself.
///
/// # Performance
///
/// Like the standard `Set` type, the performance of hashing operations in
/// `OrderedSet` is highly sensitive to the quality of hashing implemented by
/// the `Element` type. Failing to correctly implement hashing can easily lead
/// to unacceptable performance, with the severity of the effect increasing with
/// the size of the hash table.
///
/// In particular, if a certain set of elements all produce the same hash value,
/// then hash table lookups regress to searching an element in an unsorted
/// array, i.e., a linear operation. To ensure hashed collection types exhibit
/// their target performance, it is important to ensure that such collisions
/// cannot be induced merely by adding a particular list of members to the set.
///
/// The easiest way to achieve this is to make sure `Element` implements hashing
/// following `Hashable`'s documented best practices. The conformance must
/// implement the `hash(into:)` requirement, and every bit of information that
/// is compared in `==` needs to be combined into the supplied `Hasher` value.
/// When used correctly, `Hasher` produces high-quality, randomly seeded hash
/// values that prevent repeatable hash collisions.
///
/// When `Element` implements `Hashable` correctly, testing for membership in an
/// ordered set is expected to take O(1) equality checks on average. Hash
/// collisions can still occur organically, so the worst-case lookup performance
/// is technically still O(*n*) (where *n* is the size of the set); however,
/// long lookup chains are unlikely to occur in practice.
///
/// # Implementation Details
///
/// An `OrderedSet` stores its members in a regular `Array` value (exposed by
/// the `elements` property). It also maintains a standalone hash table
/// containing array indices alongside the array; this is used to implement fast
/// membership tests. The size of the array is limited by the capacity of the
/// corresponding hash table, so indices stored inside the hash table can be
/// encoded into fewer bits than a standard `Int` value, leading to a storage
/// representation that can often be more compact than that of `Set` itself.
///
/// Inserting or removing a single member (or a range of members) needs to
/// perform the corresponding operation in the storage array, in addition to
/// renumbering any subsequent members in the hash table. Therefore, these
/// operations are expected to have performance characteristics similar to an
/// `Array`: inserting or removing an element to the end of an ordered set is
/// expected to execute in O(1) operations, while they are expected to take
/// linear time at the front (or in the middle) of the set. (Note that this is
/// different to the standard `Set`, where insertions and removals are expected
/// to take amortized O(1) time.)
@frozen
public struct OrderedSet<Element> where Element: Hashable
{
  @usableFromInline
  internal typealias _Bucket = _HashTable.Bucket

  @usableFromInline
  internal var __storage: _HashTable.Storage?

  @usableFromInline
  internal var _elements: ContiguousArray<Element>

  @inlinable
  internal init(
    _uniqueElements: ContiguousArray<Element>,
    _ table: _HashTable? = nil
  ) {
    self.__storage = table?._storage
    self._elements = ContiguousArray(_uniqueElements)
  }

  @inlinable
  @inline(__always)
  internal var _table: _HashTable? {
    get { __storage.map { _HashTable($0) } }
    set { __storage = newValue?._storage }
  }
}

extension OrderedSet {
  /// A view of the members of this set, as a regular array value.
  ///
  /// It is possible to mutate the set by updating the value of this property.
  /// This guarantees that direct mutations happen in place when possible (i.e.,
  /// without spurious copy-on-write copies).
  ///
  /// However, the set needs to ensure the uniqueness of its members, so every
  /// update to `elements` includes a postprocessing step to detect and remove
  /// duplicates over the entire array. This can be slower than doing the
  /// equivalent updates with direct `OrderedSet` operations, so updating
  /// `elements` is best used in cases where direct implementations aren't
  /// available -- for example, when you need to call a `MutableCollection`
  /// algorithm that isn't directly implemented by `OrderedSet` itself.
  ///
  /// - Complexity: O(1) for the getter. Mutating this property has an expected
  ///    complexity of O(`count`), if `Element` implements high-quality hashing.
  @inlinable
  public var elements: [Element] {
    get {
      Array(_elements)
    }
    set {
      self = .init(newValue)
    }
    _modify {
      var members = Array(_elements)
      _elements = []
      defer { self = .init(members) }
      yield &members
    }
  }
}

extension OrderedSet {
  /// The maximum number of elements this instance can store before it needs
  /// to resize its hash table.
  @inlinable
  internal var _capacity: Int {
    _table?.capacity ?? _HashTable.maximumUnhashedCount
  }

  @inlinable
  internal var _minimumCapacity: Int {
    if _scale == _reservedScale { return 0 }
    return _HashTable.minimumCapacity(forScale: _scale)
  }

  @inlinable
  internal var _scale: Int {
    _table?.scale ?? 0
  }

  @inlinable
  internal var _reservedScale: Int {
    _table?.reservedScale ?? 0
  }

  @inlinable
  internal var _bias: Int {
    _table?.bias ?? 0
  }
}

extension OrderedSet {
  @inlinable
  internal mutating func _regenerateHashTable(scale: Int, reservedScale: Int) {
    assert(_HashTable.maximumCapacity(forScale: scale) >= _elements.count)
    assert(reservedScale == 0 || reservedScale >= _HashTable.minimumScale)
    _table = _HashTable.create(
      uncheckedUniqueElements: _elements,
      scale: Swift.max(scale, reservedScale),
      reservedScale: reservedScale)
  }

  @inlinable
  internal mutating func _regenerateHashTable() {
    let reservedScale = _reservedScale
    guard
      _elements.count > _HashTable.maximumUnhashedCount || reservedScale != 0
    else {
      // We have too few elements; disable hashing.
      _table = nil
      return
    }
    let scale = _HashTable.scale(forCapacity: _elements.count)
    _regenerateHashTable(scale: scale, reservedScale: reservedScale)
  }

  @inlinable
  internal mutating func _regenerateExistingHashTable() {
    assert(_capacity >= _elements.count)
    guard _table != nil else {
      return
    }
    _ensureUnique()
    _table!.update { hashTable in
      hashTable.clear()
      hashTable.fill(uncheckedUniqueElements: _elements)
    }
  }
}

extension OrderedSet {
  @inlinable
  @inline(__always)
  internal mutating func _isUnique() -> Bool {
    isKnownUniquelyReferenced(&__storage)
  }

  @inlinable
  internal mutating func _ensureUnique() {
    if __storage == nil { return }
    if isKnownUniquelyReferenced(&__storage) { return }
    _table = _table!.copy()
  }
}

extension OrderedSet {
  @inlinable
  internal func _find(_ item: Element) -> (index: Int?, bucket: _Bucket) {
    _find_inlined(item)
  }

  @inlinable
  @inline(__always)
  internal func _find_inlined(_ item: Element) -> (index: Int?, bucket: _Bucket) {
    _elements.withUnsafeBufferPointer { elements in
      guard let table = _table else {
        return (elements.firstIndex(of: item), _Bucket(offset: 0))
      }
      return table.read { hashTable in
        hashTable._find(item, in: elements)
      }
    }
  }

  @inlinable
  internal func _bucket(for index: Int) -> _Bucket {
    guard let table = _table else { return _Bucket(offset: 0) }
    return table.read { hashTable in
      var it = hashTable.bucketIterator(for: _elements[index])
      it.advance(until: index)
      precondition(it.isOccupied, "Corrupt hash table")
      return it.currentBucket
    }
  }

  /// Returns the index of the given element in the set, or `nil` if the element
  /// is not a member of the set.
  ///
  /// `OrderedSet` members are always unique, so the first index of an element
  /// is always the same as its last index.
  ///
  /// - Complexity: This operation is expected to perform O(1) comparisons on
  ///    average, provided that `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func firstIndex(of element: Element) -> Int? {
    _find(element).index
  }

  /// Returns the index of the given element in the set, or `nil` if the element
  /// is not a member of the set.
  ///
  /// `OrderedSet` members are always unique, so the first index of an element
  /// is always the same as its last index.
  ///
  /// - Complexity: This operation is expected to perform O(1) comparisons on
  ///    average, provided that `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func lastIndex(of element: Element) -> Int? {
    _find(element).index
  }
}

extension OrderedSet {
  @inlinable
  @inline(never)
  internal __consuming func _extractSubset(
    using bitset: _UnsafeBitset,
    extraCapacity: Int = 0
  ) -> Self {
    assert(bitset.count == 0 || bitset.max()! <= count)
    if bitset.count == 0 { return Self(minimumCapacity: extraCapacity) }
    if bitset.count == self.count {
      if extraCapacity <= self._capacity - self.count {
        return self
      }
      var copy = self
      copy.reserveCapacity(count + extraCapacity)
      return copy
    }
    var result = Self(minimumCapacity: bitset.count + extraCapacity)
    for offset in bitset {
      result._appendNew(_elements[offset])
    }
    assert(result.count == bitset.count)
    return result
  }
}

extension OrderedSet {
  @inlinable
  @discardableResult
  internal mutating func _removeExistingMember(
    at index: Int,
    in bucket: _Bucket
  ) -> Element {
    guard _elements.count - 1 >= _minimumCapacity else {
      let old = _elements.remove(at: index)
      _regenerateHashTable()
      return old
    }
    guard _table != nil else {
      return _elements.remove(at: index)
    }

    defer { _checkInvariants() }
    _ensureUnique()
    _table!.update { hashTable in
      // Delete the entry for the removed member.
      hashTable.delete(
        bucket: bucket,
        hashValueGenerator: { offset, seed in
          _elements[offset]._rawHashValue(seed: seed)
        })
      hashTable.adjustContents(preparingForRemovalOf: index, in: _elements)
    }
    return _elements.remove(at: index)
  }
}
