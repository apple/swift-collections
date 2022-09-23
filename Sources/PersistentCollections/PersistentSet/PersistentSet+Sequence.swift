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

extension PersistentSet: Sequence {
  @frozen
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal typealias _UnsafeHandle = _Node.UnsafeHandle

    @usableFromInline
    internal var _it: _HashTreeIterator

    @inlinable
    internal init(_root: _RawNode) {
      _it = _HashTreeIterator(root: _root)
    }

    public mutating func next() -> Element? {
      guard let (node, slot) = _it.next() else { return nil }
      return _UnsafeHandle.read(node) { $0[item: slot].key }
    }
  }

  @inlinable
  public func makeIterator() -> Iterator {
    Iterator(_root: _root.raw)
  }

  @inlinable
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    _root.containsKey(.top, element, _Hash(element))
  }
}
