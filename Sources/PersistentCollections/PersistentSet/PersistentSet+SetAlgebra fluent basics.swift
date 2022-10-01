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

extension PersistentSet {
  @inlinable
  public func inserting(_ newMember: __owned Element) -> Self {
    let hash = _Hash(newMember)
    let r = _root.inserting(.top, (newMember, ()), hash)
    return PersistentSet(_new: r.node)
  }

  @inlinable
  public func removing(_ member: Element) -> Self {
    let hash = _Hash(member)
    let r = _root.removing(.top, member, hash)
    guard let r = r else { return self }
    let root = r.replacement.finalize(.top)
    return PersistentSet(_new: root)
  }

  @inlinable
  public func updating(with newMember: __owned Element) -> Self {
    var copy = self
    copy.update(with: newMember)
    return copy
  }
}
