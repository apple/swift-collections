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
@_spi(Testing) import BitCollections

extension BitArray {
  static func _fromSequence<S: Sequence>(
    _ value: S
  ) -> BitArray where S.Element == Bool {
    BitArray(value)
  }
}

func randomBoolArray(count: Int) -> [Bool] {
  var rng = SystemRandomNumberGenerator()
  return randomBoolArray(count: count, using: &rng)
}

func randomBoolArray<R: RandomNumberGenerator>(
  count: Int, using rng: inout R
) -> [Bool] {
  let wordCount = (count + UInt.bitWidth - 1) / UInt.bitWidth
  var array: [Bool] = []
  array.reserveCapacity(wordCount * UInt.bitWidth)
  for _ in 0 ..< wordCount {
    var word: UInt = rng.next()
    for _ in 0 ..< UInt.bitWidth {
      array.append(word & 1 == 1)
      word &>>= 1
    }
  }
  array.removeLast(array.count - count)
  return array
}

final class BitArrayTests: CollectionTestCase {
  func test_empty_initializer() {
    let array = BitArray()
    expectEqual(array.count, 0)
    expectEqual(array.isEmpty, true)
    expectEqual(array.startIndex, 0)
    expectEqual(array.endIndex, 0)
    expectEqualElements(array, [])
  }
  
  func test_RandomAccessCollection() {
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    withEvery("count", in: [0, 1, 2, 13, 64, 65, 127, 128, 129]) { count in
      let reference = randomBoolArray(count: count, using: &rng)
      let value = BitArray(reference)
      print(count)
      checkBidirectionalCollection(
        value, expectedContents: reference, maxSamples: 100)
    }
  }

  func test_init_Sequence_BitArray() {
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    withEvery("count", in: [0, 1, 2, 13, 64, 65, 127, 128, 129]) { count in
      let reference = BitArray(randomBoolArray(count: count, using: &rng))
      let value = BitArray._fromSequence(reference)
      expectEqualElements(value, reference)

      let value2 = BitArray(reference)
      expectEqualElements(value2, reference)
    }
  }

  func test_init_Sequence_BitArray_SubSequence() {
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    withEvery("count", in: [0, 1, 2, 13, 64, 65, 127, 128, 129]) { count in
      let array = randomBoolArray(count: count, using: &rng)
      let ref = BitArray(array)
      withSomeRanges("range", in: 0 ..< count, maxSamples: 100) { range in
        let value = BitArray._fromSequence(ref[range])
        expectEqualElements(value, array[range])

        let value2 = BitArray(ref[range])
        expectEqualElements(value2, array[range])
      }
    }
  }

  func test_MutableCollection() {
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    withEvery("count", in: [0, 1, 2, 13, 64, 65, 127, 128, 129]) { count in
      var ref = randomBoolArray(count: count, using: &rng)
      let replacements = randomBoolArray(count: count, using: &rng)
      var value = BitArray(ref)
      withSome("i", in: 0 ..< count, maxSamples: 100) { i in
        ref[i] = replacements[i]
        value[i] = replacements[i]
        expectEqualElements(value, ref)
      }
    }
  }
  
  func test_fill() {
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    withEvery("count", in: [0, 1, 2, 13, 64, 65, 128, 129]) { count in
      withSomeRanges("range", in: 0 ..< count, maxSamples: 200) { range in
        withEvery("v", in: [false, true]) { v in
          var ref = randomBoolArray(count: count, using: &rng)
          var value = BitArray(ref)
          ref.replaceSubrange(range, with: repeatElement(v, count: range.count))
          value.fill(in: range, with: v)
          expectEqualElements(value, ref)
        }
      }
      
      var value = BitArray(randomBoolArray(count: count, using: &rng))
      value.fill(with: false)
      expectEqualElements(value, repeatElement(false, count: count))
      value.fill(with: true)
      expectEqualElements(value, repeatElement(true, count: count))
    }
  }
  
