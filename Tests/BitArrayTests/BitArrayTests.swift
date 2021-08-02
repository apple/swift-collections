//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 7/27/21.
//

import XCTest
import CollectionsTestSupport
@testable import BitArrayModule

final class BitArrayTest: CollectionTestCase {
  
  let sizes: [Int] = _getSizes(BitArray.UNIT.bitWidth)
  
  func testSequenceInitializer() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: BitArray.UNIT.bitWidth) { boolArray in
        let testBitArray: BitArray = BitArray(boolArray)
        expectEqual(Array(testBitArray), boolArray)
    }
  }
  
  func testAppend() {
    withSomeUsefulBoolArrays("bitArray", ofSizes: sizes, ofUnitBitWidth: BitArray.UNIT.bitWidth) { layout in
      print(layout)
    }
  }
}
