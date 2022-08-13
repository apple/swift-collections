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
  @usableFromInline
  internal func _contains(_ member: UInt) -> Bool {
    _read { $0.contains(member) }
  }

  public func contains(_ member: Int) -> Bool {
    guard let member = UInt(exactly: member) else { return false }
    return _contains(member)
  }
}

extension BitSet {
  @discardableResult
  public mutating func _insert(_ i: UInt) -> Bool {
    _ensureCapacity(forValue: i)
    let inserted = _update { $0.insert(i) }
    return inserted
  }

  @discardableResult
  public mutating func insert(
    _ newMember: Int
  ) -> (inserted: Bool, memberAfterInsert: Int) {
    guard let i = UInt(exactly: newMember) else {
      preconditionFailure("Value out of range")
    }
    return (_insert(i), newMember)
  }

  @discardableResult
  public mutating func update(with newMember: Int) -> Int? {
    insert(newMember).inserted ? newMember : nil
  }
}

extension BitSet {
  @discardableResult
  @usableFromInline
  internal mutating func _remove(_ member: UInt) -> Bool {
    _updateThenShrink { handle, shrink in
      shrink = handle.remove(member)
      return shrink
    }
  }

  @discardableResult
  public mutating func remove(_ member: Int) -> Int? {
    guard let m = UInt(exactly: member) else { return nil }
    return _remove(m) ? member : nil
  }
}