  func test_init_bitPattern() {
    expectEqualElements(
      BitArray(bitPattern: 42 as UInt8),
      [false, true, false, true, false, true, false, false])

    withSome(
      "value", in: -1_000_000 ..< 1_000_000, maxSamples: 1000
    ) { value in
      let actual = BitArray(bitPattern: value)
      var expected: [Bool] = []
      var v = value
      for _ in 0 ..< Int.bitWidth {
        expected.append(v & 1 == 1)
        v &>>= 1
      }
      expectEqualElements(actual, expected)
    }
  }
  
  func test_init_BitSet() {
    expectEqualElements(BitArray(BitSet([])), [])
    expectEqualElements(BitArray(BitSet([0])), [true])
    expectEqualElements(BitArray(BitSet([1])), [false, true])
    expectEqualElements(BitArray(BitSet([0, 1])), [true, true])
    expectEqualElements(BitArray(BitSet([1, 2])), [false, true, true])
    expectEqualElements(BitArray(BitSet([0, 2])), [true, false, true])

    expectEqualElements(
      BitArray(BitSet([1, 3, 6, 7])),
      [false, true, false, true, false, false, true, true])

    withEvery("count", in: [5, 63, 64, 65, 100, 1000]) { count in
      var reference = randomBoolArray(count: count)
      reference[reference.count - 1] = true // Fix the size of the bitset
      let bitset = BitSet(reference.indices.filter { reference[$0] })
      let actual = BitArray(bitset)
      expectEqualElements(actual, reference)
    }
  }
  
  func test_init_repeating() {
    withEvery("count", in: [0, 1, 2, 13, 63, 64, 65, 127, 128, 129, 1000]) { count in
      withEvery("v", in: [false, true]) { v in
        let value = BitArray(repeating: v, count: count)
        let reference = repeatElement(v, count: count)
        expectEqualElements(value, reference)
      }
    }
  }
  
  func test_ExpressibleByArrayLiteral() {
    let a: BitArray = []
    expectEqualElements(a, [])

    let b: BitArray = [true]
    expectEqualElements(b, [true])

    let c: BitArray = [true, false, false]
    expectEqualElements(c, [true, false, false])

    let d: BitArray = [true, false, false, false, true]
    expectEqualElements(d, [true, false, false, false, true])

    let e: BitArray = [
      true, false, false, false, true, false, false,
      true, true, false, false, true, false, false,
      false, false, false, false, true, false, false,
      true, false, true, false, true, false, false,
      true, false, false, true, true, false, false,
      true, false, false, false, false, false, false,
      false, false, true, false, true, true, false,
      true, false, false, false, true, false, true,
      true, true, false, false, true, true, true,
    ]
    expectEqualElements(e, [
      true, false, false, false, true, false, false,
      true, true, false, false, true, false, false,
      false, false, false, false, true, false, false,
      true, false, true, false, true, false, false,
      true, false, false, true, true, false, false,
      true, false, false, false, false, false, false,
      false, false, true, false, true, true, false,
      true, false, false, false, true, false, true,
      true, true, false, false, true, true, true,
    ])
  }
  
  func test_Hashable() {
    // This is a silly test, but it does exercise hashing a bit.
    let classes: [[BitArray]] = [
      [[]],
      [[false], [false]],
      [[false, false], [false, false]],
      [[false, false, true], [false, false, true]],
      [[false, false, true, false, false],
       [false, false, true, false, false]],
    ]
    checkHashable(equivalenceClasses: classes)
  }
  
