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

extension BitArray: Sequence {
  public typealias Element = Bool
  public typealias Iterator = IndexingIterator<BitArray>
}

extension BitArray: RandomAccessCollection, MutableCollection {
  public typealias Index = Int
  public typealias SubSequence = Slice<BitArray>
  public typealias Indices = Range<Int>

  @inlinable
  public var count: Int {
    Int(_count)
  }

  @inlinable @inline(__always)
  public var startIndex: Int { 0 }

  @inlinable @inline(__always)
  public var endIndex: Int { count }

  @inlinable @inline(__always)
  public func index(after i: Int) -> Int { i + 1 }

  @inlinable @inline(__always)
  public func index(before i: Int) -> Int { i - 1 }

  @inlinable @inline(__always)
  public func formIndex(after i: inout Int) {
    i += 1
  }

  @inlinable @inline(__always)
  public func formIndex(before i: inout Int) {
    i -= 1
  }

  @inlinable @inline(__always)
  public func index(_ i: Int, offsetBy distance: Int) -> Int {
    i + distance
  }

  public subscript(position: Int) -> Bool {
    get {
      precondition(position >= 0 && position < _count, "Index out of bounds")
      return _read { handle in
        handle[position]
      }
    }
    set {
      precondition(position >= 0 && position < _count, "Index out of bounds")
      return _update { handle in
        handle[position] = newValue
      }
    }
  }
}
