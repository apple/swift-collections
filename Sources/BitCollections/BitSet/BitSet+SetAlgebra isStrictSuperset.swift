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
  public func isStrictSuperset(of other: Self) -> Bool {
    other.isStrictSubset(of: self)
  }

  @inlinable
  public func isStrictSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    guard !isEmpty else { return false }
    if S.self == BitSet.self {
      return isStrictSuperset(of: other as! BitSet)
    }
    if S.self == Range<Int>.self {
      return isStrictSuperset(of: other as! Range<Int>)
    }
    return _UnsafeHandle.withTemporaryBitset(
      wordCount: _storage.count
    ) { seen in
      for i in other {
        guard contains(i) else { return false }
        seen.insert(UInt(i))
      }
      return seen._count < self.count
    }
  }

  public func isStrictSuperset(of other: Range<Int>) -> Bool {
    if other.isEmpty { return !isEmpty }
    if isEmpty { return false }
    guard let r = other._toUInt() else { return false }
    return _read { $0.isSuperset(of: r) && !$0.isSubset(of: r) }
  }
}
