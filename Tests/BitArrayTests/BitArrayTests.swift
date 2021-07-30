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
  
  func testAppend() {
    withSomeUsefulBitArrays("bitArray", ofSizes: sizes, ofUnitBitWidth: BitArray.UNIT.bitWidth) { layout in
    }
  }
}
