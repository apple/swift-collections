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
  public func isDisjoint(with other: Self) -> Bool {
    self._read { first in
      other._read { second in
        let w1 = first._words
        let w2 = second._words
        for i in 0 ..< Swift.min(w1.count, w2.count) {
          if !w1[i].intersection(w2[i]).isEmpty { return false }
        }
        return true
      }
    }
  }

  @inlinable
  public func isDisjoint<S: Sequence>(with other: S) -> Bool
  where S.Element == Int
  {
    if S.self == BitSet.self {
      return self.isDisjoint(with: other as! BitSet)
    }
    if S.self == Range<Int>.self  {
      return self.isDisjoint(with: other as! Range<Int>)
    }
    for value in other {
      guard !contains(value) else { return false }
    }
    return true
  }
}

extension BitSet {
  public func isDisjoint(with other: Range<Int>) -> Bool {
    _read { $0.isDisjoint(with: other._clampedToUInt()) }
  }
}
