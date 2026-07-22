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
    unsafe Self(mutating: ._dangling())
  }
}
