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
extension _Node {
  @inlinable
  internal func isEqual(
    to other: _Node,
    by areEquivalent: (Element, Element) -> Bool
  ) -> Bool {
    if self.raw.storage === other.raw.storage { return true }

    guard self.count == other.count else { return false }

    if self.isCollisionNode {
      guard other.isCollisionNode else { return false }
      return self.read { lhs in
        other.read { rhs in
          let l = lhs.reverseItems
          let r = rhs.reverseItems
          guard l.count == r.count else { return false }
          for i in l.indices {
            guard r.contains(where: { areEquivalent($0, l[i]) })
            else { return false }
          }
          return true
        }
      }
    }
    guard !other.isCollisionNode else { return false }

    return self.read { l in
      other.read { r in
        guard l.itemMap == r.itemMap else { return false }
        guard l.childMap == r.childMap else { return false }

        guard l.reverseItems.elementsEqual(r.reverseItems, by: areEquivalent)
        else { return false }

        let lc = l.children
        let rc = r.children
        return lc.elementsEqual(
          rc,
          by: { $0.isEqual(to: $1, by: areEquivalent) })
      }
    }
  }
}
