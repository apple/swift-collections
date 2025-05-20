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

extension SortedDictionary: Sequence {
  @inlinable
  public func forEach(_ body: (Element) throws -> Void) rethrows {
    try self._root.forEach(body)
  }
  
  /// An iterator over the elements of the sorted dictionary
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _iterator: _Tree.Iterator
    
    @inlinable
    @inline(__always)
    internal init(_base: SortedDictionary) {
      self._iterator = _base._root.makeIterator()
    }
    
    /// Advances to the next element and returns it, or nil if no next element exists.
    ///
    /// - Returns: The next element in the underlying sequence, if a next element exists;
    ///     otherwise, `nil`.
    /// - Complexity: O(1) amortized over the entire sequence.
    @inlinable
    public mutating func next() -> Element? {
      return self._iterator.next()
    }
  }
  
  /// Returns an iterator over the elements of the sorted dictionary.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base: self)
  }
}

extension SortedDictionary.Iterator: @unchecked Sendable
where Key: Sendable, Value: Sendable {}
