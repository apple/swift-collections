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
}
