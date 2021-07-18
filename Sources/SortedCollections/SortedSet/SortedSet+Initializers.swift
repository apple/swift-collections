//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SortedSet {
  /// Creates a new set from a finite sequence of items.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  /// - Complexity: O(`n log n`) where `n` is the number of elements
  ///   in the sequence.
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    self.init()
    
    for element in elements {
      self._root.updateAnyValue((), forKey: element)
    }
  }
  
  // TODO: potentially add unconditional
}
