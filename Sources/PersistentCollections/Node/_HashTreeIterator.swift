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
internal struct _HashTreeIterator {
  @usableFromInline
  internal struct _Opaque {
    internal var ancestorSlots: _AncestorSlots
    internal var ancestorNodes: _Stack<_UnmanagedNode>
    internal var level: _Level
    internal var isAtEnd: Bool

    @usableFromInline
    @_effects(releasenone)
    internal init(_ root: _UnmanagedNode) {
      self.ancestorSlots = .empty
      self.ancestorNodes = _Stack(filledWith: root)
      self.level = .top
      self.isAtEnd = false
    }
  }

  @usableFromInline
  internal let root: _RawStorage

  @usableFromInline
  internal var node: _UnmanagedNode

  @usableFromInline
  internal var slot: _Slot

  @usableFromInline
  internal var endSlot: _Slot

  @usableFromInline
  internal var _o: _Opaque

  @usableFromInline
  @_effects(releasenone)
  internal init(root: __shared _RawNode) {
    self.root = root.storage
    self.node = root.unmanaged
    self.slot = .zero
    self.endSlot = node.itemsEndSlot
    self._o = _Opaque(self.node)

    if node.hasItems { return }
    if node.hasChildren {
      _descendToLeftmostItem(ofChildAtSlot: .zero)
    } else {
      self._o.isAtEnd = true
    }
  }
}

extension _HashTreeIterator: IteratorProtocol {
  @inlinable
  internal mutating func next() -> (node: _UnmanagedNode, slot: _Slot)? {
    guard slot < endSlot else {
      return _next()
    }
    defer { slot = slot.next() }
    return (node, slot)
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func _next() -> (node: _UnmanagedNode, slot: _Slot)? {
    if _o.isAtEnd { return nil }
    if node.hasChildren {
      _descendToLeftmostItem(ofChildAtSlot: .zero)
      slot = slot.next()
      return (node, .zero)
    }
    while !_o.level.isAtRoot {
      let nextChild = _ascend().next()
      if nextChild < node.childrenEndSlot {
        _descendToLeftmostItem(ofChildAtSlot: nextChild)
        slot = slot.next()
        return (node, .zero)
      }
    }
    // At end
    endSlot = node.itemsEndSlot
    slot = endSlot
    _o.isAtEnd = true
    return nil
  }
}

extension _HashTreeIterator {
  internal mutating func _descend(toChildSlot childSlot: _Slot) {
    assert(childSlot < node.childrenEndSlot)
    _o.ancestorSlots[_o.level] = childSlot
    _o.ancestorNodes.push(node)
    _o.level = _o.level.descend()
    node = node.unmanagedChild(at: childSlot)
    slot = .zero
    endSlot = node.itemsEndSlot
  }

  internal mutating func _ascend() -> _Slot {
    assert(!_o.level.isAtRoot)
    node = _o.ancestorNodes.pop()
    _o.level = _o.level.ascend()
    let childSlot = _o.ancestorSlots[_o.level]
    _o.ancestorSlots.clear(_o.level)
    return childSlot
  }

  internal mutating func _descendToLeftmostItem(
    ofChildAtSlot childSlot: _Slot
  ) {
    _descend(toChildSlot: childSlot)
    while endSlot == .zero {
      assert(node.hasChildren)
      _descend(toChildSlot: .zero)
    }
  }
}
