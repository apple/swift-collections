struct Node48 {
  static let numKeys = 48

  var pointer: NodePtr
  var keys: UnsafeMutableBufferPointer<KeyPart>
  var childs: UnsafeMutableBufferPointer<NodePtr?>

  init(ptr: NodePtr) {
    self.pointer = ptr
    let body = ptr + MemoryLayout<NodeHeader>.stride
    self.keys = UnsafeMutableBufferPointer(
      start: body.assumingMemoryBound(to: KeyPart.self),
      count: 256
    )

    // NOTE: Initializes each key pointer to point to a value > number of children, as 0 will
    // refer to the first child.
    // TODO: Can we initialize buffer using any stdlib method?
    let childPtr = (body + 256 * MemoryLayout<KeyPart>.stride)
      .assumingMemoryBound(to: NodePtr?.self)
    self.childs = UnsafeMutableBufferPointer(start: childPtr, count: Self.numKeys)
  }
}

extension Node48 {
  static func allocate() -> Self {
    let buf = NodeBuffer.allocate(type: .node48, size: size)
    let node = Self(ptr: buf)
    for idx in 0..<256 {
      node.keys[idx] = 0xFF
    }
    return node
  }

  static func allocate(copyFrom: Node16) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)
    UnsafeMutableRawBufferPointer(node.childs).copyBytes(
      from: UnsafeMutableRawBufferPointer(copyFrom.childs))
    for (idx, key) in copyFrom.keys.enumerated() {
      node.keys[Int(key)] = UInt8(idx)
    }
    return node
  }

  static func allocate(copyFrom: Node256) -> Self {
    var node = Self.allocate()
    node.copyHeader(from: copyFrom)

    var slot = 0
    for (key, child) in copyFrom.childs.enumerated() {
      if child == nil {
        continue
      }

      node.keys[key] = UInt8(slot)
      node.childs[slot] = child
      slot += 1
    }

    return node
  }

  static var size: Int {
    MemoryLayout<NodeHeader>.stride + 256 * MemoryLayout<KeyPart>.stride + Self.numKeys
      * MemoryLayout<NodePtr>.stride
  }
}

extension Node48: Node {
  func type() -> NodeType { .node48 }

  func index(forKey k: KeyPart) -> Index? {
    let childIndex = Int(keys[Int(k)])
    return childIndex == 0xFF ? nil : childIndex
  }

  func index() -> Index? {
    return next(index: -1)
  }

  func next(index: Index) -> Index? {
    for idx: Int in index + 1..<256 {
      if keys[idx] != 0xFF {
        return Int(keys[idx])
      }
    }

    return nil
  }

  func child(forKey k: KeyPart, ref: inout ChildSlotPtr?) -> NodePtr? {
    let childIndex = Int(keys[Int(k)])
    if childIndex == 0xFF {
      return nil
    }

    ref = childs.baseAddress! + childIndex
    return child(at: childIndex)
  }

  func child(at: Int) -> NodePtr? {
    assert(at < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
    return childs[at]
  }

  func child(at index: Index, ref: inout ChildSlotPtr?) -> NodePtr? {
    assert(index < Self.numKeys, "maximum \(Self.numKeys) childs allowed")
    ref = childs.baseAddress! + index
    return childs[index]
  }

  mutating func addChild(
    forKey k: KeyPart,
    node: NodePtr,
    ref: ChildSlotPtr?
  ) {
    if count < Self.numKeys {
      assert(self.keys[Int(k)] == 0xFF, "node for key \(k) already exists")

      guard let slot = findFreeSlot() else {
        assert(false, "cannot find free slot in Node48")
        return
      }

      self.keys[Int(k)] = KeyPart(slot)
      self.childs[slot] = node
      self.count += 1
    } else {
      var newNode = Node256.allocate(copyFrom: self)
      newNode.addChild(forKey: k, node: node)
      ref?.pointee = newNode.pointer
      pointer.deallocate()
    }
  }

  public mutating func deleteChild(at index: Index, ref: ChildSlotPtr?) {
    let targetSlot = Int(keys[index])
    assert(targetSlot != 0xFF, "slot is empty already")
    let targetChildBuf = childs[targetSlot]
    targetChildBuf?.deallocate()

    // 1. Find out who has the last slot.
    var lastSlotKey = 0
    for k in 0..<256 {
      if keys[k] == count - 1 {
        lastSlotKey = k
        break
      }
    }

    // 2. Move last child slot into current child slot, and reset last child slot.
    childs[targetSlot] = childs[count - 1]
    childs[count - 1] = nil

    // 3. Map that key to current slot.
    keys[lastSlotKey] = UInt8(targetSlot)

    // 4. Clear input key.
    keys[index] = 0xFF

    // 5. Reduce number of children.
    count -= 1

    // 6. Shrink the node to Node16 if needed.
    if count == 13 {  // TODO: Should be made tunable.
      var newNode = Node16.allocate(copyFrom: self)
      ref?.pointee = newNode.pointer
      pointer.deallocate()
    }
  }

  private func findFreeSlot() -> Int? {
    for (index, child) in childs.enumerated() {
      if child == nil {
        return index
      }
    }

    return nil
  }

}
