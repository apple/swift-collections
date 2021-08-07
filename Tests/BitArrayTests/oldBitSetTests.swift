//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/27/21.
//

import XCTest
import CollectionsTestSupport
@testable import BitArrayModule

final class oldBitSetTest: CollectionTestCase {
  
    typealias UNIT = BitArray.WORD
  let limit = 100
  
  func testSetInits() {
    let sequence = [0, 1, 3, 5, 7, 9, 15, 16, 17]
    let bitSet = BitSet(sequence)
    let bitSet2: BitSet = [0, 1, 3, 5, 7, 9, 15, 16, 17]
    let bitSet3 = BitSet(arrayLiteral: 0, 1, 3, 5, 7, 9, 15, 16, 17)
    
    XCTAssertEqual(bitSet, bitSet2)
    XCTAssertEqual(bitSet3, bitSet2)
    XCTAssertEqual(bitSet.storage.storage, [171, 130, 3])
  }
  
  func testAppend() {
    var testBitSet = BitSet()
    var num1: UNIT = 0
    var num2: UNIT = 0
    var num3: UNIT = 0
    var num4: UNIT = 0
    var valDeterminer: Bool = Bool.random()
    var count = 0
    
    for i in 0..<8 {
      if (valDeterminer) {
        testBitSet.forceInsert(i)
        num1 += (1 << (i%8))
        count += 1
      }
      
      XCTAssertEqual(testBitSet.count, count)
      valDeterminer = Bool.random()
    }
    
    XCTAssertEqual(num1, testBitSet.storage.storage[0])
    
    for i in 8..<16 {
      if (valDeterminer) {
        testBitSet.forceInsert(i)
        num2 += (1 << (i%8))
        count += 1
      }
      valDeterminer = Bool.random()
      XCTAssertEqual(testBitSet.count, count)
    }
    
    XCTAssertEqual(num1, testBitSet.storage.storage[0])
    XCTAssertEqual(num2, testBitSet.storage.storage[1])
    
    for i in 16..<24 {
      if (valDeterminer) {
        testBitSet.forceInsert(i)
        num3 += (1 << (i%8))
        count += 1
      }
      valDeterminer = Bool.random()
      XCTAssertEqual(testBitSet.count, count)
    }
    
    XCTAssertEqual(num1, testBitSet.storage.storage[0])
    XCTAssertEqual(num2, testBitSet.storage.storage[1])
    XCTAssertEqual(num3, testBitSet.storage.storage[2])
    
    for i in 24..<32 {
      if (valDeterminer) {
        testBitSet.forceInsert(i)
        num4 += (1 << (i%8))
        count += 1
      }
      valDeterminer = Bool.random()
      
      XCTAssertEqual(testBitSet.count, count)
    }
    
    XCTAssertEqual(num1, testBitSet.storage.storage[0])
    XCTAssertEqual(num2, testBitSet.storage.storage[1])
    XCTAssertEqual(num3, testBitSet.storage.storage[2])
    XCTAssertEqual(num4, testBitSet.storage.storage[3])
  }
  
  func testFormUnion() {
    
    // SAME SIZE && UNION SETS ALL BITS TO TRUE
    var sampleBitSet = BitSet()
    var sampleBitSet2 = BitSet()
    var valDeterminer: Bool = Bool.random()
    
    for i in 0..<100 {
      if (valDeterminer) {
        sampleBitSet.forceInsert(i)
      } else {
        sampleBitSet2.forceInsert(i)
      }
      valDeterminer = Bool.random()
    }
    
    //sampleBitSet.formUnion(with: sampleBitSet2)
    
    XCTAssertEqual(sampleBitSet.storage.storage, [BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, 15])
    
    var sampleBitSet3 = BitSet()
    var sampleBitSet4 = BitSet()
    
    for i in 0..<50 {
      if (valDeterminer) {
        sampleBitSet3.forceInsert(i)
      } else {
        sampleBitSet4.forceInsert(i)
      }
      valDeterminer = Bool.random()
    }
    
    for i in 50..<100 {
      sampleBitSet4.forceInsert(i)
    }
    
    //sampleBitSet3.formUnion(with: sampleBitSet4)
    
    XCTAssertEqual(sampleBitSet3.storage.storage, [BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, BitArray.WORD.max, 15])
  }
  
  func testIntArrayView() {
    var testBitSet = BitSet()
    var resultArray: [Int] = []
    var valDeterminer: Bool = Bool.random()
    
    for i in 0..<100 {
      if (valDeterminer) {
        testBitSet.forceInsert(i)
        resultArray.append(i)
      }
      valDeterminer = Bool.random()
    }
    
    
    //XCTAssertEqual(testBitSet.intArrayView(), resultArray)
  }
  
  func testCartesianProduct() {
    var bitSet1 = BitSet()
    var bitSet2 = BitSet()
    let numbers = [0, 1, 3, 5, 7, 9]
    
    for i in numbers {
      bitSet1.forceInsert(i)
      bitSet2.forceInsert(i)
    }
    
    //let result1 = bitSet1.cartesianProduct(with: bitSet2)
    //let result2 = bitSet2.cartesianProduct(with: bitSet1)
    
  }
  
  
}
