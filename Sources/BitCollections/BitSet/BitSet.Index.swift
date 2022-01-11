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

extension BitSet {
  @frozen
  public struct Index {
    @usableFromInline
    var _value: UInt

    @inlinable
    internal init(_value: UInt) {
      self._value = _value
    }

    @inlinable
    internal init(_position: _UnsafeHandle.Index) {
      self._value = _position.value
    }

    @inline(__always)
    internal var _position: _UnsafeHandle.Index {
      _UnsafeHandle.Index(_value)
    }
  }
}

extension BitSet.Index: Comparable, Hashable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }

  @inlinable
  public static func < (left: Self, right: Self) -> Bool {
    left._value < right._value
  }

  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_value)
  }
}
