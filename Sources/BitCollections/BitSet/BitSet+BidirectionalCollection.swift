//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitSet: Sequence {
  @inlinable
  @inline(__always)
  public var underestimatedCount: Int {
    return count
  }

  @inlinable
  public func makeIterator() -> Iterator {
    return Iterator(self)
  }

  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    guard let element = UInt(exactly: element) else { return false }
    return _core._read { $0.contains(element) }
  }

  public struct Iterator: IteratorProtocol {
    internal typealias _UnsafeHandle = _BitSet.UnsafeHandle

    internal let bitset: BitSet
    internal var index: Int
    internal var word: _Word

    @usableFromInline
    internal init(_ bitset: BitSet) {
      self.bitset = bitset
      self.index = 0
      self.word = bitset._core._read { handle in
        guard handle.wordCount > 0 else { return .empty }
        return handle._words[0]
      }
    }

    @_effects(releasenone)
    public mutating func next() -> Element? {
      if let bit = word.next() {
        let i = _UnsafeHandle.Index(word: index, bit: bit)
        return Element(truncatingIfNeeded: i.value)
      }
      return bitset._core._read { handle in
        while (index + 1) < handle.wordCount {
          index += 1
          word = handle._words[index]
          if let bit = word.next() {
            let i = _UnsafeHandle.Index(word: index, bit: bit)
            return Element(truncatingIfNeeded: i.value)
          }
        }
        return nil
      }
    }
  }
}

extension BitSet: Collection, BidirectionalCollection {
  public var isEmpty: Bool { _core._count == 0 }
  public var count: Int { _core._count }

  public var startIndex: Index {
    // Note: This is O(n)
    Index(_position: _core._read { $0.startIndex })
  }

  public var endIndex: Index {
    Index(_position: .init(word: _core._storage.count, bit: 0))
  }
  
  public subscript(position: Index) -> Element {
    Element(position._position.value)
  }
  
  public func index(after index: Index) -> Index {
    Index(_position: _core._read { $0.index(after: index._position) })
  }
  
  public func index(before index: Index) -> Index {
    Index(_position: _core._read { $0.index(before: index._position) })
  }

  #if false // TODO: Specialize these
  public func distance(from start: Index, to end: Index) -> Int {
    fatalError("Unimplemented")
  }

  public func index(_ index: Index, offsetBy distance: Int) -> Index {
    fatalError("Unimplemented")
  }

  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    fatalError("Unimplemented")
  }
  #endif

  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    guard contains(element) else { return .some(nil) }
    return Index(_value: UInt(element))
  }

  public func _customLastIndexOfEquatableElement(
    _ element: Element
  ) -> Index?? {
    _customIndexOfEquatableElement(element)
  }
}
