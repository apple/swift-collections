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
  static func == (left: _Node, right: _Node) -> Bool {
    if left.raw.storage === right.raw.storage { return true }

    guard left.count == right.count else { return false }

    if left.isCollisionNode {
      guard right.isCollisionNode else { return false }
      return left.read { lhs in
        right.read { rhs in
          let l = lhs.reverseItems
          let r = rhs.reverseItems
          guard l.count == r.count else { return false }
          for i in l.indices {
            guard r.contains(where: { $0 == l[i] }) else { return false }
          }
          return true
        }
      }
    }
    guard !right.isCollisionNode else { return false }

    guard left.count == right.count else { return false }
    return left.read { l in
      right.read { r in
        guard l.itemMap == r.itemMap else { return false }
        guard l.childMap == r.childMap else { return false }

        guard l.reverseItems.elementsEqual(r.reverseItems, by: { $0 == $1 })
        else { return false }

        guard l.children.elementsEqual(r.children) else { return false }
        return true
      }
    }
  }
}
