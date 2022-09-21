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

public struct PersistentSet<Element: Hashable> {
  @usableFromInline
  internal typealias _Node = PersistentCollections._Node<Element, Void>

  @usableFromInline
  internal var _root: _Node

  @usableFromInline
  internal var _version: UInt

  @inlinable
  internal init(_root: _Node, version: UInt) {
    self._root = _root
    self._version = version
  }

  @inlinable
  internal init(_new: _Node) {
    self.init(_root: _new, version: _new.initialVersionNumber)
  }
}


extension PersistentSet {
  @inlinable
  public func _invariantCheck() {
    _root._fullInvariantCheck(.top, _Hash(_value: 0))
  }
}
