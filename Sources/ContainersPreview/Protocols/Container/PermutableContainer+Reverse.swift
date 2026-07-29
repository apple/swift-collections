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
where Self: BidirectionalContainer, Element: ~Copyable
{
  @inlinable
  public mutating func reverse() {
    var i = self.startIndex
    var j = self.endIndex
    while i != j {
      self.formIndex(before: &j)
      guard i != j else { break }
      self.swapAt(i, j)
      self.formIndex(after: &i)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension PermutableContainer
where
  Self: BidirectionalContainer,
  Element: ~Copyable,
  Index: Comparable
{
  @inlinable
  public mutating func reverseSubrange(_ range: Range<Index>) {
    var i = range.lowerBound
    var j = range.upperBound
    while i != j {
      self.formIndex(before: &j)
      guard i != j else { break }
      self.swapAt(i, j)
      self.formIndex(after: &i)
    }
  }
}

#endif
