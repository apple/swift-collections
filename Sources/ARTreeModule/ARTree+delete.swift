extension ARTree {
  public mutating func delete(key: Key) -> Bool {
    var ref: ChildSlotPtr? = ChildSlotPtr(&root)
    if let node = root?.asNode(of: Value.self) {
      return _delete(node: node, ref: &ref, key: key, depth: 0)
    }

    return false
  }

  public mutating func deleteRange(start: Key, end: Key) {
    // TODO
    fatalError("not implemented")
  }

  private mutating func _delete(node: Node, ref: inout ChildSlotPtr?, key: Key, depth: Int) -> Bool
  {
    var newDepth = depth
    var node = node

    if node.type() == .leaf {
      let leaf = node as! NodeLeaf<Value>

      if !leaf.keyEquals(with: key, depth: depth) {
        return false
      }

      ref?.pointee = nil
      leaf.valuePtr.deinitialize(count: 1)
      return true
    }

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
    let child = node.child(at: childPosition, ref: &childRef)!.asNode(of: Value.self)!
    if !_delete(node: child, ref: &childRef, key: key, depth: newDepth + 1) {
      return false
    }

    let shouldDeleteNode = node.count == 1
    node.deleteChild(at: childPosition, ref: ref)

    // NOTE: node can be invalid because of node shrinking. Hence, we get count before.
    return shouldDeleteNode
  }
}
