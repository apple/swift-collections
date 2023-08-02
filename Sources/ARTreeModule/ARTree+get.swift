extension ARTree {
  public func getValue(key: Key) -> Value? {
    var current = root
    var depth = 0
    while depth <= key.count {
      guard let node = current?.asNode(of: Value.self) else {
        return nil
      }

      if node.type() == .leaf {
        let leaf: NodeLeaf<Value> = node.pointer.asLeaf()
        return leaf.keyEquals(with: key)
          ? leaf.value
          : nil
      }

      if node.partialLength > 0 {
        let prefixLen = node.prefixMismatch(withKey: key, fromIndex: depth)
        assert(prefixLen <= Const.maxPartialLength, "partial length is always bounded")
        if prefixLen != node.partialLength {
          return nil
        }
        depth = depth + node.partialLength
      }

      current = node.child(forKey: key[depth])
      depth += 1
    }

    return nil
  }

  public mutating func getRange(start: Key, end: Key) {
    // TODO
    fatalError("not implemented")
  }
}
