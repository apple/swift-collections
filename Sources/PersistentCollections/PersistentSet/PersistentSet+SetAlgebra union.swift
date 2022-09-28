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
    let r = _root.union(.top, .emptyPrefix, other._root)
    guard r.copied else { return self }
    r.node._fullInvariantCheck(.top, .emptyPrefix)
    return PersistentSet(_new: r.node)
  }
}
