//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import _CollectionsTestSupport
@testable import BitCollections

final class BitSetTest: CollectionTestCase {
  func test_empty_initializer() {
    let set = BitSet()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_array_literal_initializer() {
    let set0: BitSet = []
    expectEqual(set0.count, 0)
    expectTrue(set0.isEmpty)
    expectEqualElements(set0, [])

    let set1: BitSet = [0, 3, 50, 10, 21, 11, 3, 100, 300, 20]
    expectEqual(set1.count, 9)
    expectEqualElements(set1, [0, 3, 10, 11, 20, 21, 50, 100, 300])
  }

  func test_sequence_initializer() {
    withEvery("i", in: 0 ..< 100) { i in
      var rng = RepeatableRandomNumberGenerator(seed: i)
      let input = (0 ..< 1000).shuffled(using: &rng).prefix(100)
      let expected = input.sorted()
      let actual = BitSet(input)
      expectEqual(actual.count, expected.count)
      expectEqualElements(actual, expected)

      let actual2 = BitSet(actual)
      expectEqualElements(actual2, actual)
    }
  }

  func test_range_initializer() {
    withEveryRange("range", in: 0 ..< 200) { range in
      let set = BitSet(range)
      expectEqualElements(set, range)
    }
  }

  func test_collection_strides() {
    withEvery("stride", in: [1, 2, 3, 5, 7, 8, 11, 13, 63, 79, 300]) { stride in
      withEvery("count", in: [0, 1, 2, 5, 10, 20, 25]) { count in
        let input = Swift.stride(from: 0, to: stride * count, by: stride)
        let expected = Array(input)
        let actual = BitSet(input)
        checkBidirectionalCollection(actual, expectedContents: expected)
      }
    }
  }

  func withInterestingSets(
    _ label: String,
    maximum: Int,
    file: StaticString = #file,
    line: UInt = #line,
    run body: (Set<Int>) -> Void
  ) {
    let context = TestContext.current
    func yield(_ desc: String, _ set: Set<Int>) {
      let entry = context.push(
        "\(label): \(desc)", file: file, line: line)
      defer { context.pop(entry) }
      body(set)
    }

    yield("empty", [])
    yield("full", Set(0 ..< maximum))
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    let c = 10

    func randomSelection(_ desc: String, count: Int) {
      // 1% filled
      for i in 0 ..< c {
        let set = Set((0 ..< maximum)
                        .shuffled(using: &rng)
                        .prefix(count))
        yield("\(desc)/\(i)", set)
      }
    }
    if maximum > 100 {
      randomSelection("1%", count: maximum / 100)
      randomSelection("9%", count: maximum / 100)
    }
    randomSelection("50%", count: maximum / 2)

    let a = maximum / 3
    let b = 2 * maximum / 3
    yield("0..<a", Set(0 ..< a))
    yield("a..<b", Set(a ..< b))
    yield("b..<max", Set(b ..< maximum))
    yield("0..<b", Set(0 ..< b))
    yield("a..<max", Set(a ..< maximum))
  }

  func test_firstIndexOf_lastIndexOf() {
    let max = 1000
    withInterestingSets("input", maximum: max) { input in
      let bits = BitSet(input)
      withEvery("value", in: 0 ..< max) { value in
        if input.contains(value) {
          expectNotNil(bits.firstIndex(of: value)) { i in
            expectEqual(bits[i], value)
            expectNotNil(bits.lastIndex(of: value)) { j in
              expectEqual(i, j)
            }
          }
        } else {
          expectNil(bits.firstIndex(of: value))
          expectNil(bits.lastIndex(of: value))
        }
      }
    }
  }

  func test_hashable() {
    // This is a silly test, but it does exercise hashing a bit.
    let classes: [[BitSet]] = [
      [[]],
      [[1]],
      [[2]],
      [[1, 5, 10], [10, 5, 1]],
      [[1, 5, 11], [11, 5, 1]],
      [[1, 5, 100], [100, 5, 1]],
    ]
    checkHashable(equivalenceClasses: classes)
  }

  func test_contains() {
    withInterestingSets("input", maximum: 1000) { input in
      let bitset = BitSet(input)
      withEvery("value", in: 0 ..< 1000) { value in
        expectEqual(bitset.contains(value), input.contains(value))
      }
      expectFalse(bitset.contains(5000))
    }
  }

  func test_contains_Int32() {
    withInterestingSets("input", maximum: 1000) { input in
      let bitset = BitSet(input)
      withEvery("value", in: 0 ..< 1000) { value in
        expectEqual(bitset.contains(Int32(value)), input.contains(value))
      }
      expectFalse(bitset.contains(5000 as Int32))
    }
  }

  func checkInsert<F: FixedWidthInteger>(for type: F.Type, count: Int) {
    withEvery("seed", in: 0 ..< 10) { seed in
      var rng = RepeatableRandomNumberGenerator(seed: seed)
      var actual: BitSet = []
      var expected: Set<Int> = []
      let input = (0 ..< count).shuffled(using: &rng)
      withEvery("i", in: input.indices) { i in
        let (i1, m1) = actual.insert(F(input[i]))
        expected.insert(input[i])
        expectTrue(i1)
        expectEqual(m1, F(input[i]))
        if i % 25 == 0 {
          expectEqual(Array(actual), expected.sorted())
        }
        let (i2, m2) = actual.insert(F(input[i]))
        expectFalse(i2)
        expectEqual(m2, m1)
      }
      expectEqual(Array(actual), expected.sorted())
    }
  }

  func test_insert_Int() {
    checkInsert(for: Int.self, count: 100)
  }
  func test_insert_Int32() {
    checkInsert(for: Int32.self, count: 100)
  }
  func test_insert_UInt16() {
    checkInsert(for: UInt16.self, count: 100)
  }

  func checkUpdate<F: FixedWidthInteger>(for type: F.Type, count: Int) {
    withEvery("seed", in: 0 ..< 10) { seed in
      var rng = RepeatableRandomNumberGenerator(seed: seed)
      var actual: BitSet = []
      var expected: Set<Int> = []
      let input = (0 ..< count).shuffled(using: &rng)
      withEvery("i", in: input.indices) { i in
        let old = actual.update(with: F(input[i]))
        expected.update(with: input[i])
        expectEqual(old, F(input[i]))
        if i % 25 == 0 {
          expectEqual(Array(actual), expected.sorted())
        }
        expectNil(actual.update(with: F(input[i])))
      }
      expectEqual(Array(actual), expected.sorted())
    }
  }

  func test_update_Int() {
    checkUpdate(for: Int.self, count: 100)
  }
  func test_update_Int32() {
    checkUpdate(for: Int32.self, count: 100)
  }
  func test_update_UInt16() {
    checkUpdate(for: UInt16.self, count: 100)
  }

  func test_remove_Int() {
    func checkRemove<F: FixedWidthInteger>(for type: F.Type, count: Int) {
      context.withTrace("\(type)") {
        withEvery("seed", in: 0 ..< 10) { seed in
          var rng = RepeatableRandomNumberGenerator(seed: seed)
          var actual = BitSet(0 ..< count)
          var expected = Set<Int>(0 ..< count)
          let input = (0 ..< count).shuffled(using: &rng)
          withEvery("i", in: input.indices) { i in
            let v = input[i]
            let old = actual.remove(F(v))
            expected.remove(v)
            expectEqual(old, F(v))
            if i % 25 == 0 {
              expectEqual(Array(actual), expected.sorted())
            }
            expectNil(actual.remove(F(v)))
          }
          expectEqual(Array(actual), expected.sorted())
        }
      }
    }

    checkRemove(for: Int.self, count: 100)
    checkRemove(for: Int32.self, count: 100)
    checkRemove(for: UInt16.self, count: 100)
  }

  func test_union_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.union(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_union_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        let c = BitSet(a)
        let actual = c.union(b)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_formUnion_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formUnion(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formUnion_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        var c = BitSet(a)
        c.formUnion(b)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_intersection_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.intersection(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_intersection_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        let c = BitSet(a)
        let actual = c.intersection(b)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_formIntersection_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formIntersection(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formIntersection_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        var c = BitSet(a)
        c.formIntersection(b)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_symmetricDifference_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.symmetricDifference(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_symmetricDifference_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        let c = BitSet(a)
        let actual = c.symmetricDifference(b)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_formSymmetricDifference_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formSymmetricDifference(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formSymmetricDifference_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        var c = BitSet(a)
        c.formSymmetricDifference(b)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_subtracting_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.subtracting(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_subtracting_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        let c = BitSet(a)
        let actual = c.subtracting(b)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_subtract_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.subtract(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_subtract_Set() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        var c = BitSet(a)
        c.subtract(b)
        expectEqualElements(c, expected)
      }
    }
  }

  #if false
  typealias WORD = BitArray.WORD
  let sizes = _getSizes(WORD.bitWidth)
  
  func testBitArrayInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      let bitArray = BitArray(layout)
      let modifiedBitArrayAsBitSetWouldModify = _dropExcessFalses(forArr: bitArray)
      let bitSet = BitSet(bitArray)
      var expectedResult: [Int] = []
      
      for index in 0..<layout.endIndex {
        if (layout[index]) {
          expectedResult.append(index)
        }
      }
      
      let expectedStartIndex = (expectedResult.count == 0) ? 0 : expectedResult[0]
      let expectedEndIndex = (expectedResult.count == 0) ? 0 : modifiedBitArrayAsBitSetWouldModify.endIndex
      
      expectEqual(Array(bitSet), expectedResult)
      expectEqual(bitSet.count, expectedResult.count)
      expectEqual(bitSet.startIndex, BitSet.Index(bitArrayIndex: expectedStartIndex))
      expectEqual(bitSet.endIndex, BitSet.Index(bitArrayIndex: expectedEndIndex))
    }
    
  }
  
  
  func testSequenceInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolArray in
      let bitArray = BitArray(boolArray)
      let expectedBitSet = BitSet(bitArray)
      var sequence: [Int] = []
      
      for index in 0..<boolArray.endIndex {
        if (boolArray[index]) {
          sequence.append(index)
        }
      }
      
      let bitSet = BitSet(sequence)
      
      expectEqual(bitSet.storage.storage, expectedBitSet.storage.storage)
      expectEqual(bitSet.count, expectedBitSet.count)
      expectEqual(bitSet.count, sequence.count)
      expectEqual(bitSet.startIndex, expectedBitSet.startIndex)
      expectEqual(bitSet.endIndex, expectedBitSet.endIndex)
    }
  }
  
  private func _dropExcessFalses(forArr: BitArray) -> BitArray{
    // remove excess bytes
    var modifiedBitArray = forArr
    while(modifiedBitArray.storage.count != 0 && modifiedBitArray.storage[modifiedBitArray.storage.endIndex-1] == 0) {
      modifiedBitArray.storage.removeLast()
    }
    
    modifiedBitArray.excess = 0
    
    return modifiedBitArray
  }
  
  func testExpressibleByArrayLiteralAndArrayLiteralInit() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSetIntArray", ofLayout: layout) { bitSetIntArray in
        let bitArray = BitArray(layout)
        let bitSetFromBitArray = BitSet(bitArray)
        let bitSetFromIntArray = BitSet(bitSetIntArray)
        
        XCTAssertEqual(bitSetFromBitArray, bitSetFromIntArray) // used instead of expectEqual because expectEqual was requesting more context
        expectEqual(Array(bitSetFromBitArray), bitSetIntArray)
        expectEqual(Array(bitSetFromIntArray), bitSetIntArray)
        XCTAssertTrue(bitArray.startIndex <= bitArray.endIndex)
      }
    }
    
