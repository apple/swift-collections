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
  Self: RandomAccessContainer,
  Element: ~Copyable
{
  @inlinable
  public mutating func heapSort(
    in subrange: Range<Index>,
    by areInIncreasingOrder: (borrowing Element, borrowing Element) -> Bool
  ) {
    let c = self.distance(from: subrange.lowerBound, to: subrange.upperBound)
    var start = c / 2
    var end = c
    // Invariants:
    //   - 0 <= start <= end <= c
    //   - `0 ..< start` has unprocessed elements
    //   - `start ..< end` is a forest of heap-ordered segments
    //   - `end ..< subrange.upperBound` is sorted
    while end > 1 {
      if start > 0 {
        // Heap construction
        start -= 1
      } else {
        // Heap extraction
        end -= 1
        self.swapAt(
          subrange.lowerBound,
          self.index(subrange.lowerBound, offsetBy: end))
      }
      var root = start
      while true {
        var child = root * 2 + 1
        guard child < end else { break }
        var i = self.index(subrange.lowerBound, offsetBy: child)
        if child + 1 < end {
          let j = self.index(after: i)
          if areInIncreasingOrder(self[i], self[j]) {
            child += 1
            i = j
          }
        }
        let r = self.index(subrange.lowerBound, offsetBy: root)
        guard areInIncreasingOrder(self[r], self[i]) else { break }
        self.swapAt(r, i)
        root = child
      }
    }
  }

  @export(implementation)
  @_transparent
  public mutating func heapSort(
    by areInIncreasingOrder: (borrowing Element, borrowing Element) -> Bool
  ) {
    self.heapSort(in: self.startIndex ..< self.endIndex, by: areInIncreasingOrder)
  }
}

@available(SwiftStdlib 6.4, *)
extension PermutableContainer
where
  Self: RandomAccessContainer,
  Element: Comparable & ~Copyable
{
  @export(implementation)
  @_transparent
  public mutating func heapSort() {
    self.heapSort(in: self.startIndex ..< self.endIndex)
  }

  @export(implementation)
  @_transparent
  public mutating func heapSort(in subrange: Range<Index>) {
    self.heapSort(in: subrange, by: <)
  }
}

#endif
