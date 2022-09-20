//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary: Sequence {
  public typealias Element = (key: Key, value: Value)

  public struct Iterator {
    // Fixed-stack iterator for traversing a hash tree.
    // The iterator performs a pre-order traversal, with items at a node visited
    // before any items within children.

    @usableFromInline
    typealias _ItemBuffer = ReversedCollection<UnsafeMutableBufferPointer<Element>>

    @usableFromInline
    typealias _ChildBuffer = UnsafeBufferPointer<_Node>

    @usableFromInline
    internal var _root: _Node

    @usableFromInline
    internal var _itemIterator: _ItemBuffer.Iterator?

    @usableFromInline
    internal var _pathTop: _ChildBuffer.Iterator?

    @usableFromInline
    internal var _pathRest: [_ChildBuffer.Iterator]

    @inlinable
    internal init(_root: _Node) {
      self._root = _root
      self._pathRest = []
      self._pathRest.reserveCapacity(_Level.limit)

      // FIXME: This is illegal, as it escapes pointers to _root contents
      // outside the closure passed to `read`. :-(
      self._itemIterator = _root.read {
        $0.hasItems ? $0.reverseItems.reversed().makeIterator() : nil
      }
      self._pathTop = _root.read {
        $0.hasChildren ? $0.children.makeIterator() : nil
      }
    }
  }

  @inlinable
  public var underestimatedCount: Int {
    _root.count
  }

  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_root: _root)
  }
}

extension PersistentDictionary.Iterator: IteratorProtocol {
  public typealias Element = (key: Key, value: Value)

  @inlinable
  public mutating func next() -> Element? {
    if let item = _itemIterator?.next() {
      return item
    }

    _itemIterator = nil

    while _pathTop != nil {
      guard let nextNode = _pathTop!.next() else {
        _pathTop = _pathRest.popLast()
        continue
      }
      if nextNode.read({ $0.hasChildren }) {
        _pathRest.append(_pathTop!)
        _pathTop = nextNode.read { $0.children.makeIterator() } // 💥ILLEGAL
      }
      if nextNode.read({ $0.hasItems }) {
        _itemIterator = nextNode.read { $0.reverseItems.reversed().makeIterator() } // 💥ILLEGAL
        return _itemIterator!.next()
      }
    }

    assert(_itemIterator == nil)
    assert(_pathTop == nil)
    assert(_pathRest.isEmpty)
    return nil
  }
}
