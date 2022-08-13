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
  public __consuming func subtracting(_ other: Self) -> Self {
    self._read { first in
      other._read { second in
        Self(
          _combining: (first, second),
          includingTail: true,
          using: { $0.subtracting($1) })
      }
    }
  }

  @inlinable
  public __consuming func subtracting<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int
  {
    var result = self
    result.subtract(other)
    return result
  }

  public __consuming func subtracting(_ other: Range<Int>) -> Self {
    var result = self
    result.subtract(other)
    return result
  }
}
