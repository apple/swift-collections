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

// FIXME: These are non-standard extensions generalizing ==.
extension PersistentSet {
  @inlinable
  public func isEqual(to other: Self) -> Bool {
    _root.isEqual(to: other._root, by: { _, _ in true })
  }

  @inlinable
  public func isEqual<Value>(
    to other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    _root.isEqual(to: other._base._root, by: { _, _ in true })
  }

  @inlinable
  public func isEqual<S: Sequence>(to other: S) -> Bool
  where S.Element == Element
  {
    if S.self == Self.self {
      return isEqual(to: other as! Self)
    }

    guard other.underestimatedCount <= self.count else { return false }
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: _Node = ._empty()
    for item in other {
      let hash = _Hash(item)
      guard self._root.containsKey(.top, item, hash) else { return false }
      guard seen.insert(.top, (item, ()), hash).inserted
      else { return false }
    }
    return seen.count == self.count
  }
}
