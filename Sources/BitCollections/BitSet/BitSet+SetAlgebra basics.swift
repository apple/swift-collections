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

extension _BitSet {
  @usableFromInline
  internal func contains(_ member: UInt) -> Bool {
    _read { $0.contains(member) }
  }
}

extension BitSet {
  @inlinable
  public func contains(_ member: Element) -> Bool {
    guard let value = UInt(exactly: member) else { return false }
    return _core.contains(value)
  }
}

extension _BitSet {
  @usableFromInline
  internal mutating func insert(
    _ newMember: UInt
  ) -> Bool {
    _ensureCapacity(forValue: newMember)
    return _update { $0.insert(newMember) }
  }
}

extension BitSet {
  @inlinable
  @discardableResult
  public mutating func insert(
    _ newMember: Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    guard let i = UInt(exactly: newMember) else {
      preconditionFailure("Value out of range")
    }
    return (_core.insert(i), newMember)
  }

  @inlinable
  @discardableResult
  public mutating func update(with newMember: Element) -> Element? {
    insert(newMember).inserted ? newMember : nil
  }
}

extension _BitSet {
  @usableFromInline
  internal mutating func remove(_ member: UInt) -> Bool {
    _updateThenShrink { handle, shrink in
      shrink = handle.remove(member)
      return shrink
    }
  }
}

extension BitSet {
  @inlinable
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    guard let m = UInt(exactly: member) else { return nil }
    return _core.remove(m) ? member : nil
  }
}
