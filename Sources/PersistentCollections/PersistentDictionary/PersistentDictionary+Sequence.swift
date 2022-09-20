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

  @frozen
  public struct Iterator {
    // Fixed-stack iterator for traversing a hash tree.
    // The iterator performs a pre-order traversal, with items at a node visited
    // before any items within children.

    @usableFromInline
    internal typealias _UnsafeHandle = _Node.UnsafeHandle

    @usableFromInline
    internal var _it: _HashTreeIterator

    @inlinable
    internal init(_root: _RawNode) {
      self._it = _HashTreeIterator(root: _root)
    }
  }

  @inlinable
  public var underestimatedCount: Int {
    _root.count
  }

  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_root: _root.raw)
  }
}

extension PersistentDictionary.Iterator: IteratorProtocol {
  public typealias Element = (key: Key, value: Value)

  @inlinable
  public mutating func next() -> Element? {
    guard let (node, slot) = _it.next() else { return nil }
    return _UnsafeHandle.read(node) { $0[item: slot] }
  }
}