  func test_replaceSubrange_Array() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSomeRanges("range", in: 0 ..< count, maxSamples: 50) { range in
        withEvery(
          "length", in: [0, 1, range.count, 2 * range.count]
        ) { length in
          var reference = randomBoolArray(count: count)
          let replacement = randomBoolArray(count: length)
          var actual = BitArray(reference)
          
          reference.replaceSubrange(range, with: replacement)
          actual.replaceSubrange(range, with: replacement)
          expectEqualElements(actual, reference)
        }
      }
    }
  }

  func test_replaceSubrange_BitArray() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSomeRanges("range", in: 0 ..< count, maxSamples: 50) { range in
        withEvery(
          "length", in: [0, 1, range.count, 2 * range.count]
        ) { length in
          var reference = randomBoolArray(count: count)
          let value = BitArray(reference)
          
          let refReplacement = randomBoolArray(count: length)
          let replacement = BitArray(refReplacement)
          
          reference.replaceSubrange(range, with: refReplacement)

          var actual = value
          actual.replaceSubrange(range, with: replacement)
          expectEqualElements(actual, reference)

          // Also check through the generic API
          func forceCollection<C: Collection>(_ v: C) where C.Element == Bool {
            var actual = value
            actual.replaceSubrange(range, with: v)
            expectEqualElements(actual, reference)
          }
          forceCollection(replacement)
        }
      }
    }
  }

  func test_replaceSubrange_BitArray_SubSequence() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSomeRanges("range", in: 0 ..< count, maxSamples: 25) { range in
        withSomeRanges(
          "replacementRange",
          in: 0 ..< count,
          maxSamples: 10
        ) { replacementRange in
          var reference = randomBoolArray(count: count)
          let value = BitArray(reference)

          let refReplacement = randomBoolArray(count: count)
          let replacement = BitArray(refReplacement)

          reference.replaceSubrange(
            range, with: refReplacement[replacementRange])

          var actual = value
          actual.replaceSubrange(range, with: replacement[replacementRange])
          expectEqualElements(actual, reference)

          // Also check through the generic API
          func forceCollection<C: Collection>(_ v: C) where C.Element == Bool {
            var actual = value
            actual.replaceSubrange(range, with: v)
            expectEqualElements(actual, reference)
          }
          forceCollection(replacement[replacementRange])
        }
      }
    }
  }
  
  func test_append() {
    withEvery("count", in: 0 ..< 129) { count in
      withEvery("v", in: [false, true]) { v in
        var reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
        reference.append(v)
        actual.append(v)
        expectEqualElements(actual, reference)
      }
    }
  }
  
  func test_append_Sequence() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSome("length", in: 0 ..< 256, maxSamples: 50) { length in
        let reference = randomBoolArray(count: count)
        let addition = randomBoolArray(count: length)
        
        let value = BitArray(reference)
        
        func check<S: Sequence>(_ addition: S) where S.Element == Bool {
          var ref = reference
          var actual = value
          
          ref.append(contentsOf: addition)
          actual.append(contentsOf: addition)
          expectEqualElements(actual, ref)
        }
        check(addition)
        check(BitArray(addition))
        check(BitArray(addition)[...])
      }
    }
  }

  func test_append_BitArray() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSome("length", in: 0 ..< 256, maxSamples: 50) { length in
        var reference = randomBoolArray(count: count)
        let addition = randomBoolArray(count: length)
        
        var actual = BitArray(reference)

        reference.append(contentsOf: addition)
        actual.append(contentsOf: BitArray(addition))
        expectEqualElements(actual, reference)
      }
    }
  }

  func test_append_BitArray_SubSequence() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSomeRanges("range", in: 0 ..< 512, maxSamples: 50) { range in
        var reference = randomBoolArray(count: count)
        let addition = randomBoolArray(count: 512)
        
        var actual = BitArray(reference)

        reference.append(contentsOf: addition[range])
        actual.append(contentsOf: BitArray(addition)[range])
        expectEqualElements(actual, reference)
      }
    }
  }
  
  func test_insert() {
    withEvery("count", in: 0 ..< 129) { count in
      withSome("i", in: 0 ..< count + 1, maxSamples: 20) { i in
        withEvery("v", in: [false, true]) { v in
          var reference = randomBoolArray(count: count)
          var actual = BitArray(reference)
          reference.insert(v, at: i)
          actual.insert(v, at: i)
          expectEqualElements(actual, reference)
        }
      }
    }
  }
  
  func test_insert_contentsOf_Sequence() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSome("length", in: 0 ..< 256, maxSamples: 5) { length in
        withSome("i", in: 0 ..< count + 1, maxSamples: 10) { i in
          let reference = randomBoolArray(count: count)
          let addition = randomBoolArray(count: length)
          
          let value = BitArray(reference)
          
          func check<C: Collection>(_ addition: C) where C.Element == Bool {
            var ref = reference
            var actual = value
            
            ref.insert(contentsOf: addition, at: i)
            actual.insert(contentsOf: addition, at: i)
            expectEqualElements(actual, ref)
          }
          check(addition)
          check(BitArray(addition))
          check(BitArray(addition)[...])
        }
      }
    }
  }

  func test_insert_contentsOf_BitArray() {
    withSome("count", in: 0 ..< 512, maxSamples: 10) { count in
      print(count)
      withSome("length", in: 0 ..< 256, maxSamples: 5) { length in
        withSome("i", in: 0 ..< count + 1, maxSamples: 10) { i in
          let reference = randomBoolArray(count: count)
          let addition = randomBoolArray(count: length)
          
          let value = BitArray(reference)
          
          var ref = reference
          var actual = value
            
          ref.insert(contentsOf: addition, at: i)
          actual.insert(contentsOf: BitArray(addition), at: i)
          expectEqualElements(actual, ref)
        }
      }
    }
  }
  
  func test_remove() {
    withSome("count", in: 0 ..< 512, maxSamples: 50) { count in
      withSome("i", in: 0 ..< count, maxSamples: 30) { i in
        var reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
          
        let v1 = reference.remove(at: i)
        let v2 = actual.remove(at: i)
        expectEqual(v2, v1)
        expectEqualElements(actual, reference)
      }
    }
  }
  
  func test_removeSubrange() {
    withSome("count", in: 0 ..< 512, maxSamples: 50) { count in
      withSomeRanges("range", in: 0 ..< count, maxSamples: 50) { range in
        var reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
        reference.removeSubrange(range)
        actual.removeSubrange(range)
        expectEqualElements(actual, reference)
      }
    }
  }

  func test_removeLast() {
    withEvery("count", in: 1 ..< 512) { count in
      var reference = randomBoolArray(count: count)
      var actual = BitArray(reference)
      let v1 = reference.removeLast()
      let v2 = actual.removeLast()
      expectEqual(v1, v2)
      expectEqualElements(actual, reference)
    }
  }
  
  func test_removeFirst() {
    withEvery("count", in: 1 ..< 512) { count in
      var reference = randomBoolArray(count: count)
      var actual = BitArray(reference)
      let v1 = reference.removeFirst()
      let v2 = actual.removeFirst()
      expectEqual(v1, v2)
      expectEqualElements(actual, reference)
    }
  }
  
  func test_removeFirst_n() {
    withSome("count", in: 0 ..< 512, maxSamples: 50) { count in
      withSome("n", in: 0 ... count, maxSamples: 30) { n in
        var reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
          
        reference.removeFirst(n)
        actual.removeFirst(n)
        expectEqualElements(actual, reference)
      }
    }
  }

  func test_removeLast_n() {
    withSome("count", in: 0 ..< 512, maxSamples: 50) { count in
      withSome("n", in: 0 ... count, maxSamples: 30) { n in
        var reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
          
        reference.removeLast(n)
        actual.removeLast(n)
        expectEqualElements(actual, reference)
      }
    }
  }
  
  func test_removeAll() {
    withSome("count", in: 0 ..< 512, maxSamples: 50) { count in
      withEvery("keep", in: [false, true]) { keep in
        let reference = randomBoolArray(count: count)
        var actual = BitArray(reference)
        actual.removeAll(keepingCapacity: keep)
        expectEqualElements(actual, [])
        if keep {
          expectGreaterThanOrEqual(actual._capacity, count)
        } else {
          expectEqual(actual._capacity, 0)
        }
      }
    }
  }
  
  func test_reserveCapacity() {
    var bits = BitArray()
    expectEqual(bits._capacity, 0)
    bits.reserveCapacity(1)
    expectGreaterThanOrEqual(bits._capacity, 1)
    bits.reserveCapacity(0)
    expectGreaterThanOrEqual(bits._capacity, 1)
    bits.reserveCapacity(100)
    expectGreaterThanOrEqual(bits._capacity, 100)
    bits.reserveCapacity(0)
    expectGreaterThanOrEqual(bits._capacity, 100)
    bits.append(contentsOf: repeatElement(true, count: 1000))
    expectGreaterThanOrEqual(bits._capacity, 1000)
    bits.reserveCapacity(2000)
    expectGreaterThanOrEqual(bits._capacity, 2000)
  }
  
  func test_bitwiseOr() {
    withSome("count", in: 0 ..< 512, maxSamples: 100) { count in
      withEvery("i", in: 0 ..< 10) { i in
        let a = randomBoolArray(count: count)
        let b = randomBoolArray(count: count)
        
        let c = BitArray(a)
        let d = BitArray(b)
        
        let expected = zip(a, b).map { $0 || $1 }
        let actual = c | d
        
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_bitwiseAnd() {
    withSome("count", in: 0 ..< 512, maxSamples: 100) { count in
      withEvery("i", in: 0 ..< 10) { i in
        let a = randomBoolArray(count: count)
        let b = randomBoolArray(count: count)
        
        let c = BitArray(a)
        let d = BitArray(b)
        
        let expected = zip(a, b).map { $0 && $1 }
        let actual = c & d
        
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_bitwiseXor() {
    withSome("count", in: 0 ..< 512, maxSamples: 100) { count in
      withEvery("i", in: 0 ..< 10) { i in
        let a = randomBoolArray(count: count)
        let b = randomBoolArray(count: count)
        
        let c = BitArray(a)
        let d = BitArray(b)
        
        let expected = zip(a, b).map { $0 != $1 }
        let actual = c ^ d
        
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_bitwiseComplement() {
    withSome("count", in: 0 ..< 512, maxSamples: 100) { count in
      withEvery("i", in: 0 ..< 10) { i in
        let a = randomBoolArray(count: count)
        
        let b = BitArray(a)

        let expected = a.map { !$0 }
        let actual = ~b
        
        expectEqualElements(actual, expected)
      }
    }
  }
  
  func test_truncateOrExtend() {
    withSome("oldCount", in: 0 ..< 512, maxSamples: 50) { oldCount in
      withSome("newCount", in: 0 ... 1024, maxSamples: 30) { newCount in
        withEvery("padding", in: [false, true]) { padding in
          let array = randomBoolArray(count: oldCount)
          
          var bits = BitArray(array)
          bits.truncateOrExtend(toCount: newCount, with: padding)
          
          let delta = newCount - oldCount
          if delta >= 0 {
            let expected = array + repeatElement(padding, count: delta)
            expectEqualElements(bits, expected)
          } else {
            expectEqualElements(bits, array[0 ..< newCount])
          }
        }
      }
    }
  }

  func test_random() {
    var rng = AllOnesRandomNumberGenerator()
    for c in [0, 10, 64, 65, 77, 1200] {
      let array = BitArray.random(count: c, using: &rng)
      expectEqual(array.count, c)
      expectEqualElements(array, repeatElement(true, count: c))
    }

    let a = Set((0..<10).map { _ in BitArray.random(count: 1000) })
    expectEqual(a.count, 10)
  }

  func test_description() {
    let a: BitArray = []
    expectEqual("\(a)", "0")

    let b: BitArray = [true, false, true, true, true]
    expectEqual("\(b)", "10111")

    let c: BitArray = [false, false, false, false, true, true, true, false]
    expectEqual("\(c)", "00001110")
  }

  func test_debugDescription() {
    let a: BitArray = []
    expectEqual("\(String(reflecting: a))", "BitArray(0)")

    let b: BitArray = [true, false, true, true, true]
    expectEqual("\(String(reflecting: b))", "BitArray(10111)")

    let c: BitArray = [false, false, false, false, true, true, true, false]
    expectEqual("\(String(reflecting: c))", "BitArray(00001110)")
  }

  func test_mirror() {
    func check<T>(_ v: T) -> String {
      var str = ""
      dump(v, to: &str)
      return str
    }

    expectEqual(check(BitArray()), """
      - 0 elements

      """)

    expectEqual(check([true, false, false] as BitArray), """
      ▿ 3 elements
        - true
        - false
        - false

      """)
  }

}
