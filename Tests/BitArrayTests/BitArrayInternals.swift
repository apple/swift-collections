//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/15/21.
//
import CollectionsTestSupport
@_spi(Testing) import BitArrayModule 

func withSomeUsefulBitArrays<C: Collection>(
  _ label: String,
  ofSizes sizes: C,
  ofUnitBitWidth bitWidth: Int,
  file: StaticString = #file, line: UInt = #line,
  _ body: ([Bool]) throws -> Void
) rethrows -> Void where C.Element == Int {
  
  if (bitWidth > 32) {
    for size in sizes {
      let allFalses = Array(repeating: false, count: size)
      let falseEntry = TestContext.current.push("\(label): \(allFalses)", file: file, line: line)
      do {
        defer { TestContext.current.pop(falseEntry) }
        try body(allFalses)
      }
      let allTrues = Array(repeating: true, count: size)
      let trueEntry = TestContext.current.push("\(label): \(allTrues)", file: file, line: line)
      do {
        defer { TestContext.current.pop(trueEntry) }
        try body(allTrues)
      }
      for _ in 0 ... 10 {
        let array = (0 ..< size).map { _ in Bool.random() }
        let entry = TestContext.current.push("\(label): \(array)", file: file, line: line)
        defer { TestContext.current.pop(entry) }
        try body(array)
      }
    }
  } else {
    for size in sizes {
      let values = [0, 1]
      var bitArray: [Bool] = []
      for combo in values.combinations(ofCount: size) {
        for value in combo {
          if (value == 1) {
            bitArray.append(true)
          } else {
            bitArray.append(false)
          }
        }
      }
      let entry = TestContext.current.push("\(label): \(bitArray)", file: file, line: line)
      defer { TestContext.current.pop(entry) }
      try body(bitArray)
    }
  }
}

fileprivate func _allBitArrays() {
  
}

fileprivate func _someBitArrays() {
  
}

internal func _getSizes(_ bitWidth: Int) -> [Int] {
  var sizes: [Int] = []
  for i in 0...bitWidth+1 {
    sizes.append(i)
  }
  
  sizes.append(2*bitWidth-1)
  sizes.append(2*bitWidth)
  sizes.append(2*bitWidth+1)
  sizes.append(2*bitWidth + Int.random(in: 2..<bitWidth))
  
  return sizes
}
