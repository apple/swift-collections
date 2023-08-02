extension UnsafeMutableBufferPointer {
  // Doesn't clear the shifted bytes.
  func shiftRight(startIndex: Int, endIndex: Int, by: Int) {
    var idx = endIndex
    while idx >= startIndex {
      self[idx + by] = self[idx]
      idx -= 1
    }
  }

  func shiftLeft(startIndex: Int, endIndex: Int, by: Int) {
    var idx = startIndex
    while idx <= endIndex {
      self[idx - by] = self[idx]
      idx += 1
    }
  }
}
