private let FixedArray8Count = 8

struct FixedSizedArray8<Elem> {
  var storage: (Elem, Elem, Elem, Elem, Elem, Elem, Elem, Elem)

  init(val: Elem) {
    self.storage = (val, val, val, val, val, val, val, val)
  }

  mutating func copy(src: ArraySlice<Elem>, start: Int, count: Int) {
    // TODO: memcpy?
    for ii in 0..<min(FixedArray8Count, count) {
      self[ii] = src[src.startIndex + start + ii]
    }
  }

  mutating func copy(src: UnsafeMutableBufferPointer<Elem>, start: Int, count: Int) {
    for ii in 0..<min(FixedArray8Count, count) {
      self[ii] = src[start + ii]
    }
  }

  mutating func shiftLeft(toIndex: Int) {
    for ii in toIndex..<FixedArray8Count {
      self[ii - toIndex] = self[ii]
    }
  }

  subscript(position: Int) -> Elem {
    get {
      precondition(0 <= position && position < FixedArray8Count, "\(position)")
      return self[unchecked: position]
    }

    set {
      precondition(0 <= position && position < 8)
      self[unchecked: position] = newValue
    }
  }

  subscript(unchecked position: Int) -> Elem {
    get {
      return withUnsafeBytes(of: storage) { (ptr) -> Elem in
        let offset = MemoryLayout<Elem>.stride &* position
        return ptr.load(fromByteOffset: offset, as: Elem.self)
      }
    }
    set {
      let offset = MemoryLayout<Elem>.stride &* position
      withUnsafeMutableBytes(of: &storage) { (ptr) -> Void in
        ptr.storeBytes(
          of: newValue,
          toByteOffset: offset,
          as: Elem.self)
      }
    }
  }
}
