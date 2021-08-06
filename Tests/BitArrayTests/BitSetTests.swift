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
  
  typealias UNIT = BitArray.UNIT
  let sizes = _getSizes(UNIT.bitWidth)
  
  func testBitArrayInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: UNIT.bitWidth) { layout in
      let bitArray = BitArray(layout)
      let bitSet = BitSet(bitArray)
      var expectedResult: [Int] = []
      
      for index in 0..<layout.endIndex {
        if (layout[index]) {
          expectedResult.append(index)
        }
      }
      
      let expectedStartIndex = (expectedResult.count == 0) ? bitArray.endIndex : expectedResult[0]
      let expectedEndIndex = (expectedResult.count == 0) ? bitArray.endIndex : expectedResult[expectedResult.endIndex-1]
      
      expectEqual(Array(bitSet), expectedResult)
      expectEqual(bitSet.count, expectedResult.count)
      expectEqual(bitSet.startIndex, BitSet.Index(bitArrayIndex: expectedStartIndex))
      expectEqual(bitSet.endIndex, BitSet.Index(bitArrayIndex: expectedEndIndex))
    }
  }
  
}
