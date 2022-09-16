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

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
extension _Node: Equatable where Value: Equatable {
  @inlinable
  static func == (lhs: _Node, rhs: _Node) -> Bool {
    if lhs.raw.storage === rhs.raw.storage { return true }
    if lhs.isCollisionNode && rhs.isCollisionNode {
      return lhs.read { lhs in
        rhs.read { rhs in
          let l = Dictionary(
            uniqueKeysWithValues: lhs._items.lazy.map { ($0.key, $0.value) })
          let r = Dictionary(
            uniqueKeysWithValues: rhs._items.lazy.map { ($0.key, $0.value) })
          return l == r
        }
      }
    }
    return deepContentEquality(lhs, rhs)
  }

  @inlinable
  internal static func deepContentEquality(
    _ left: _Node,
    _ right: _Node
  ) -> Bool {
    guard left.count == right.count else { return false }
    return left.read { l in
      right.read { r in
        guard l.itemMap == r.itemMap else { return false }
        guard l.childMap == r.childMap else { return false }

        guard l._items.elementsEqual(r._items, by: { $0 == $1 })
        else { return false }

        guard l._children.elementsEqual(r._children) else { return false }
        return true
      }
    }
  }
}
