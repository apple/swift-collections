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
  public func contains(_ member: Int) -> Bool {
    // Note: the generic overload over `FixedWidthInteger` below does not shadow
    // the default `contains` implementation from Sequence, so we provide this
    // overload that's dedicated to `Int`, the element type.
    //
    // `BitSet` does customize `_customContainsEquatableElement` so we'd get
    // an efficient implementation even without this, but it seems like a good
    // idea to make things explicit.
    guard let value = UInt(exactly: member) else { return false }
    return _contains(value)
  }

  @inlinable
  public func contains<I: FixedWidthInteger>(_ member: I) -> Bool {
    guard let value = UInt(exactly: member) else { return false }
    return _contains(value)
  }

  @usableFromInline
  internal func _contains(_ member: UInt) -> Bool {
    _read { $0.contains(member) }
  }

  @inlinable
  @discardableResult
  public mutating func insert<I: FixedWidthInteger>(
    _ newMember: I
  ) -> (inserted: Bool, memberAfterInsert: I) {
    guard let i = UInt(exactly: newMember) else {
      preconditionFailure("BitSet can only hold nonnegative integers")
    }
    return (_insert(i), newMember)
  }

  @usableFromInline
  internal mutating func _insert(
    _ newMember: UInt
  ) -> Bool {
    _ensureCapacity(forValue: newMember)
    return _update { $0.insert(newMember) }
  }

  @discardableResult
  public mutating func update<I: FixedWidthInteger>(
    with newMember: I
  ) -> I? {
    insert(newMember).inserted ? newMember : nil
  }

  @discardableResult
  public mutating func remove<I: FixedWidthInteger>(
    _ member: I
  ) -> I? {
    guard let m = UInt(exactly: member) else { return nil }
    return _remove(m) ? member : nil
  }

  @usableFromInline
  internal mutating func _remove(_ member: UInt) -> Bool {
    _updateThenShrink { handle, shrink in
      shrink = handle.remove(member)
      return shrink
    }
  }
}
