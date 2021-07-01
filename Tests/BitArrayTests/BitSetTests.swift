//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/27/21.
//

import XCTest
import CollectionsTestSupport
@testable import BitArrayModule

final class BitSetTest: CollectionTestCase {
    
    let limit = 100
    
    func testAppend() {
        var testBitSet = BitSet()
        var num1: UInt8 = 0
        var num2: UInt8 = 0
        var num3: UInt8 = 0
        var num4: UInt8 = 0
        var valDeterminer: Bool = Bool.random()
        
        for i in 0..<8 {
            if (valDeterminer) {
                testBitSet.append(i)
                num1 += (1 << (i%8))
            }
            
            valDeterminer = Bool.random()
        }
        
        XCTAssertEqual(num1, testBitSet.storage.storage[0])
        
        for i in 8..<16 {
            if (valDeterminer) {
                testBitSet.append(i)
                num2 += (1 << (i%8))
            }
            valDeterminer = Bool.random()
        }
        
        XCTAssertEqual(num1, testBitSet.storage.storage[0])
        XCTAssertEqual(num2, testBitSet.storage.storage[1])
        
        for i in 16..<24 {
            if (valDeterminer) {
                testBitSet.append(i)
                num3 += (1 << (i%8))
            }
            valDeterminer = Bool.random()
        }
        
        XCTAssertEqual(num1, testBitSet.storage.storage[0])
        XCTAssertEqual(num2, testBitSet.storage.storage[1])
        XCTAssertEqual(num3, testBitSet.storage.storage[2])
        
        for i in 24..<32 {
            if (valDeterminer) {
                testBitSet.append(i)
                num4 += (1 << (i%8))
            }
            valDeterminer = Bool.random()
        }
        
        XCTAssertEqual(num1, testBitSet.storage.storage[0])
        XCTAssertEqual(num2, testBitSet.storage.storage[1])
        XCTAssertEqual(num3, testBitSet.storage.storage[2])
        XCTAssertEqual(num4, testBitSet.storage.storage[3])
    }
    
}
