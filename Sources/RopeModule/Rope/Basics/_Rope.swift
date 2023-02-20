//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An ordered data structure of `Element` values that organizes itself into a tree.
/// The rope is augmented by the commutative group specified by `Element.Summary`, enabling
/// quick lookup operations.
struct _Rope<Element: _RopeElement> {
  var _root: Node?
  var _version: _RopeVersion

  init() {
    self._root = nil
    self._version = _RopeVersion()
  }
  
  init(root: Node?) {
    self._root = root
    self._version = _RopeVersion()
  }

  var root: Node {
    get { _root.unsafelyUnwrapped }
    @inline(__always) _modify { yield &_root! }
  }
  
  init(_ value: Element) {
    self._root = .createLeaf(Item(value))
    self._version = _RopeVersion()
  }
}

extension _Rope: Sendable where Element: Sendable {}

extension _Rope {
  mutating func ensureUnique() {
    guard _root != nil else { return }
    root.ensureUnique()
  }
}

extension _Rope {
  var isSingleton: Bool {
    guard _root != nil else { return false }
    return root.isSingleton
  }
}

extension _Rope {
  func isIdentical(to other: Self) -> Bool {
    self._root?.object === other._root?.object
  }
}
