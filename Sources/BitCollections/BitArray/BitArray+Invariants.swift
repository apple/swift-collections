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

extension BitArray {
#if COLLECTIONS_INTERNAL_CHECKS
  @inline(never)
  @_effects(releasenone)
  public func _checkInvariants() {
    precondition(_count <= _storage.count * _Word.capacity)
    precondition(_count > (_storage.count - 1) * _Word.capacity)
    let p = _BitPosition(_count).split
    if p.bit > 0 {
      precondition(_storage.last!.subtracting(_Word(upTo: p.bit)) == .empty)
    }
  }
#else
  @inline(__always) @inlinable
  public func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}