    // manual tests
    let testBitSet1: BitSet = []
    expectEqual(Array(testBitSet1), [])
    expectEqual(testBitSet1.storage.storage, [])
    expectEqual(testBitSet1.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet1.count, 0)
    expectEqual(testBitSet1.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet1.endIndex, BitSet.Index(bitArrayIndex: 0))
    XCTAssertTrue(testBitSet1.startIndex <= testBitSet1.endIndex)
    
    let testBitSet2: BitSet = [0]
    expectEqual(Array(testBitSet2), [0])
    expectEqual(testBitSet2.storage.storage, [1])
    expectEqual(testBitSet2.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet2.count, 1)
    expectEqual(testBitSet2.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet2.endIndex, BitSet.Index(bitArrayIndex: testBitSet2._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet2.startIndex < testBitSet2.endIndex)
    
    let testBitSet3: BitSet = [0, 1, 2, 3]
    expectEqual(Array(testBitSet3), [0, 1, 2, 3])
    expectEqual(testBitSet3.storage.storage, [15])
    expectEqual(testBitSet3.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet3.count, 4)
    expectEqual(testBitSet3.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet3.endIndex, BitSet.Index(bitArrayIndex: testBitSet3._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet3.startIndex < testBitSet3.endIndex)
    
    let testBitSet4: BitSet = [0, 1, 3, 5, 11]
    expectEqual(Array(testBitSet4), [0, 1, 3, 5, 11])
    // expectEqual(testBitSet4.storage.storage, [43, 8]) // only for BitArray.WORD = UInt8
    expectEqual(testBitSet4.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet4.count, 5)
    expectEqual(testBitSet4.startIndex, BitSet.Index(bitArrayIndex: 0))
    expectEqual(testBitSet4.endIndex, BitSet.Index(bitArrayIndex: testBitSet4._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet4.startIndex < testBitSet4.endIndex)
    
    let testBitSet5: BitSet = [1, 11, 99]
    expectEqual(Array(testBitSet5), [1, 11, 99])
    // expectEqual(testBitSet5.storage.storage, [2, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8]) // only for BitArray.WORD = UInt8
    expectEqual(testBitSet5.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet5.count, 3)
    expectEqual(testBitSet5.startIndex, BitSet.Index(bitArrayIndex: 1))
    expectEqual(testBitSet5.endIndex, BitSet.Index(bitArrayIndex: testBitSet5._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet5.startIndex < testBitSet5.endIndex)
    
    // testing duplicate, unordered values, as well as major gaps between set elements
    let testBitSet6: BitSet = [9, 11, 12, 15, 17, 32, 45, 46, 45, 47, 14, 10, 99]
    expectEqual(Array(testBitSet6), [9, 10, 11, 12, 14, 15, 17, 32, 45, 46, 47, 99])
    // expectEqual(testBitSet6.storage.storage, [0, 222, 2, 0, 1, 224, 0, 0, 0, 0, 0, 0, 8]) // only for BitArray.WORD = UInt8
    expectEqual(testBitSet6.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet6.count, 12)
    expectEqual(testBitSet6.startIndex, BitSet.Index(bitArrayIndex: 9))
    expectEqual(testBitSet6.endIndex, BitSet.Index(bitArrayIndex: testBitSet6._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet6.startIndex < testBitSet6.endIndex)
    
    // only for BitArray.WORD = UInt8
    /*var expectedArrayFor7: [WORD] = [8, 220, 2, 0, 1, 224, 0, 0, 0, 0, 0, 0, 8]
    expectedArrayFor7 += Array(repeating: 0, count: 402)
    expectedArrayFor7.append(16)*/
    
    let testBitSet7: BitSet = [3, 11, 12, 12, 15, 17, 32, 45, 46, 45, 47, 14, 10, 99, 3324]
    expectEqual(Array(testBitSet7), [3, 10, 11, 12, 14, 15, 17, 32, 45, 46, 47, 99, 3324])
    // expectEqual(testBitSet7.storage.storage, expectedArrayFor7) // only for BitArray.WORD = UInt8
    expectEqual(testBitSet7.storage.excess, WORD(testBitSet1.count%(WORD.bitWidth)))
    expectEqual(testBitSet7.count, 13)
    expectEqual(testBitSet7.startIndex, BitSet.Index(bitArrayIndex: 3))
    expectEqual(testBitSet7.endIndex, BitSet.Index(bitArrayIndex: testBitSet7._getExpectedEndIndex()))
    XCTAssertTrue(testBitSet7.startIndex < testBitSet7.endIndex)
  }
  
  func testInsertAndContains() {
    var values: [Int] = [0]
    for value in 1...2*WORD.bitWidth+13 {
      values.append(value)
    }
    values.append(3320)
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSet", ofLayout: layout) { bitSetIntArray in
        var bitSet = BitSet(bitSetIntArray)
        var intArrayCopy = bitSetIntArray
        
        for value in values {
          if (!intArrayCopy.contains(value)) {
            intArrayCopy.append(value)
            expectFalse(bitSet.contains(value))
          }
          bitSet.insert(value)
          expectEqual(Array(bitSet), intArrayCopy.sorted())
          expectTrue(bitSet.contains(value))
        }
        
        expectFalse(bitSet.contains(999999))
        
      }
    }
    
    //test with empty initializer
    var bitSet = BitSet()
    var layout: [Int] = []
    
    for value in values {
      if (!layout.contains(value)) {
        layout.append(value)
        expectFalse(bitSet.contains(value))
      }
      bitSet.insert(value)
      expectEqual(Array(bitSet), layout.sorted())
      expectTrue(bitSet.contains(value))
    }
    
    expectFalse(bitSet.contains(999999))
    
  }
  
  func testForceInsertAndContainsAndIsEmpty() {
    var values: [Int] = [0]
    for value in 1...2*WORD.bitWidth+13 {
      values.append(value)
    }
    values.append(3320)
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSet", ofLayout: layout) { bitSetIntArray in
        var bitSet = BitSet(bitSetIntArray)
        var intArrayCopy = bitSetIntArray
        
        if (intArrayCopy.isEmpty) {
          expectTrue(bitSet.isEmpty)
        } else {
          expectFalse(bitSet.isEmpty)
        }
        
        for value in values {
          if (!intArrayCopy.contains(value)) {
            intArrayCopy.append(value)
            expectFalse(bitSet.contains(value))
          }
          bitSet._forceInsert(value)
          expectEqual(Array(bitSet), intArrayCopy.sorted())
          expectTrue(bitSet.contains(value))
        }
        
        expectFalse(bitSet.contains(999999))
        
      }
    }
    
    //test with empty initializer
    var bitSet = BitSet()
    var layout: [Int] = []
    
    expectTrue(bitSet.isEmpty)
    
    for value in values {
      if (!layout.contains(value)) {
        layout.append(value)
        expectFalse(bitSet.contains(value))
      }
      bitSet._forceInsert(value)
      expectEqual(Array(bitSet), layout.sorted())
      expectTrue(bitSet.contains(value))
      expectFalse(bitSet.isEmpty)
    }
    
    expectFalse(bitSet.contains(999999))
    
  }
  
