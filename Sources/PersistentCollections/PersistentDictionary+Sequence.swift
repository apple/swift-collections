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

    typealias _ItemBuffer = UnsafeBufferPointer<Element>
    typealias _ChildBuffer = UnsafeBufferPointer<_Node>

    internal var _root: _Node
    internal var _itemIterator: _ItemBuffer.Iterator?

    internal var _pathTop: _ChildBuffer.Iterator?
    internal var _pathRest: [_ChildBuffer.Iterator]

    internal init(_root: _Node) {
      self._root = _root
      self._pathRest = []
      self._pathRest.reserveCapacity(_maxDepth)

      if _root.hasItems {
        self._itemIterator = _root._items.makeIterator()
      }
      if _root.hasChildren {
        self._pathTop = _root._children.makeIterator()
      }
    }
  }

  public __consuming func makeIterator() -> Iterator {
    return Iterator(_root: _root)
  }
}

extension PersistentDictionary.Iterator: IteratorProtocol {
  public typealias Element = (key: Key, value: Value)

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
      if nextNode.hasChildren {
        _pathRest.append(_pathTop!)
        _pathTop = nextNode._children.makeIterator()
      }
      if nextNode.hasItems {
        _itemIterator = nextNode._items.makeIterator()
        return _itemIterator!.next()
      }
    }

    assert(_itemIterator == nil)
    assert(_pathTop == nil)
    assert(_pathRest.isEmpty)
    return nil
  }
}
