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

extension OrderedDictionary: Collection {

  public struct Index: Comparable {
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.value < rhs.value
    }
    
    @inlinable
    public init(value: Int) {
      self.value = value
    }
    
    public let value: Int
  }

  @inlinable
  @inline(__always)
  public var startIndex: Index {
    Index(value: _keys.startIndex)
  }

  @inlinable
  @inline(__always)
  public var endIndex: Index {
    Index(value: _keys.endIndex)
  }

  @inlinable
  @inline(__always)
  public func index(after i: Index) -> Index {
    Index(value: _keys.index(after: i.value))
  }

  @inlinable
  @inline(__always)
  public subscript(position: Index) -> (key: Key, value: Value) {
    get { (_keys[position.value], _values[position.value]) }
  }

}