  func testRemove() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { layout in
      withTheirBitSetLayout("bitSetIntLayout", ofLayout: layout) { bitSetIntLayout in
        var bitSet = BitSet(bitSetIntLayout)
        var intArrayCopy = bitSetIntLayout
        
        // do some beyond the scope
        for value in (4*WORD.bitWidth)...(7*WORD.bitWidth) {
          expectFalse(bitSet.remove(value))
        }
        
        // trying removing one more than the last value
        if (bitSetIntLayout.count != 0) {
          expectFalse(bitSet.remove(bitSetIntLayout[bitSetIntLayout.endIndex-1]+1))
        }
        
        for _ in layout {
          
          guard let removing = intArrayCopy.randomElement() else {
            continue
          }
          
          expectTrue(bitSet.contains(removing))
          intArrayCopy.removeAll(where: {$0 == removing})
          expectTrue(bitSet.remove(removing))
          expectFalse(bitSet.contains(removing))
          expectEqual(Array(bitSet), intArrayCopy)
        }
        
        expectTrue(bitSet.isEmpty)
      }
    }
  }
  
  func testUnion() {
    withSomeUsefulBoolArrays("boolArray1", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolLayout1 in
      withTheirBitSetLayout("bitSetLayout1", ofLayout: boolLayout1) { bitSetLayout1 in
        withSomeUsefulBoolArrays("boolArray2", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolArray2 in
          withTheirBitSetLayout("bitSetLayout2", ofLayout: boolArray2) { bitSetLayout2 in
            var bitSet1 = BitSet(bitSetLayout1)
            let bitSet2 = BitSet(bitSetLayout2)
            let intArrayCopy1 = bitSetLayout1
            let intArrayCopy2 = bitSetLayout2
            
            var expectedResult = intArrayCopy1
            for value in intArrayCopy2 {
              if (!intArrayCopy1.contains(value)) {
                expectedResult.append(value)
              }
            }
            
            expectedResult = expectedResult.sorted()
            
            let nonFormUnion = bitSet1.union(bitSet2)
            bitSet1.formUnion(bitSet2)
            
            expectEqual(bitSet1, nonFormUnion)
            expectEqual(Array(bitSet1), expectedResult)
            expectEqual(Array(nonFormUnion), expectedResult)
          }
        }
      }
    }
  }
  
  func testIntersection() {
    withSomeUsefulBoolArrays("boolArray1", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolLayout1 in
      withTheirBitSetLayout("bitSetLayout1", ofLayout: boolLayout1) { bitSetLayout1 in
        withSomeUsefulBoolArrays("boolArray2", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolArray2 in
          withTheirBitSetLayout("bitSetLayout2", ofLayout: boolArray2) { bitSetLayout2 in
            var bitSet1 = BitSet(bitSetLayout1)
            let bitSet2 = BitSet(bitSetLayout2)
            let intArrayCopy1 = bitSetLayout1
            let intArrayCopy2 = bitSetLayout2
            
            var expectedResult: [Int] = []
            
            for value in intArrayCopy1 {
              if (intArrayCopy2.contains(value)) {
                expectedResult.append(value)
              }
            }
            
            expectedResult = expectedResult.sorted()
            
            let nonFormIntersection = bitSet1.intersection(bitSet2)
            bitSet1.formIntersection(bitSet2)
            
            expectEqual(bitSet1, nonFormIntersection)
            expectEqual(Array(bitSet1), expectedResult)
            expectEqual(Array(nonFormIntersection), expectedResult)
          }
        }
      }
    }
  }
  
  func testSymmetricDifference() {
    withSomeUsefulBoolArrays("boolArray1", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolLayout1 in
      withTheirBitSetLayout("bitSetLayout1", ofLayout: boolLayout1) { bitSetLayout1 in
        withSomeUsefulBoolArrays("boolArray2", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolArray2 in
          withTheirBitSetLayout("bitSetLayout2", ofLayout: boolArray2) { bitSetLayout2 in
            var bitSet1 = BitSet(bitSetLayout1)
            let bitSet2 = BitSet(bitSetLayout2)
            let intArrayCopy1 = bitSetLayout1
            let intArrayCopy2 = bitSetLayout2
            
            var expectedResult: [Int] = []
            
            for value in intArrayCopy1 {
              if (!intArrayCopy2.contains(value)) {
                expectedResult.append(value)
              }
            }
            
            for value in intArrayCopy2 {
              if (!intArrayCopy1.contains(value)) {
                expectedResult.append(value)
              }
            }
            
            expectedResult = expectedResult.sorted()
            
            let nonFormSymmetricDifference = bitSet1.symmetricDifference(bitSet2)
            bitSet1.formSymmetricDifference(bitSet2)
            
            expectEqual(bitSet1, nonFormSymmetricDifference)
            expectEqual(Array(bitSet1), expectedResult)
            expectEqual(Array(nonFormSymmetricDifference), expectedResult)
          }
        }
      }
    }
  }
  
  func testIndexBefore() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { bitArrayLayout in
      withTheirBitSetLayout("bitSet", ofLayout: bitArrayLayout) { bitSetLayout in
        let bitSet = BitSet(bitSetLayout)
        var layoutCopy = bitSetLayout
        layoutCopy.reverse()
        
        var secondValueIndex = 0
        for value in bitSet.reversed() {
          expectEqual(value, layoutCopy[secondValueIndex])
          secondValueIndex += 1
        }
      }
    }
  }
  
  func testInsertOffsetBy() {
    withSomeUsefulBoolArrays("boolArray", ofSizes: sizes, ofUnitBitWidth: WORD.bitWidth) { boolLayout in
      withTheirBitSetLayout("bitSetLayout", ofLayout: boolLayout) { bitSetLayout in
        let bitSet = BitSet(bitSetLayout)
        if (bitSetLayout.count != 0) {
          let offset = Int.random(in: 0..<bitSet.count)
          
          // test positive offset from startIndex
          expectEqual(bitSet.index(bitSet.startIndex, offsetBy: offset).bitArrayIndex,
                      bitSetLayout[bitSetLayout.index(bitSetLayout.startIndex, offsetBy: offset)])
          
          // test negative offset from endIndex
          if (offset == 0) {
            expectEqual(bitSet.index(bitSet.endIndex, offsetBy: -offset).bitArrayIndex,
                        Int(bitSet.storage.storage.count*WORD.bitWidth))
          } else {
            expectEqual(bitSet.index(bitSet.endIndex, offsetBy: -offset).bitArrayIndex,
                        bitSetLayout[bitSetLayout.count-offset])
          }
          
          // test positive and negative from middle index if applicable -- depends on above testing passing
          if (bitSet.count >= 3) {
            let distanceFromStart = Int.random(in: 1..<bitSet.count-1)
            let distanceFromEnd = (bitSet.count-1) - distanceFromStart
            let fromIndex = bitSet.index(bitSet.startIndex, offsetBy: distanceFromStart)
            
            let negativeOffset = -(Int.random(in: 1...distanceFromStart))
            let positiveOffset = Int.random(in: 1...distanceFromEnd)
            
            expectEqual(bitSet.index(fromIndex, offsetBy: negativeOffset).bitArrayIndex, bitSetLayout[bitSetLayout.index(distanceFromStart, offsetBy: negativeOffset)])
            expectEqual(bitSet.index(fromIndex, offsetBy: positiveOffset).bitArrayIndex, bitSetLayout[bitSetLayout.index(distanceFromStart, offsetBy: positiveOffset)])
          }
        }
      }
    }
  }
    func testc() {
        let a: BitSet = []
        var b = a
        b.insert(100)
        b.remove(100)
        //expectEqual(a,b)
        let bitArray: BitArray = [ false, true]
        print(bitArray.firstIndex(of: true))
    }
  #endif
}

#if false
extension BitSet {
  typealias WORD = BitArray.WORD
  fileprivate func _getExpectedEndIndex() -> Int {
    self.storage.storage.count * WORD.bitWidth
  }
}
#endif
