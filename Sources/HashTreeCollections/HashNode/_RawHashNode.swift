//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A type-erased node in a hash tree. This doesn't know about the user data
/// stored in the tree, but it has access to subtree counts and it can be used
/// to freely navigate within the tree structure.
///
/// This construct is powerful enough to implement APIs such as `index(after:)`,
/// `distance(from:to:)`, `index(_:offsetBy:)` in non-generic code.
@usableFromInline
@frozen
@safe
internal struct _RawHashNode {
  @usableFromInline
  internal var storage: _RawHashStorage

  @usableFromInline
  internal var count: Int

  @inlinable
  internal init(storage: _RawHashStorage, count: Int) {
    self.storage = storage
    self.count = count
  }
}

extension _RawHashNode {
  @inline(__always)
  @unsafe
  internal func read<R>(_ body: (UnsafeHandle) -> R) -> R {
    unsafe storage.withUnsafeMutablePointers { header, elements in
      unsafe body(UnsafeHandle(header, UnsafeRawPointer(elements)))
    }
  }
}

extension _RawHashNode {
  @inlinable @inline(__always)
  @unsafe
  internal var unmanaged: _UnmanagedHashNode {
    unsafe _UnmanagedHashNode(storage)
  }

  @inlinable @inline(__always)
  internal func isIdentical(to other: _UnmanagedHashNode) -> Bool {
    unsafe other.ref.toOpaque() == Unmanaged.passUnretained(storage).toOpaque()
  }
}

extension _RawHashNode {
  @usableFromInline
  internal func validatePath(_ path: _UnsafePath) {
    var l = _HashLevel.top
    var n = unsafe self.unmanaged
    while l < path.level {
      let slot = path.ancestors[l]
      precondition(unsafe slot < n.childrenEndSlot)
      unsafe n = n.unmanagedChild(at: slot)
      l = l.descend()
    }
    precondition(unsafe n == path.node)
    if path._isItem {
      precondition(unsafe path.nodeSlot < n.itemsEndSlot)
    } else {
      precondition(unsafe path.nodeSlot <= n.childrenEndSlot)
    }
  }
}
