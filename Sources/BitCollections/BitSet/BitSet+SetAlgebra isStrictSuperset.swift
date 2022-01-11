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
  where S.Element: FixedWidthInteger
  {
    guard !isEmpty else { return false }
    if S.self == BitSet.self {
      return isStrictSuperset(of: other as! BitSet)
    }
    if S.self == Range<S.Element>.self {
      return isStrictSuperset(of: other as! Range<S.Element>)
    }
    return _UnsafeHandle.withTemporaryBitset(
      wordCount: _storage.count
    ) { seen in
      for i in other {
        guard let i = UInt(exactly: i) else { return false }
        if !contains(i) { return false }
        seen.insert(i)
      }
      return seen._count < self._count
    }
  }

  @inlinable
  public func isStrictSuperset<I: FixedWidthInteger>(
    of other: Range<I>
  ) -> Bool {
    if other.isEmpty { return !isEmpty }
    if isEmpty { return false }
    guard let r = other._toUInt() else { return false }
    return _isStrictSuperset(of: r)
  }

  @usableFromInline
  internal func _isStrictSuperset(of other: Range<UInt>) -> Bool {
    _read { $0.isSuperset(of: other) && !$0.isSubset(of: other) }
  }
}
