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
import Builtin

extension UnsafeMutablePointer where Pointee: ~Copyable {
  // FIXME: Remove this once the standard `pointee` has a borrow accessor.
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  package var _pointee: Pointee {
    @_unsafeSelfDependentResult
    borrow {
      Builtin.borrowAt(self._rawValue)
    }
    @_unsafeSelfDependentResult
    nonmutating mutate {
      unsafe &self.pointee
    }
  }
}

#endif

extension UnsafeMutablePointer where Pointee: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  package static func _dangling() -> Self {
    return unsafe Self(mutating: ._dangling())
  }
}

extension UnsafeMutablePointer where Pointee: ~Copyable {
  /// Deinitialize `count` consecutive elements starting at this address.
  @_alwaysEmitIntoClient
  @_transparent
  @unsafe
  package func _deinitializeElements(count: Int) {
    /// Swift 6.2 optimizer bug: when specialized for a noncopyable type with a
    /// `deinit`, `deinitialize(count:)` over multiple elements can get compiled
    /// into a no-op, leaking the elements. Destroying elements one by one avoids
    /// this, but only if we do it by moving them out: a loop of
    /// `deinitialize(count: 1)` calls gets miscompiled the same way when the
    /// element type's `deinit` is inlined across module boundaries.
#if compiler(<6.3)
    for i in 0 ..< count {
      _ = unsafe (self + i).move()
    }
#else
    unsafe self.deinitialize(count: count)
#endif
  }
}
