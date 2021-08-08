//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 8/5/21.
//

import XCTest
import CollectionsTestSupport
@testable import BitArrayModule

final class BitSetTest: CollectionTestCase {
  
  typealias WORD = BitArray.WORD
  let sizes = _getSizes(WORD.bitWidth)
  
  func testBitArrayInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      let bitArray = BitArray(layout)
      let modifiedBitArrayAsBitSetWouldModify = _dropExcessFalses(forArr: bitArray)
      let bitSet = BitSet(bitArray)
      var expectedResult: [Int] = []
      
      for index in 0..<layout.endIndex {
        if (layout[index]) {
          expectedResult.append(index)
        }
      }
      
      let expectedStartIndex = (expectedResult.count == 0) ? 0 : expectedResult[0]
      let expectedEndIndex = (expectedResult.count == 0) ? 0 : modifiedBitArrayAsBitSetWouldModify.endIndex
      
      expectEqual(Array(bitSet), expectedResult)
      expectEqual(bitSet.count, expectedResult.count)
      expectEqual(bitSet.startIndex, BitSet.Index(bitArrayIndex: expectedStartIndex))
      expectEqual(bitSet.endIndex, BitSet.Index(bitArrayIndex: expectedEndIndex))
    }
    
  }
  
  
  func testSequenceInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolArray in
      let bitArray = BitArray(boolArray)
      let expectedBitSet = BitSet(bitArray)
      var sequence: [Int] = []
      
      for index in 0..<boolArray.endIndex {
        if (boolArray[index]) {
          sequence.append(index)
        }
      }
      
      let bitSet = BitSet(sequence)
      
      expectEqual(bitSet.storage.storage, expectedBitSet.storage.storage)
      expectEqual(bitSet.count, expectedBitSet.count)
      expectEqual(bitSet.count, sequence.count)
      expectEqual(bitSet.startIndex, expectedBitSet.startIndex)
      expectEqual(bitSet.endIndex, expectedBitSet.endIndex)
    }
  }
  
  private func _dropExcessFalses(forArr: BitArray) -> BitArray{
    // remove excess bytes
    var modifiedBitArray = forArr
    while(modifiedBitArray.storage.count != 0 && modifiedBitArray.storage[modifiedBitArray.storage.endIndex-1] == 0) {
      modifiedBitArray.storage.removeLast()
    }
    
    modifiedBitArray.excess = 0
    
    return modifiedBitArray
  }
  
  func testExpressibleByArrayLiteralAndArrayLiteralInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSetIntArray", ofLayout: layout) { bitSetIntArray in
        let bitArray = BitArray(layout)
        let bitSetFromBitArray = BitSet(bitArray)
        let bitSetFromIntArray = BitSet(bitSetIntArray)
        
        XCTAssertEqual(bitSetFromBitArray, bitSetFromIntArray) // used instead of expectEqual because expectEqual was requesting more context
        expectEqual(Array(bitSetFromBitArray), bitSetIntArray)
        expectEqual(Array(bitSetFromIntArray), bitSetIntArray)
        XCTAssertTrue(bitArray.startIndex <= bitArray.endIndex)
      }
    }
    
    #warning("The storage.storage comparison tests will fail if WORD is changed.")
    // manual tests
    let testBitSet1: BitSet = []
    expectEqual(Array(testBitSet1), [])
    expectEqual(testBitSet1.storage.storage, [])
    expectEqual(testBitSet1.storage.excess, 0)
    expectEqual(testBitSet1.count, 0)
    expectEqual(testBitSet1.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet1.endIndex, BitSet.Index(bitArrayIndex: 0))
    XCTAssertTrue(testBitSet1.startIndex <= testBitSet1.endIndex)
    
    let testBitSet2: BitSet = [0]
    expectEqual(Array(testBitSet2), [0])
    expectEqual(testBitSet2.storage.storage, [1])
    expectEqual(testBitSet2.storage.excess, 0)
    expectEqual(testBitSet2.count, 1)
    expectEqual(testBitSet2.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet2.endIndex, BitSet.Index(bitArrayIndex: 8))
    XCTAssertTrue(testBitSet2.startIndex < testBitSet2.endIndex)
    
    let testBitSet3: BitSet = [0, 1, 2, 3]
    expectEqual(Array(testBitSet3), [0, 1, 2, 3])
    expectEqual(testBitSet3.storage.storage, [15])
    expectEqual(testBitSet3.storage.excess, 0)
    expectEqual(testBitSet3.count, 4)
    expectEqual(testBitSet3.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet3.endIndex, BitSet.Index(bitArrayIndex: 8))
    XCTAssertTrue(testBitSet3.startIndex < testBitSet3.endIndex)
    
    let testBitSet4: BitSet = [0, 1, 3, 5, 11]
    expectEqual(Array(testBitSet4), [0, 1, 3, 5, 11])
    expectEqual(testBitSet4.storage.storage, [43, 8])
    expectEqual(testBitSet4.storage.excess, 0)
    expectEqual(testBitSet4.count, 5)
    expectEqual(testBitSet4.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet4.endIndex, BitSet.Index(bitArrayIndex: 16))
    XCTAssertTrue(testBitSet4.startIndex < testBitSet4.endIndex)
    
    let testBitSet5: BitSet = [1, 11, 99]
    expectEqual(Array(testBitSet5), [1, 11, 99])
    expectEqual(testBitSet5.storage.storage, [2, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8])
    expectEqual(testBitSet5.storage.excess, 0)
    expectEqual(testBitSet5.count, 3)
    expectEqual(testBitSet5.startIndex, BitSet.Index(bitArrayIndex: 1))
    expectEqual(testBitSet5.endIndex, BitSet.Index(bitArrayIndex: 104))
    XCTAssertTrue(testBitSet5.startIndex < testBitSet5.endIndex)
    
    // testing duplicate, unordered values, as well as major gaps between set elements
    let testBitSet6: BitSet = [9, 11, 12, 15, 17, 32, 45, 46, 45, 47, 14, 10, 99]
    expectEqual(Array(testBitSet6), [9, 10, 11, 12, 14, 15, 17, 32, 45, 46, 47, 99])
    expectEqual(testBitSet6.storage.storage, [0, 222, 2, 0, 1, 224, 0, 0, 0, 0, 0, 0, 8])
    expectEqual(testBitSet6.storage.excess, 0)
    expectEqual(testBitSet6.count, 12)
    expectEqual(testBitSet6.startIndex, BitSet.Index(bitArrayIndex: 9))
    expectEqual(testBitSet6.endIndex, BitSet.Index(bitArrayIndex: 104))
    XCTAssertTrue(testBitSet6.startIndex < testBitSet6.endIndex)
    
    var expectedArrayFor7: [UInt8] = [8, 220, 2, 0, 1, 224, 0, 0, 0, 0, 0, 0, 8]
    expectedArrayFor7 += Array(repeating: 0, count: 402)
    expectedArrayFor7.append(16)
    
    let testBitSet7: BitSet = [3, 11, 12, 12, 15, 17, 32, 45, 46, 45, 47, 14, 10, 99, 3324]
    expectEqual(Array(testBitSet7), [3, 10, 11, 12, 14, 15, 17, 32, 45, 46, 47, 99, 3324])
    expectEqual(testBitSet7.storage.storage, expectedArrayFor7)
    expectEqual(testBitSet7.storage.excess, 0)
    expectEqual(testBitSet7.count, 13)
    expectEqual(testBitSet7.startIndex, BitSet.Index(bitArrayIndex: 3))
    expectEqual(testBitSet7.endIndex, BitSet.Index(bitArrayIndex: 3328))
    XCTAssertTrue(testBitSet7.startIndex < testBitSet7.endIndex)
  }
  
  func testInsertAndContains() {
    var values: [Int] = [0]
    for value in 1...2*WORD.bitWidth+13 {
      values.append(value)
    }
    values.append(3320)
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSet", ofLayout: layout) { bitSetIntArray in
        var bitSet = BitSet(bitSetIntArray)
        var intArrayCopy = bitSetIntArray
        
        for value in values {
          if (!intArrayCopy.contains(value)) {
            intArrayCopy.append(value)
            expectFalse(bitSet.contains(value))
          }
          bitSet.insert(value)
          expectEqual(Array(bitSet), intArrayCopy.sorted())
          expectTrue(bitSet.contains(value))
        }
        
        expectFalse(bitSet.contains(999999))
        
      }
    }
    
    //test with empty initializer
    var bitSet = BitSet()
    var layout: [Int] = []
    
    for value in values {
      if (!layout.contains(value)) {
        layout.append(value)
        expectFalse(bitSet.contains(value))
      }
      bitSet.insert(value)
      expectEqual(Array(bitSet), layout.sorted())
      expectTrue(bitSet.contains(value))
    }
    
    expectFalse(bitSet.contains(999999))
    
  }
  
  func testForceInsertAndContains() {
    var values: [Int] = [0]
    for value in 1...2*WORD.bitWidth+13 {
      values.append(value)
    }
    values.append(3320)
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSet", ofLayout: layout) { bitSetIntArray in
        var bitSet = BitSet(bitSetIntArray)
        var intArrayCopy = bitSetIntArray
        
        for value in values {
          if (!intArrayCopy.contains(value)) {
            intArrayCopy.append(value)
            expectFalse(bitSet.contains(value))
          }
          bitSet.forceInsert(value)
          expectEqual(Array(bitSet), intArrayCopy.sorted())
          expectTrue(bitSet.contains(value))
        }
        
        expectFalse(bitSet.contains(999999))
        
      }
    }
    
    //test with empty initializer
    var bitSet = BitSet()
    var layout: [Int] = []
    
    for value in values {
      if (!layout.contains(value)) {
        layout.append(value)
        expectFalse(bitSet.contains(value))
      }
      bitSet.forceInsert(value)
      expectEqual(Array(bitSet), layout.sorted())
      expectTrue(bitSet.contains(value))
    }
    
    expectFalse(bitSet.contains(999999))
    
  }
}