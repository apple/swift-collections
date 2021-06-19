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
    
    func testAppend() {
        var testArray = BitArray()
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
        XCTAssertEqual(testArray.getStorageCount(), 0)
        XCTAssertEqual(testArray.getExcessCount(), 0)
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
        XCTAssertEqual(testArray.getStorageCount(), 13)
        XCTAssertEqual(testArray.getExcessCount(), 5)
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
            testArray[i] = setVal
            XCTAssertEqual(testArray[i], setVal)
            XCTAssertNotEqual(testArray[i], !setVal)
            
            testArray[i] = !setVal
            XCTAssertEqual(testArray[i], !setVal)
            XCTAssertNotEqual(testArray[i], setVal)
        }
        
    }
    
}
