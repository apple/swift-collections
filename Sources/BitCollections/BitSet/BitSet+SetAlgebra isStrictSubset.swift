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
  public func isStrictSubset(of other: Self) -> Bool {
    self._read { first in
      other._read { second in
        let w1 = first._words
        let w2 = second._words
        if first.count >= second.count || w1.count > w2.count {
          return false
        }
        var strict = w1.count < w2.count
        for i in 0 ..< w1.count {
          if !w1[i].subtracting(w2[i]).isEmpty {
            return false
          }
          strict = strict || w1[i] != w2[i]
        }
        return strict
      }
    }
  }

  @inlinable
  public func isStrictSubset<S: Sequence>(of other: S) -> Bool
  where S.Element: FixedWidthInteger
  {
    if S.self == BitSet.self {
      return isStrictSubset(of: other as! BitSet)
    }
    if S.self == Range<S.Element>.self {
      return isStrictSubset(of: other as! Range<S.Element>)
    }

    if isEmpty {
      var it = other.makeIterator()
      return it.next() != nil
    }

    return _UnsafeHandle.withTemporaryBitset(
      wordCount: _storage.count
    ) { seen in
      var strict = false
      var it = other.makeIterator()
      while let i = it.next() {
        guard self.contains(i) else {
          strict = true
          continue
        }
        if seen.insert(UInt(i)), seen._count == self._count {
          while !strict, let i = it.next() {
            strict = !self.contains(i)
          }
          return strict
        }
      }
      assert(seen._count < self._count)
      return false
    }
  }

  @inlinable
  public func isStrictSubset<I: FixedWidthInteger>(of other: Range<I>) -> Bool {
    isSubset(of: other) && !isSuperset(of: other)
  }
}
