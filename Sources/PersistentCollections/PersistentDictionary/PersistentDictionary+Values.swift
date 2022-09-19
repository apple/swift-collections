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

// TODO: implement a custom `Values` view rather than relying on an array representation
extension PersistentDictionary {
  /// A view of a dictionary’s values.
  @frozen
  public struct Values {
    @usableFromInline
    internal typealias _Node = PersistentCollections._Node<Key, Value>

    @usableFromInline
    internal var _base: PersistentDictionary

    @inlinable
    internal init(_base: PersistentDictionary) {
      self._base = _base
    }
  }

  /// A collection containing just the values of the dictionary.
  @inlinable
  public var values: Values {
    get {
      Values(_base: self)
    }
    set { // FIXME: Consider removing
      self = newValue._base
    }
    _modify { // FIXME: Consider removing
      var values = Values(_base: self)
      self = Self()
      defer {
        self = values._base
      }
      yield &values
    }
  }
}

extension PersistentDictionary.Values: Sequence {
  public typealias Element = Value

  @frozen
  public struct Iterator: IteratorProtocol {
    public typealias Element = Value

    @usableFromInline
    internal var _base: PersistentDictionary.Iterator

    @inlinable
    internal init(_base: PersistentDictionary.Iterator) {
      self._base = _base
    }

    @inlinable
    public mutating func next() -> Element? {
      _base.next()?.value
    }
  }

  @inlinable
  public func makeIterator() -> Iterator {
    Iterator(_base: _base.makeIterator())
  }
}

// Note: This cannot be a MutableCollection because its subscript setter
// needs to invalidate indices.
extension PersistentDictionary.Values: BidirectionalCollection {
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
    get {
      _base[index].value
    }
    set { // FIXME: Consider removing
      precondition(_base._isValid(index), "Invalid index")
      precondition(index._path.isOnItem, "Cannot set value at end index")
      let (leaf, slot) = _base._root.ensureUnique(level: .top, at: index._path)
      _Node.UnsafeHandle.update(leaf) { $0[item: slot].value = newValue }
      _base._invalidateIndices()
    }
    _modify { // FIXME: Consider removing
      precondition(_base._isValid(index), "Invalid index")
      precondition(index._path.isOnItem, "Cannot set value at end index")
      let (leaf, slot) = _base._root.ensureUnique(level: .top, at: index._path)
      var item = _Node.UnsafeHandle.update(leaf) { $0.itemPtr(at: slot).move() }
      defer {
        _Node.UnsafeHandle.update(leaf) {
          $0.itemPtr(at: slot).initialize(to: item)
        }
        _base._invalidateIndices()
      }
      yield &item.value
    }
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
