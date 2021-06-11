//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/9/21.
//

import Foundation
import XCTest
import CollectionsTestSupport
@_spi(Testing) import BitArrayModule

final class BitArrayTest: CollectionTestCase {
    
    var testArray = BitArray()
    
    func testAppend() {
        let limit = 100 // if change limit, change getStorageCount and getExcessCount tests as well
        var value = Bool.random()
        
        for i in 0...limit {
            testArray.append(value)
            XCTAssertEqual(testArray[i], value)
            
            XCTAssertEqual(testArray.count, i+1)
            XCTAssertEqual(testArray.endIndex, i+1)
            XCTAssertEqual(testArray.startIndex, 0)
            
            value = Bool.random()
        }
        XCTAssertEqual(testArray.count, limit+1)
        XCTAssertEqual(testArray.endIndex, limit+1)
        XCTAssertEqual(testArray.startIndex, 0)
        XCTAssertEqual(testArray.getStorageCount(), 13)
        XCTAssertEqual(testArray.getExcessCount(), 5)
    }
    
    func testClear() {
        if (testArray.count <= 10) {
            for _ in 0...10 {
                testArray.append(Bool.random())
            }
        }
        
        testArray.clear()
        
        XCTAssertEqual(testArray.count, 0)
        XCTAssertEqual(testArray.endIndex, 1)
        XCTAssertEqual(testArray.startIndex, 0)
        XCTAssertEqual(testArray.getStorageCount(), 0)
        XCTAssertEqual(testArray.getExcessCount(), 0)
    }
    
    func testSubscriptReturnOnly() {
        testArray.clear()
        
        let limit = 100 // if change limit, change getStorageCount and getExcessCount tests as well
        var value = Bool.random()
        
        for i in 0...limit {
            testArray.append(value)
            XCTAssertEqual(testArray[i], value)
            value = Bool.random()
        }
        
        XCTAssertEqual(testArray.count, limit+1)
        XCTAssertEqual(testArray.endIndex, limit+1)
        XCTAssertEqual(testArray.startIndex, 0)
        XCTAssertEqual(testArray.getStorageCount(), 13)
        XCTAssertEqual(testArray.getExcessCount(), 5)
    }
    
    func testSubscriptSetOnly() {
        
        // size up the array
        if (testArray.count < 100) {
            var value = Bool.random()
            for i in 0 ... 100 {
                testArray.append(value)
                XCTAssertEqual(testArray[i], value)
                value = Bool.random()
                if (testArray.count >= 101) { break }
            }
        }
        
        let valArray: [Bool] = [true, false, true, false, false, true, true, false, false, true, true, false]
        
        /*for i in 0..<testArray.endIndex {
            for value in valArray {
                testArray[i] = value
                XCTAssertEqual(testArray[i], value)
            }
        }*/
        
        for i in 0..<testArray.endIndex {
            testArray[i] = true
            XCTAssertEqual(testArray[i], true)
            
            testArray[i] = true
            XCTAssertEqual(testArray[i], true)
            
            testArray[i] = false
            XCTAssertEqual(testArray[i], false)
            
            testArray[i] = true
            XCTAssertEqual(testArray[i], true)
            
            testArray[i] = false
            XCTAssertEqual(testArray[i], false)
            
            testArray[i] = false
            XCTAssertEqual(testArray[i], false)
            
            testArray[i] = true
            XCTAssertEqual(testArray[i], true)
            
            testArray[i] = true
            XCTAssertEqual(testArray[i], true)
        }
        
    }
    
}
