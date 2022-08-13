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
  public func isSuperset(of other: Self) -> Bool {
    other.isSubset(of: self)
  }

  @inlinable
  public func isSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Int
  {
    if S.self == BitSet.self {
      return self.isSuperset(of: other as! BitSet)
    }
    if S.self == Range<Int>.self  {
      return self.isSuperset(of: other as! Range<Int>)
    }
    for i in other {
      guard let i = UInt(exactly: i) else { return false }
      if !_contains(i) { return false }
    }
    return true
  }

  public func isSuperset(of other: Range<Int>) -> Bool {
    if other.isEmpty { return true }
    if isEmpty { return false }
    guard let r = other._toUInt() else { return false }
    return _read { $0.isSuperset(of: r) }
  }
}
