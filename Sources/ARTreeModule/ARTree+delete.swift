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

extension ARTree {
  public mutating func delete(key: Key) -> Bool {
    var ref: ChildSlotPtr? = ChildSlotPtr(&root)
    if let node = root {
      return _delete(node: node, ref: &ref, key: key, depth: 0)
    }

    return false
  }

  public mutating func deleteRange(start: Key, end: Key) {
    // TODO
    fatalError("not implemented")
  }

  private mutating func _delete(node: RawNode, ref: inout ChildSlotPtr?, key: Key, depth: Int) -> Bool
  {
    var newDepth = depth
    var _node = node

    if _node.type == .leaf {
      let leaf: NodeLeaf = _node.toLeafNode()

      if !leaf.keyEquals(with: key, depth: depth) {
        return false
      }

      ref?.pointee = nil
      leaf.withValue(of: Value.self) {
        $0.deinitialize(count: 1)
      }
      return true
    }

    var node = _node.toInternalNode()
    if node.partialLength > 0 {
      let matchedBytes = node.prefixMismatch(withKey: key, fromIndex: depth)
      assert(matchedBytes <= node.partialLength)
      newDepth += matchedBytes
    }

    guard let childPosition = node.index(forKey: key[newDepth]) else {
      // Key not found, nothing to do.
      return false
    }

    var childRef: ChildSlotPtr?
    let child = node.child(at: childPosition, ref: &childRef)!
    if !_delete(node: child, ref: &childRef, key: key, depth: newDepth + 1) {
      return false
    }

    let shouldDeleteNode = node.count == 1
    node.deleteChild(at: childPosition, ref: ref)

    // NOTE: node can be invalid because of node shrinking. Hence, we get count before.
    return shouldDeleteNode
  }
}
