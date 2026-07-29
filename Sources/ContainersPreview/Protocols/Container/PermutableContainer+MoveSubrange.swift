//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension PermutableContainer
where
  Self: BidirectionalContainer,
  Element: ~Copyable,
  Index: Comparable
{
  @inlinable
  @discardableResult
  public mutating func moveSubrange(
    _ subrange: Range<Index>,
    to insertionPoint: Index
  ) -> Range<Index> {
    if subrange.contains(insertionPoint) {
      return subrange
    }
    let c = self.distance(from: subrange.lowerBound, to: subrange.upperBound)
    if insertionPoint < subrange.lowerBound {
      self.reverseSubrange(insertionPoint ..< subrange.upperBound)
      let cut = self.index(insertionPoint, offsetBy: c)
      self.reverseSubrange(insertionPoint ..< cut)
      self.reverseSubrange(cut ..< subrange.upperBound)
      return insertionPoint ..< cut
    }
    self.reverseSubrange(subrange.lowerBound ..< insertionPoint)
    let cut = self.index(insertionPoint, offsetBy: -c)
    self.reverseSubrange(subrange.lowerBound ..< cut)
    self.reverseSubrange(cut ..< insertionPoint)
    return cut ..< insertionPoint
  }
}

#endif
