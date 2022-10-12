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
  /// A view of a dictionary’s keys.
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
  @inlinable
  public var keys: Keys {
    Keys(_base: self)
  }
}

#if swift(>=5.5)
extension PersistentDictionary.Keys: Sendable
where Key: Sendable, Value: Sendable {}
#endif

extension PersistentDictionary.Keys: Sequence {
  public typealias Element = Key

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

  @inlinable
  public func contains(_ element: Element) -> Bool {
    _base._root.containsKey(.top, element, _Hash(element))
  }
}

#if swift(>=5.5)
extension PersistentDictionary.Keys.Iterator: Sendable
where Key: Sendable, Value: Sendable {}
#endif

extension PersistentDictionary.Keys: BidirectionalCollection {
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
  public func formIndex(before i: inout Index) {
    _base.formIndex(before: &i)
  }

  @inlinable
  public func index(after i: Index) -> Index {
    _base.index(after: i)
  }

  @inlinable
  public func index(before i: Index) -> Index {
    _base.index(before: i)
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
