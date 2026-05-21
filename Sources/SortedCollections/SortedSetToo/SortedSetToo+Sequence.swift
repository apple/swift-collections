//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension SortedSet: Sequence {
  public struct Iterator: IteratorProtocol {
    fileprivate var nextNode: SkipList.Node?

    mutating public func next() -> Element? {
      defer { nextNode = nextNode?.successors.first }

      return nextNode?.value
    }
  }

  public func makeIterator() -> Iterator {
    return .init(nextNode: self._storage.rowHeads.first?.head)
  }

  public var underestimatedCount: Int {
    self._storage.rowHeads.first?.count ?? 0
  }
}
