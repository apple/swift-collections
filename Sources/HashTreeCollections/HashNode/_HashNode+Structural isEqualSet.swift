//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
extension _HashNode {
  @inlinable
  internal func isEqualSet<Value2>(
    to other: _HashNode<Key, Value2>,
    by areEquivalent: (Value, Value2) -> Bool
  ) -> Bool {
    if self.raw.storage === other.raw.storage { return true }

    guard self.count == other.count else { return false }

    if self.isCollisionNode {
      guard other.isCollisionNode else { return false }
      return unsafe self.read { lhs in
        unsafe other.read { rhs in
          guard unsafe lhs.collisionHash == rhs.collisionHash else { return false }
          let l = unsafe lhs.reverseItems
          let r = unsafe rhs.reverseItems
          assert(l.count == r.count) // Already checked above
          for i in l.indices {
            let found = unsafe r.contains {
              unsafe l[i].key == $0.key && areEquivalent(l[i].value, $0.value)
            }
            guard found else { return false }
          }
          return true
        }
      }
    }
    guard !other.isCollisionNode else { return false }

    return unsafe self.read { l in
      unsafe other.read { r in
        guard unsafe l.itemMap == r.itemMap else { return false }
        guard unsafe l.childMap == r.childMap else { return false }

        guard unsafe l.reverseItems.elementsEqual(
          r.reverseItems,
          by: { $0.key == $1.key && areEquivalent($0.value, $1.value) })
        else { return false }

        let lc = unsafe l.children
        let rc = unsafe r.children
        return unsafe lc.elementsEqual(
          rc,
          by: { $0.isEqualSet(to: $1, by: areEquivalent) })
      }
    }
  }
}
