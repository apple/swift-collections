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

extension _BitSet {
  @usableFromInline
  internal func isStrictSuperset(of other: Range<UInt>) -> Bool {
    _read { $0.isSuperset(of: other) && !$0.isSubset(of: other) }
  }
}

extension BitSet {
  @inlinable
  public func isStrictSuperset(of other: Self) -> Bool {
    other.isStrictSubset(of: self)
  }

  @inlinable
  public func isStrictSuperset<I: FixedWidthInteger>(
    of other: BitSet<I>
  ) -> Bool {
    other.isStrictSubset(of: self)
  }

  @inlinable
  public func isStrictSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    guard !isEmpty else { return false }
    if S.self == BitSet.self {
      return isStrictSuperset(of: other as! BitSet)
    }
    if S.self == Range<Element>.self {
      return isStrictSuperset(of: other as! Range<Element>)
    }
    return _UnsafeHandle.withTemporaryBitset(
      wordCount: _core._storage.count
    ) { seen in
      for i in other {
        guard let i = UInt(exactly: i) else { return false }
        if !_core.contains(i) { return false }
        seen.insert(i)
      }
      return seen._count < self.count
    }
  }

  @inlinable
  public func isStrictSuperset(of other: Range<Element>) -> Bool {
    if other.isEmpty { return !isEmpty }
    if isEmpty { return false }
    guard let r = other._toUInt() else { return false }
    return _core.isStrictSuperset(of: r)
  }

  @inlinable
  public func isStrictSuperset<I: FixedWidthInteger>(
    of other: Range<I>
  ) -> Bool {
    if other.isEmpty { return !isEmpty }
    if isEmpty { return false }
    guard let r = other._toUInt() else { return false }
    return _core.isStrictSuperset(of: r)
  }
}
