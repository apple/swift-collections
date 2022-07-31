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
  internal __consuming func intersection(_ other: Self) -> Self {
    self._read { first in
      other._read { second in
        Self(
          _combining: (first, second),
          includingTail: false,
          using: { $0.intersection($1) })
      }
    }
  }
}

extension BitSet {
  public __consuming func intersection(_ other: Self) -> Self {
    Self(_core: _core.intersection(other._core))
  }

  @inlinable
  public __consuming func intersection<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Element
  {
    if S.self == Self.self {
      return intersection(other as! BitSet)
    }
    if S.self == Range<Element>.self {
      return intersection(other as! Range<Element>)
    }
    return intersection(BitSet(_validMembersOf: other))
  }

  @inlinable
  public __consuming func intersection(_ other: Range<Element>) -> Self {
    var result = self
    result.formIntersection(other)
    return result
  }
}
