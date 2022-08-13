//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitSet {
  public func isSubset(of other: Self) -> Bool {
    self._read { first in
      other._read { second in
        let w1 = first._words
        let w2 = second._words
        if first.count > second.count || w1.count > w2.count {
          return false
        }
        for i in 0 ..< w1.count {
          if !w1[i].subtracting(w2[i]).isEmpty {
            return false
          }
        }
        return true
      }
    }
  }

  @inlinable
  public func isSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    if S.self == BitSet.self {
      return self.isSubset(of: other as! BitSet)
    }
    if S.self == Range<Int>.self  {
      return self.isSubset(of: other as! Range<Int>)
    }
    guard !isEmpty else { return true }
    var t = self
    for i in other {
      guard let i = UInt(exactly: i) else { continue }
      if t._remove(i), t.isEmpty { return true }
    }
    assert(!t.isEmpty)
    return false
  }

  public func isSubset(of other: Range<Int>) -> Bool {
    guard !isEmpty else { return true }
    return _read { $0.isSubset(of: other._clampedToUInt()) }
  }
}
