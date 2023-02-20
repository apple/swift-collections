//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension _Rope {
  mutating func builder(
    splittingAt position: Int,
    in metric: some _RopeMetric<Element>
  ) -> Builder {
    invalidateIndices()
    var builder = Builder()

    var position = position
    var node = root
    _root = nil
    while !node.isLeaf {
      let r = node.readInner { $0.findSlot(at: position, in: metric) }
      position = r.remaining
      node._innerSplit(at: r.slot, into: &builder)
    }

    let r = node.readLeaf { $0.findSlot(at: position, in: metric) }
    var item = node._leafSplit(at: r.slot, into: &builder)
    let index = metric.index(at: r.remaining, in: item.value)
    let suffix = item.split(at: index)
    builder.prependSuffix(suffix)
    builder.append(item.value)
    return builder
  }

  mutating func split(at index: Index) -> (builder: Builder, item: Element) {
    validate(index)
    precondition(index < endIndex)
    var builder = Builder()
    
    var node = root
    _root = nil
    while !node.isLeaf {
      let slot = index._path[node.height]
      precondition(slot < node.childCount, "Index out of bounds")
      node._innerSplit(at: slot, into: &builder)
    }
    
    let slot = index._path[node.height]
    precondition(slot < node.childCount, "Index out of bounds")
    let item = node._leafSplit(at: slot, into: &builder)
    invalidateIndices()
    return (builder, item.value)
  }

  mutating func split(at ropeIndex: Index, _ itemIndex: Element.Index) -> Builder {
    var (builder, item) = self.split(at: ropeIndex)
    let suffix = item.split(at: itemIndex)
    if !suffix.isEmpty {
      builder.prependSuffix(_Rope.Item(suffix))
    }
    if !item.isEmpty {
      builder.append(item)
    }
    return builder
  }
}

extension _Rope.Node {
  mutating func _innerSplit(
    at slot: Int,
    into builder: inout _Rope.Builder
  ) {
    assert(!self.isLeaf)
    assert(slot >= 0 && slot < childCount)
    ensureUnique()
    
    var slot = slot
    if slot == childCount - 2 {
      builder.prependSuffix(_removeNode(at: childCount - 1))
    }
    if slot == 1 {
      builder.append(_removeNode(at: 0))
      slot -= 1
    }
    
    var n = _removeNode(at: slot)
    swap(&self, &n)
    
    guard n.childCount > 0 else { return }
    if slot == 0 {
      builder.prependSuffix(n)
      return
    }
    if slot == n.childCount {
      builder.append(n)
      return
    }
    let suffix = n.split(keeping: slot)
    builder.append(n)
    builder.prependSuffix(suffix)
  }
  
  __consuming func _leafSplit(
    at slot: Int,
    into builder: inout _Rope.Builder
  ) -> Item {
    var n = self
    n.ensureUnique()
    
    assert(n.isLeaf)
    assert(slot >= 0 && slot < n.childCount)
    
    var slot = slot
    if slot == n.childCount - 2 {
      builder.prependSuffix(n._removeItem(at: childCount - 1).removed)
    }
    if slot == 1 {
      builder.append(n._removeItem(at: 0).removed.value)
      slot -= 1
    }
    
    let item = n._removeItem(at: slot).removed
    
    guard n.childCount > 0 else { return item }
    if slot == 0 {
      builder.prependSuffix(n)
    } else if slot == n.childCount {
      builder.append(n)
    } else {
      let suffix = n.split(keeping: slot)
      builder.append(n)
      builder.prependSuffix(suffix)
    }
    return item
  }
}
