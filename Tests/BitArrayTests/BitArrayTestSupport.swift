//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/15/21.
//
import _CollectionsTestSupport
@_spi(Testing) import BitArrayModule 

func withSomeUsefulBoolArrays<C: Collection>(
  _ label: String,
  ofSizes sizes: C,
  ofUnitBitWidth bitWidth: Int,
  file: StaticString = #file, line: UInt = #line,
  _ body: ([Bool]) throws -> Void
) rethrows -> Void where C.Element == Int {
  
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
}

func withTheirBitSetLayout<C: Collection>(
  _ label: String,
  ofLayout layout: C,
  file: StaticString = #file, line: UInt = #line,
  _ body: ([Int]) throws -> Void
) rethrows -> Void where C.Element == Bool, C.Index == Int {
  var intArray: [Int] = []
  for index in 0..<layout.endIndex {
    if(layout[index]) {
      intArray.append(index)
    }
  }
  
  let entry = TestContext.current.push("\(label): \(intArray)", file: file, line: line)
  defer { TestContext.current.pop(entry) }
  try body(intArray)
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
