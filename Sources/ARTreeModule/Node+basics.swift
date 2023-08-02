extension Node {
  fileprivate var header: NodeHeaderPtr { self.pointer.assumingMemoryBound(to: NodeHeader.self) }

  var partialLength: Int {
    get { Int(self.header.pointee.partialLength) }
    set {
      assert(newValue <= Const.maxPartialLength)
      self.header.pointee.partialLength = KeyPart(newValue)
    }
  }

  var partialBytes: PartialBytes {
    get { header.pointee.partialBytes }
    set { header.pointee.partialBytes = newValue }
  }

  var count: Int {
    get { Int(header.pointee.count) }
    set { header.pointee.count = UInt16(newValue) }
  }

  func child(forKey k: KeyPart) -> NodePtr? {
    var ref = UnsafeMutablePointer<NodePtr?>(nil)
    return child(forKey: k, ref: &ref)
  }

  mutating func addChild(forKey k: KeyPart, node: NodePtr) {
    let ref = UnsafeMutablePointer<NodePtr?>(nil)
    addChild(forKey: k, node: node, ref: ref)
  }

  mutating func addChild(forKey k: KeyPart, node: Node) {
    let ref = UnsafeMutablePointer<NodePtr?>(nil)
    addChild(forKey: k, node: node, ref: ref)
  }

  mutating func addChild(
    forKey k: KeyPart,
    node: Node,
    ref: ChildSlotPtr?
  ) {
    addChild(forKey: k, node: node.pointer, ref: ref)
  }

  mutating func deleteChild(forKey k: KeyPart, ref: ChildSlotPtr?) {
    let index = index(forKey: k)
    assert(index != nil, "trying to delete key that doesn't exist")
    if index != nil {
      deleteChild(at: index!, ref: ref)
    }
  }

  mutating func deleteChild(forKey k: KeyPart) {
    var ptr: NodePtr? = self.pointer
    return deleteChild(forKey: k, ref: &ptr)
  }

  mutating func deleteChild(at index: Index) {
    var ptr: NodePtr? = self.pointer
    deleteChild(at: index, ref: &ptr)
  }

  mutating func copyHeader(from: any Node) {
    let src = from.header.pointee
    header.pointee.count = src.count
    header.pointee.partialLength = src.partialLength
    header.pointee.partialBytes = src.partialBytes
  }

  // Calculates the index at which prefix mismatches.
  func prefixMismatch(withKey key: Key, fromIndex depth: Int) -> Int {
    assert(partialLength <= Const.maxPartialLength, "partial length is always bounded")
    let maxComp = min(partialLength, key.count - depth)

    for index in 0..<maxComp {
      if partialBytes[index] != key[depth + index] {
        return index
      }
    }

    return maxComp
  }
}
