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

extension _RawNode {
  @usableFromInline
  @frozen
  internal struct UnsafeHandle {
    @usableFromInline
    internal let _header: UnsafePointer<_StorageHeader>

    @usableFromInline
    internal let _memory: UnsafeRawPointer

    @inlinable
    internal init(
      _ header: UnsafePointer<_StorageHeader>,
      _ memory: UnsafeRawPointer
    ) {
      self._header = header
      self._memory = memory
    }
  }
}

extension _RawNode.UnsafeHandle {
  @inline(__always)
  internal var isCollisionNode: Bool {
    _header.pointee.isCollisionNode
  }

  @inline(__always)
  internal var hasChildren: Bool {
    _header.pointee.hasChildren
  }

  @inline(__always)
  internal var childCount: Int {
    _header.pointee.childCount
  }

  @inline(__always)
  internal var hasItems: Bool {
    _header.pointee.hasItems
  }

  @inline(__always)
  internal var itemCount: Int {
    _header.pointee.itemCount
  }


  @inline(__always)
  internal var _childrenStart: UnsafePointer<_RawNode> {
    _memory.assumingMemoryBound(to: _RawNode.self)
  }

  internal subscript(child offset: Int) -> _RawNode {
    unsafeAddress {
      assert(offset >= 0 && offset < childCount)
      return _childrenStart + offset
    }
  }

  internal var _children: UnsafeBufferPointer<_RawNode> {
    UnsafeBufferPointer(start: _childrenStart, count: childCount)
  }
}
