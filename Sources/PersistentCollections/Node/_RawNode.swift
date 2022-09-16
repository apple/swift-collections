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

@usableFromInline
@frozen
internal struct _RawNode {
  @usableFromInline
  internal var storage: _RawStorage

  @usableFromInline
  internal var count: Int

  @inlinable
  internal init(storage: _RawStorage, count: Int) {
    self.storage = storage
    self.count = count
  }
}

extension _RawNode {
  @inline(__always)
  internal func read<R>(_ body: (UnsafeHandle) -> R) -> R {
    storage.withUnsafeMutablePointers { header, elements in
      body(UnsafeHandle(header, UnsafeRawPointer(elements)))
    }
  }
}

extension _RawNode {
  @inline(__always)
  internal var unmanaged: _UnmanagedNode {
    _UnmanagedNode(storage)
  }

  @inlinable @inline(__always)
  internal func isIdentical(to other: _UnmanagedNode) -> Bool {
    other.ref.toOpaque() == Unmanaged.passUnretained(storage).toOpaque()
  }
}

extension _RawNode {
  @usableFromInline
  internal func validatePath(_ path: _UnsafePath) {
    var l = _Level.top
    var n = self.unmanaged
    while l < path.level {
      let offset = path.ancestors[l]
      precondition(offset < n.childCount)
      n = n.unmanagedChild(at: offset)
      l = l.descend()
    }
    precondition(n == path.node)
    if path._isItem {
      precondition(path._nodeOffset < n.itemCount)
    } else {
      precondition(path._nodeOffset <= n.childCount)
    }
  }
}
