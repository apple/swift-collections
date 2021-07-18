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

// TODO: add custom forEach?
// TODO: benchmark

extension SortedDictionary: Sequence {
  /// An iterator over the elements of the sorted dictionary
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _iterator: _Tree.Iterator
    
    @inlinable
    internal init(_base: SortedDictionary) {
      self._iterator = _base._root.makeIterator()
    }
    
    @inlinable
    public mutating func next() -> Element? {
      return self._iterator.next()
    }
  }
  
  /// Returns an iterator over the elements of the sorted dictionary.
  ///
  /// - Complexity: O(1)
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base: self)
  }
}
