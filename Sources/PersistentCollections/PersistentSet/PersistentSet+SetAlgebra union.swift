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

extension PersistentSet {
  @inlinable
  public func union(_ other: __owned Self) -> Self {
    // FIXME: Do this with a structural merge.
    var copy = self
    for item in other {
      copy.insert(item)
    }
    return copy
  }
}
