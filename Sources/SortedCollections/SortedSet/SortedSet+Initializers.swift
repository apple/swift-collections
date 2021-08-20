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
  
  /// Creates a dictionary from a sequence of **sorted** elements.
  ///
  /// This is a more efficient alternative to ``init(_:)`` which offers
  /// better asymptotic performance, and also reduces memory usage when constructing a
  /// sorted set on a pre-sorted sequence.
  ///
  /// - Parameter elements: A sequence of elements in non-decreasing comparison order for the
  ///     new set.
  /// - Complexity: O(`n`) where `n` is the number of elements in the
  ///     sequence.
  @inlinable
  public init<S: Sequence>(
    sortedElements elements: S
  ) where S.Element == Element {
    var builder = _Tree.Builder()
    
    var previousElement: Element? = nil
    for element in elements {
      precondition(previousElement == nil || previousElement! < element,
             "Sequence out of order.")
      builder.append(element)
      previousElement = element
    }
    
    self.init(_rootedAt: builder.finish())
  }
}
