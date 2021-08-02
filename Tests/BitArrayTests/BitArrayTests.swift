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
  
  func testExpressibleByArrayLiteral() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: BitArray.UNIT.bitWidth) { boolArray in
      let testBitArray = BitArray(boolArray)
      expectEqual(Array(testBitArray), boolArray)
    }
    //?
    // Using manually created Bool Arrays
    let testBitArray1: BitArray = []
    expectEqual(Array(testBitArray1), [])
    
    let testBitArray2: BitArray = [true]
    expectEqual(Array(testBitArray2), [true])
    expectEqual(testBitArray2.storage, [1])
    expectEqual(testBitArray2.excess, 1)
    
    let testBitArray3: BitArray = [false]
    expectEqual(Array(testBitArray3), [false])
    expectEqual(testBitArray3.storage, [0])
    expectEqual(testBitArray3.excess, 1)
    
    let testBitArray4: BitArray = [true, true, true, true, true, true, true, true]
    expectEqual(Array(testBitArray4), [true, true, true, true, true, true, true, true])
    expectEqual(testBitArray4.storage, [255])
    expectEqual(testBitArray4.excess, 0)
    
    let testBitArray4B: BitArray = [true, true, true, true, true, true, true, true, true]
    expectEqual(Array(testBitArray4B), [true, true, true, true, true, true, true, true, true])
    expectEqual(testBitArray4B.storage, [255, 1])
    expectEqual(testBitArray4B.excess, 1)
    
    let testBitArray5: BitArray = [false, false, false, false, false, false, false, false]
    expectEqual(Array(testBitArray5), [false, false, false, false, false, false, false, false])
    expectEqual(testBitArray5.storage, [0])
    expectEqual(testBitArray5.excess, 0)
    
    let testBitArray5B: BitArray = [false, false, false, false, false, false, false, false, false]
    expectEqual(Array(testBitArray5B), [false, false, false, false, false, false, false, false, false])
    expectEqual(testBitArray5B.storage, [0, 0])
    expectEqual(testBitArray5B.excess, 1)
    
    let testBitArray6: BitArray = [true, false, true, false, false, false, true]
    expectEqual(Array(testBitArray6), [true, false, true, false, false, false, true])
    expectEqual(testBitArray6.storage, [69])
    expectEqual(testBitArray6.excess, 7)
  }
  
  func testRepeatingInit() {
    for count in 0...50 {
      let trueArray = Array(repeating: true, count: count)
      let falseArray = Array(repeating: false, count: count)
      
      let trueBitArray = BitArray(trueArray)
      let falseBitArray = BitArray(falseArray)
      
      let repeatCount = (count%8 == 0) ? Int(count/8) : Int(count/8) + 1
      let expectedFalseStorage: [UInt8] = Array(repeating: 0, count: repeatCount)
      var expectedTrueStorage: [UInt8] = Array(repeating: 255, count: repeatCount)
      if (count%8 != 0) {
        expectedTrueStorage.removeLast()
        switch count%8 {
        case 1:
          expectedTrueStorage.append(1)
          break
        case 2:
          expectedTrueStorage.append(3)
          break
        case 3:
          expectedTrueStorage.append(7)
          break
        case 4:
            expectedTrueStorage.append(15)
            break
        case 5:
            expectedTrueStorage.append(31)
            break
        case 6:
            expectedTrueStorage.append(63)
            break
        case 7:
            expectedTrueStorage.append(127)
            break
        default:
          fatalError("I shouldn't be here.")
          break
        }
      }
      let expectedExcess: UInt8 = UInt8(count%8)
      
      expectEqual(Array(trueBitArray), trueArray)
      expectEqual(Array(falseBitArray), falseArray)
      expectEqual(trueBitArray.storage, expectedTrueStorage)
      expectEqual(falseBitArray.storage, expectedFalseStorage)
      expectEqual(trueBitArray.excess, expectedExcess)
      expectEqual(falseBitArray.excess, expectedExcess)
    }
  }
  
  func testAppend() {
    withSomeUsefulBoolArrays("bitArray", ofSizes: sizes, ofUnitBitWidth: BitArray.UNIT.bitWidth) { layout in
      print(layout)
    }
  }
}
