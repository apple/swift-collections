//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsUtilities

extension PersistentDictionary {
  /// A view of a persistent dictionary’s keys, as a standalone collection.
  @frozen
  public struct Keys {
    @usableFromInline
    internal typealias _Node = PersistentCollections._Node<Key, Value>

    @usableFromInline
    internal var _base: PersistentDictionary

    @inlinable
    internal init(_base: PersistentDictionary) {
      self._base = _base
    }
  }
  
  /// A collection containing just the keys of the dictionary.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var keys: Keys {
    Keys(_base: self)
  }
}

#if swift(>=5.5)
extension PersistentDictionary.Keys: Sendable
where Key: Sendable, Value: Sendable {}
#endif

extension PersistentDictionary.Keys: _UniqueCollection {}

extension PersistentDictionary.Keys: CustomStringConvertible {
  // A textual representation of this instance.
  public var description: String {
    _arrayDescription(for: self)
  }
}

extension PersistentDictionary.Keys: CustomDebugStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    _arrayDescription(
      for: self,
      debug: true,
      typeName: "\(PersistentDictionary._debugTypeName()).Keys")
  }
}

extension PersistentDictionary.Keys: Sequence {
  /// The element type of the collection.
  public typealias Element = Key

  /// The type that allows iteration over the elements of the keys view
  /// of a persistent dictionary.
  @frozen
  public struct Iterator: IteratorProtocol {
    public typealias Element = Key

    @usableFromInline
    internal var _base: PersistentDictionary.Iterator

    @inlinable
    internal init(_base: PersistentDictionary.Iterator) {
      self._base = _base
    }

    @inlinable
    public mutating func next() -> Element? {
      _base.next()?.key
    }
  }

  @inlinable
  public func makeIterator() -> Iterator {
    Iterator(_base: _base.makeIterator())
  }

  @inlinable
  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    _base._root.containsKey(.top, element, _Hash(element))
  }

  /// Returns a Boolean value that indicates whether the given key exists
  /// in the dictionary.
  ///
  /// - Parameter element: A key to look for in the dictionary/
  ///
  /// - Returns: `true` if `element` exists in the set; otherwise, `false`.
  ///
  /// - Complexity: This operation is expected to perform O(1) hashing and
  ///    comparison operations on average, provided that `Element` implements
  ///    high-quality hashing.
  @inlinable
  public func contains(_ element: Element) -> Bool {
    _base._root.containsKey(.top, element, _Hash(element))
  }
}

#if swift(>=5.5)
extension PersistentDictionary.Keys.Iterator: Sendable
where Key: Sendable, Value: Sendable {}
#endif

extension PersistentDictionary.Keys: Collection {
  public typealias Index = PersistentDictionary.Index

  @inlinable
  public var isEmpty: Bool { _base.isEmpty }

  @inlinable
  public var count: Int { _base.count }

  @inlinable
  public var startIndex: Index { _base.startIndex }

  @inlinable
  public var endIndex: Index { _base.endIndex }

  @inlinable
  public subscript(index: Index) -> Element {
    _base[index].key
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    _base.formIndex(after: &i)
  }

  @inlinable
  public func index(after i: Index) -> Index {
    _base.index(after: i)
  }

  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    _base.index(i, offsetBy: distance)
  }

  @inlinable
  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    _base.index(i, offsetBy: distance, limitedBy: limit)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    _base.distance(from: start, to: end)
  }
}

#if false
extension PersistentDictionary.Keys: BidirectionalCollection {
  @inlinable
  public func formIndex(before i: inout Index) {
    _base.formIndex(before: &i)
  }

  @inlinable
  public func index(before i: Index) -> Index {
    _base.index(before: i)
  }
}
#endif

extension PersistentDictionary.Keys {
  public func intersection(_ other: Self) -> Self {
    guard let r = _base._root.intersection(.top, other._base._root) else {
      return self
    }
    return PersistentDictionary(_new: r).keys
  }

  public func subtracting(_ other: Self) -> Self {
    guard let r = _base._root.subtracting(.top, other._base._root) else {
      return self
    }
    return PersistentDictionary(_new: r).keys
  }
}
