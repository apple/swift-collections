//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/9/21.
//

import XCTest
import CollectionsTestSupport
@testable import BitArrayModule

final class BitArrayTest: CollectionTestCase {
  
  // DEFINITELY needs improvement lol. I can imagine this looking like a terrible butcher to the experienced eye.
  let limit = 100 // if change limit, change getStorageCount and getExcessCount tests as well
  
  func testArrayLitInit() {
    
    let bitArray = BitArray(arrayLiteral: true, false, true, false, true, true, false, true, false, true)
    
    XCTAssertEqual(bitArray.storage, [181, 2])
    XCTAssertEqual(bitArray.excess, 2)
    XCTAssertEqual(bitArray.endIndex, bitArray.count)
    XCTAssertEqual(bitArray.endIndex, 9)
  }
  
  func testRemoveAll() {
    var testArray = BitArray()
    var value = Bool.random()
    
    for _ in 0...limit {
      testArray.append(value)
      value = Bool.random()
    }
    
    testArray.removeAll()
    
    XCTAssertEqual(testArray.count, 0)
    XCTAssertEqual(testArray.endIndex, 0)
    XCTAssertEqual(testArray.startIndex, 0)
    //XCTAssertEqual(testArray.getStorageCount(), 0)
    //XCTAssertEqual(testArray.getExcessCount(), 0)
  }
  
  func testSubscriptReturnOnly() {
    var testArray = BitArray()
    var value = Bool.random()
    
    
    for _ in 0...limit {
      testArray.append(value)
      value = Bool.random()
    }
    
    XCTAssertEqual(testArray.count, limit+1)
    XCTAssertEqual(testArray.endIndex, limit+1)
    XCTAssertEqual(testArray.startIndex, 0)
    //XCTAssertEqual(testArray.getStorageCount(), 13)
    //XCTAssertEqual(testArray.getExcessCount(), 5)
  }
  
  func testSubscriptSetOnly() {
    
    var testArray = BitArray()
    var value = Bool.random()
    
    
    for _ in 0...limit {
      testArray.append(value)
      value = Bool.random()
    }
    
    for i in 0..<testArray.endIndex {
      let setVal = Bool.random()
      let copy = testArray
      testArray[i] = setVal
      XCTAssertEqual(testArray[i], setVal)
      XCTAssertNotEqual(testArray[i], !setVal)
      
      testArray[i] = !setVal
      XCTAssertEqual(testArray[i], !setVal)
      XCTAssertNotEqual(testArray[i], setVal)
      
      // testing that previous values are unaffected
      for j in 0..<i {
        XCTAssertEqual(copy[j], testArray[j])
      }
    }
    
  }
  
  func testformBitwiseOR(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    testArray.formBitwiseOR(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(255)
    }
    resultStorage.append(31)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(testArray.storage, resultStorage)
    
  }
  
  func testformBitwiseAND(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    testArray.formBitwiseAND(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(0)
    }
    resultStorage.append(0)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(testArray.storage, resultStorage)
    
  }
  
  func testformBitwiseXOR(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    testArray.formBitwiseXOR(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(255)
    }
    resultStorage.append(31)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(testArray.storage, resultStorage)
    
  }
  
  func testBitwiseOR(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    let newArr = testArray.bitwiseOR(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(255)
    }
    resultStorage.append(31)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(newArr.storage, resultStorage)
    
  }
  
  func testBitwiseAND(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    let newArr = testArray.bitwiseAND(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(0)
    }
    resultStorage.append(0)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(newArr.storage, resultStorage)
    
  }
  
  func testBitwiseXOR(){
    var testArray = BitArray()
    var testArray2 = BitArray()
    
    for i in 0...limit {
      testArray.append((i%2 == 0))
    }
    
    for i in 0...limit {
      testArray2.append((i%2 != 0))
    }
    
    
    let newArr = testArray.bitwiseXOR(with: testArray2)
    
    var resultStorage: [UInt8] = []
    
    for _ in 0..<12 {
      resultStorage.append(255)
    }
    resultStorage.append(31)
    
    XCTAssertEqual(testArray.storage.count, 13)
    XCTAssertEqual(newArr.storage, resultStorage)
    
  }
  
  func testToggle() { // toggle function already works?
    var testArray = BitArray()
    var value = Bool.random()
    
    
    for _ in 0...limit {
      testArray.append(value)
      value = Bool.random()
    }
    
    var copyArray = testArray
    
    // will take each value and toggle it back and forth 4 times, making sure the rest of the array is unaffected each time
    for i in 0...limit {
      copyArray = testArray
      value = testArray[i]
      
      testArray[i].toggle()
      XCTAssertEqual(!value, testArray[i])
      testArray[i].toggle()
      XCTAssertEqual(value, testArray[i])
      XCTAssertEqual(copyArray, testArray)
    }
    
  }
  
}
