//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary: Collection {
  public struct Index: Comparable {
    @usableFromInline
    internal let _value: Int

    @usableFromInline
    internal init(_value: Int) {
      self._value = _value
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
      lhs._value < rhs._value
    }
  }

  @inlinable
  public var isEmpty: Bool { _root.count == 0 }

  @inlinable
  public var count: Int { _root.count }

  @inlinable
  public var startIndex: Index { Index(_value: 0) }

  @inlinable
  public var endIndex: Index { Index(_value: count) }
  
  @inlinable
  public func index(after i: Index) -> Index {
    Index(_value: i._value + 1)
  }
  
  /// Accesses the key-value pair at the specified position.
  @inlinable
  public subscript(position: Index) -> Element {
    _root.item(position: position._value)
  }
}

