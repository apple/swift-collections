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

@usableFromInline
@frozen
@unsafe
internal struct _HashTreeIterator {
  @usableFromInline
  @unsafe
  internal struct _Opaque {
    @safe
    internal var ancestorSlots: _AncestorHashSlots
    @unsafe
    internal var ancestorNodes: _HashStack<_UnmanagedHashNode>
    @safe
    internal var level: _HashLevel
    @safe
    internal var isAtEnd: Bool

    @usableFromInline
    @_effects(releasenone)
    internal init(_ root: _UnmanagedHashNode) {
      self.ancestorSlots = .empty
      unsafe self.ancestorNodes = _HashStack(filledWith: root)
      self.level = .top
      self.isAtEnd = false
    }
  }

  @usableFromInline
  @unsafe
  internal let root: _RawHashStorage

  @usableFromInline
  @unsafe
  internal var node: _UnmanagedHashNode

  @usableFromInline
  @safe
  internal var slot: _HashSlot

  @usableFromInline
  @safe
  internal var endSlot: _HashSlot

  @usableFromInline
  @unsafe
  internal var _o: _Opaque

  @usableFromInline
  @_effects(releasenone)
  internal init(root: __shared _RawHashNode) {
    unsafe self.root = root.storage
    unsafe self.node = root.unmanaged
    self.slot = .zero
    self.endSlot = unsafe node.itemsEndSlot
    unsafe self._o = _Opaque(self.node)

    if unsafe node.hasItems { return }
    if unsafe node.hasChildren {
      unsafe _descendToLeftmostItem(ofChildAtSlot: .zero)
    } else {
      unsafe self._o.isAtEnd = true
    }
  }
}

extension _HashTreeIterator: @unsafe IteratorProtocol {
  @inlinable
  internal mutating func next(
  ) -> (node: _UnmanagedHashNode, slot: _HashSlot)? {
    guard slot < endSlot else {
      return unsafe _next()
    }
    defer { slot = slot.next() }
    return unsafe (node, slot)
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func _next(
  ) -> (node: _UnmanagedHashNode, slot: _HashSlot)? {
    if unsafe _o.isAtEnd { return nil }
    if unsafe node.hasChildren {
      unsafe _descendToLeftmostItem(ofChildAtSlot: .zero)
      slot = slot.next()
      return unsafe (node, .zero)
    }
    while unsafe !_o.level.isAtRoot {
      let nextChild = unsafe _ascend().next()
      if unsafe nextChild < node.childrenEndSlot {
        unsafe _descendToLeftmostItem(ofChildAtSlot: nextChild)
        slot = slot.next()
        return unsafe (node, .zero)
      }
    }
    // At end
    endSlot = unsafe node.itemsEndSlot
    slot = endSlot
    unsafe _o.isAtEnd = true
    return nil
  }
}

extension _HashTreeIterator {
  internal mutating func _descend(toChildSlot childSlot: _HashSlot) {
    assert(unsafe childSlot < node.childrenEndSlot)
    unsafe _o.ancestorSlots[_o.level] = childSlot
    unsafe _o.ancestorNodes.push(node)
    unsafe _o.level = _o.level.descend()
    unsafe node = node.unmanagedChild(at: childSlot)
    slot = .zero
    unsafe endSlot = node.itemsEndSlot
  }

  internal mutating func _ascend() -> _HashSlot {
    assert(unsafe !_o.level.isAtRoot)
    unsafe node = _o.ancestorNodes.pop()
    unsafe _o.level = _o.level.ascend()
    let childSlot = unsafe _o.ancestorSlots[_o.level]
    unsafe _o.ancestorSlots.clear(_o.level)
    return childSlot
  }

  internal mutating func _descendToLeftmostItem(
    ofChildAtSlot childSlot: _HashSlot
  ) {
    unsafe _descend(toChildSlot: childSlot)
    while endSlot == .zero {
      assert(unsafe node.hasChildren)
      unsafe _descend(toChildSlot: .zero)
    }
  }
}
