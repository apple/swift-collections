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
#if COLLECTIONS_INTERNAL_CHECKS
  @inline(never)
  @_effects(releasenone)
  public func _checkInvariants() {
    //let actualCount = _storage.reduce(into: 0) { $0 += $1.count }
    //precondition(_count == actualCount, "Invalid count")

    precondition(_storage.isEmpty || !_storage.last!.isEmpty,
                 "Extraneous tail slot")
  }
#else
  @inline(__always) @inlinable
  public func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}
