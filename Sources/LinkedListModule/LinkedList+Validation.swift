//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @inlinable
  @inline(never)
  public func _checkInvariants() {
    precondition(_version._bits != 0 || _count == 0, "LinkedList: Invalid version")
    var tortoise = unsafe _first
    var hare = unsafe _first
    var last = unsafe _first
    var c = 0
    while let current = unsafe hare {
      if !c.isMultiple(of: 2) {
        unsafe tortoise = tortoise?.pointee.next
      }
      unsafe last = current
      unsafe hare = current.pointee.next
      c += 1
      unsafe precondition(hare != tortoise, "LinkedList: Cycle detected")
    }
    precondition(c == _count, "LinkedList: Invalid count")
    unsafe precondition(last == _last, "LinkedList: Invalid last node")
  }
}
#endif
