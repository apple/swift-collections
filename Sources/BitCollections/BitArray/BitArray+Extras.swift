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

extension BitArray {
  public mutating func truncateOrExtend(
    toCount count: Int,
    with padding: Bool = false
  ) {
    precondition(count >= 0, "Negative count")
    if count < _count {
      _removeLast(self.count - count)
    } else if count > _count {
      _extend(by: count - self.count, with: padding)
    }
  }
}
