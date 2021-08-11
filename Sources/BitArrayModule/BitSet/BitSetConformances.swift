//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet: Collection, BidirectionalCollection {
  
  // when items are appended or removed, do these need to be recalculated, and is that does automatically?
  
  public var isEmpty: Bool { return count == 0 }
  
  public var startIndex: Index { return _getStartIndex() }
  // leaving it like this might be correct if firstTrueIndex was fast enough -- BENCHMARKS
  
  private func _getStartIndex() -> Index {
    guard let index = storage.firstTrueIndex() else {
      return Index(bitArrayIndex: storage.endIndex)
    }
    
    return Index(bitArrayIndex: index)
  }
  
  public var endIndex: Index { return Index(bitArrayIndex: storage.endIndex) }
  
  public var count: Int {
    var count = 0
    for byte in storage.storage {
      count += byte.nonzeroBitCount
    }
    return count
  }
  
  public subscript(position: Index) -> Int {
    get {
      precondition((startIndex.bitArrayIndex <= position.bitArrayIndex) && (endIndex.bitArrayIndex > position.bitArrayIndex), "Given Index is out of range")
      precondition((storage[position.bitArrayIndex]), "Index passed in is invalid: does not exist in the set")
      return position.bitArrayIndex
    }
  }
  
  // Do I need to keep the check in Index since the checks exist in subscript? I feel like I at least need to keep the range ones since subcript doesn't check that we're alreadt at the end/beginning or not?
  public func index(after: Index) -> Index {
    precondition((startIndex.bitArrayIndex <= after.bitArrayIndex) && (endIndex.bitArrayIndex > after.bitArrayIndex), "Given Index is out of range")
    precondition((storage[after.bitArrayIndex]), "Index passed in is invalid: does not exist in the set")
    precondition(after.bitArrayIndex != endIndex.bitArrayIndex, "Passed in Index is already the endIndex, and has no existing Indexes after it")
    // Optimize using storage.storage and leadingZeroCount/trailingZeroCount when benchmarking... I could do that now but Imma save this so I can feel the satisfaction of scoring faster numbers 🤪
    for i in (after.bitArrayIndex+1)..<storage.count {
      if (storage[i]) {
        return Index(bitArrayIndex: i)
      }
    }
    return endIndex
  }
  
  public func index(before: Index) -> Index {
    precondition(before.bitArrayIndex != startIndex.bitArrayIndex, "Passed in Index is already the startIndex, and has no existing Indexes before it")
    precondition((startIndex.bitArrayIndex < before.bitArrayIndex) && (endIndex.bitArrayIndex >= before.bitArrayIndex), "Given Index is out of range")
    precondition( ((before == endIndex) || (storage[before.bitArrayIndex])), "Index passed in is invalid: does not exist in the set")
    // Optimize using storage.storage and leadingZeroCount/trailingZeroCount when benchmarking... I could do that now but Imma save this so I can feel the satisfaction of scoring faster numbers 🤪
    
    for i in stride(from: (before.bitArrayIndex-1), through: 0, by: -1) {
      if (storage[i]) {
        return Index(bitArrayIndex: i)
      }
    }
    fatalError("Before not found :(")
  }
  
  public func index(_ index: Index, offsetBy distance: Int) -> Index {
    precondition((startIndex.bitArrayIndex <= index.bitArrayIndex) && (endIndex.bitArrayIndex >= index.bitArrayIndex), "Given Index is out of range")
    precondition((storage[index.bitArrayIndex]), "Index passed in is invalid: does not exist in the set")
    // Optimize using storage.storage and leadingZeroCount/trailingZeroCount when benchmarking... I could do that now but Imma save this so I can feel the satisfaction of scoring faster numbers 🤪
    var counter = 0
    if (distance == 0) {
      return index
    } else if (distance > 0) {
      for i in (index.bitArrayIndex+1)..<storage.count {
        if (storage[i]) {
          counter += 1
        }
        if (counter == distance) {
          return Index(bitArrayIndex: i)
        }
      }
    } else {
      for i in (0..<index.bitArrayIndex).reversed() {
        if (storage[i]) {
          counter += 1
        }
        if (counter == distance) {
          return Index(bitArrayIndex: i)
        }
      }
    }
    fatalError("Passed in distance points to an Index beyond the scope of the set") // Wondering if there is a simple way to put this as a precondition instead. Would be possible if the Indices were able to keep track of what number element of the Set it points to?
  }
  
}
