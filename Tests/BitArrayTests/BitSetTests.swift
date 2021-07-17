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
        var count = 0
        
        for i in 0..<8 {
            if (valDeterminer) {
                testBitSet.append(i)
                num1 += (1 << (i%8))
                count += 1
            }
            
            XCTAssertEqual(testBitSet.count, count)
            valDeterminer = Bool.random()
        }
        
        XCTAssertEqual(num1, testBitSet.storage.storage[0])
        
        for i in 8..<16 {
            if (valDeterminer) {
                testBitSet.append(i)
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
                testBitSet.append(i)
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
                testBitSet.append(i)
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
                sampleBitSet.append(i)
            } else {
                sampleBitSet2.append(i)
            }
            valDeterminer = Bool.random()
        }
        
        //sampleBitSet.formUnion(with: sampleBitSet2)
        
        XCTAssertEqual(sampleBitSet.storage.storage, [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 15])
        
        var sampleBitSet3 = BitSet()
        var sampleBitSet4 = BitSet()
        
        for i in 0..<50 {
            if (valDeterminer) {
                sampleBitSet3.append(i)
            } else {
                sampleBitSet4.append(i)
            }
            valDeterminer = Bool.random()
        }
        
        for i in 50..<100 {
            sampleBitSet4.append(i)
        }
        
        //sampleBitSet3.formUnion(with: sampleBitSet4)
        
        XCTAssertEqual(sampleBitSet3.storage.storage, [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 15])
    }
    
    func testIntArrayView() {
        var testBitSet = BitSet()
        var resultArray: [Int] = []
        var valDeterminer: Bool = Bool.random()
        
        for i in 0..<100 {
            if (valDeterminer) {
                testBitSet.append(i)
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
            bitSet1.append(i)
            bitSet2.append(i)
        }
        
        //let result1 = bitSet1.cartesianProduct(with: bitSet2)
        //let result2 = bitSet2.cartesianProduct(with: bitSet1)
        
    }
    
    
}
