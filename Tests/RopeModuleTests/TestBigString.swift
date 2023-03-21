//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8)
import _CollectionsTestSupport
import _RopeModule
import XCTest

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
class TestBigString: CollectionTestCase {
  override var isAvailable: Bool { isRunningOnSwiftStdlib5_8 }

  override class func setUp() {
    // Turn off output buffering.
    setbuf(stdout, nil)
    setbuf(stderr, nil)
    super.setUp()
  }

  override func setUp() {
    print("Global seed: \(globalSeed)")
  }

  func test_capacity() {
    let min = BigString._minimumCapacity
    let max = BigString._maximumCapacity

    XCTAssertLessThanOrEqual(min, max)
#if !DEBUG // Debug builds have smaller nodes
    // We want big strings to hold at least as many UTF-8 code units as a regular String.
    XCTAssertGreaterThanOrEqual(min, 1 << 48)
#endif
  }

  func test_empty() {
    let s = BigString()
    s._invariantCheck()
    XCTAssertEqual(s.count, 0)
    XCTAssertEqual(s.unicodeScalars.count, 0)
    XCTAssertEqual(s.utf16.count, 0)
    XCTAssertEqual(s.utf8.count, 0)
    XCTAssertTrue(s.isEmpty)
    XCTAssertEqual(s.startIndex, s.endIndex)
    XCTAssertEqual(s.utf8.distance(from: s.startIndex, to: s.endIndex), 0)
    XCTAssertEqual(s.utf16.distance(from: s.startIndex, to: s.endIndex), 0)
    XCTAssertEqual(s.unicodeScalars.distance(from: s.startIndex, to: s.endIndex), 0)
    XCTAssertEqual(s.distance(from: s.startIndex, to: s.endIndex), 0)
  }

  func test_Equatable() {
    let a: BigString = "Cafe\u{301}"
    let b: BigString = "Café"
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a.unicodeScalars, b.unicodeScalars)
    XCTAssertNotEqual(a.utf8, b.utf8)
    XCTAssertNotEqual(a.utf16, b.utf16)
  }

  func test_descriptions() {
    let s: BigString = "Café"
    XCTAssertEqual(s.description, "Café")
    XCTAssertEqual(s.unicodeScalars.description, "Café")
    XCTAssertEqual(s.utf8.description, "<43 61 66 C3 A9>")
    XCTAssertEqual(s.utf16.description, "<0043 0061 0066 00E9>")
  }

  func test_string_conversion() {
    let big = BigString(sampleString)

    big._invariantCheck()
    XCTAssertEqual(big.count, sampleString.count)
    XCTAssertEqual(big.unicodeScalars.count, sampleString.unicodeScalars.count)
    XCTAssertEqual(big.utf16.count, sampleString.utf16.count)
    XCTAssertEqual(big.utf8.count, sampleString.utf8.count)

    let flat = String(big)
    XCTAssertEqual(flat, sampleString)
  }

  @discardableResult
  func checkCharacterIndices(
    _ flat: String,
    _ big: BigString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [BigString.Index]) {
    let indices1 = Array(flat.indices) + [flat.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.index(after: $0)
      }
    )

    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)

    let c = min(indices1.count, indices2.count)

    for i in 0 ..< c {
      let i1 = indices1[i]
      let i2 = indices2[i]
      guard i1 < flat.endIndex, i2 < big.endIndex else { continue }
      let c1 = flat[i1]
      let c2 = big[i2]
      XCTAssertEqual(c1, c2, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    for i in 0 ..< c {
      let i1 = indices1[i]
      let i2 = indices2[i]
      let d1 = flat.utf8.distance(from: flat.startIndex, to: i1)
      let d2 = big.utf8.distance(from: big.startIndex, to: i2)
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    return (indices1, indices2)
  }

  @discardableResult
  func checkScalarIndices(
    _ flat: String,
    _ big: BigString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [BigString.Index]) {
    let indices1 = Array(flat.unicodeScalars.indices) + [flat.unicodeScalars.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.unicodeScalars.index(after: $0)
      }
    )

    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)

    let c = min(indices1.count, indices2.count)

    for i in 0 ..< c {
      let i1 = indices1[i]
      let i2 = indices2[i]
      guard i1 < flat.endIndex, i2 < big.endIndex else { continue }
      let c1 = flat.unicodeScalars[i1]
      let c2 = big.unicodeScalars[i2]
      XCTAssertEqual(c1, c2, "i: \(i), i1: \(i1), i2: \(i2)", file: file, line: line)
    }

    for i in 0 ..< min(indices1.count, indices2.count) {
      let i1 = indices1[i]
      let i2 = indices2[i]
      let d1 = flat.utf8.distance(from: flat.startIndex, to: i1)
      let d2 = big.utf8.distance(from: big.startIndex, to: i2)
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    return (indices1, indices2)
  }

  @discardableResult
  func checkUTF8Indices(
    _ flat: String,
    _ big: BigString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [BigString.Index]) {
    let indices1 = Array(flat.utf8.indices) + [flat.utf8.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.utf8.index(after: $0)
      }
    )

    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)

    let c = min(indices1.count, indices2.count)

    for i in 0 ..< c {
      let i1 = indices1[i]
      let i2 = indices2[i]
      guard i1 < flat.endIndex, i2 < big.endIndex else { continue }
      let c1 = flat.utf8[i1]
      let c2 = big.utf8[i2]
      XCTAssertEqual(c1, c2, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    for i in 0 ..< min(indices1.count, indices2.count) {
      let i1 = indices1[i]
      let i2 = indices2[i]
      let d1 = flat.utf8.distance(from: flat.startIndex, to: i1)
      let d2 = big.utf8.distance(from: big.startIndex, to: i2)
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    return (indices1, indices2)
  }

  @discardableResult
  func checkUTF16Indices(
    _ flat: String,
    _ big: BigString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [BigString.Index]) {
    let indices1 = Array(flat.utf16.indices) + [flat.utf16.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.utf16.index(after: $0)
      }
    )

    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)

    let c = min(indices1.count, indices2.count)

    for i in 0 ..< c {
      let i1 = indices1[i]
      let i2 = indices2[i]
      guard i1 < flat.endIndex, i2 < big.endIndex else { continue }
      let c1 = flat.utf16[i1]
      let c2 = big.utf16[i2]
      XCTAssertEqual(c1, c2, "i: \(i), i1: \(i1), i2: \(i2)", file: file, line: line)
    }

    for i in 0 ..< min(indices1.count, indices2.count) {
      let i1 = indices1[i]
      let i2 = indices2[i]
      let d1 = flat.utf8.distance(from: flat.startIndex, to: i1)
      let d2 = big.utf8.distance(from: big.startIndex, to: i2)
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(i1._description), i2: \(i2)", file: file, line: line)
    }

    return (indices1, indices2)
  }

  func test_iterator_character() {
    let small: BigString = "Cafe\u{301} 👩‍👩‍👧"
    var it = small.makeIterator()
    XCTAssertEqual(it.next(), "C")
    XCTAssertEqual(it.next(), "a")
    XCTAssertEqual(it.next(), "f")
    XCTAssertEqual(it.next(), "e\u{301}")
    XCTAssertEqual(it.next(), " ")
    XCTAssertEqual(it.next(), "👩‍👩‍👧")
    XCTAssertNil(it.next())

    let flat = sampleString
    let big = BigString(flat)

    let c1 = Array(flat)
    let c2 = Array(big)
    XCTAssertEqual(c1, c2)
  }

  func test_iterator_scalar() {
    let flat = sampleString
    let big = BigString(flat)

    let c1 = Array(flat.unicodeScalars)
    let c2 = Array(big.unicodeScalars)
    XCTAssertEqual(c1, c2)
  }

  func test_iterator_utf8() {
    let flat = sampleString
    let big = BigString(flat)

    let c1 = Array(flat.utf8)
    let c2 = Array(big.utf8)
    XCTAssertEqual(c1, c2)
  }

  func test_iterator_utf16() {
    let flat = sampleString
    let big = BigString(flat)

    let c1 = Array(flat.utf16)
    let c2 = Array(big.utf16)
    XCTAssertEqual(c1, c2)
  }

  func test_indices_character() {
    let flat = sampleString
    let big = BigString(flat)

    let (indices1, indices2) = checkCharacterIndices(flat, big)

    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 5, seed: 0) {
      for j in randomStride(from: i, to: c, by: 5, seed: i) {
        let i1 = indices1[i]
        let j1 = indices1[j]
        let a = String(sampleString[i1 ..< j1])

        let i2 = indices2[i]
        let j2 = big.index(i2, offsetBy: j - i)
        let b = String(big[i2 ..< j2])
        XCTAssertEqual(b, a)
      }
    }
  }

  func test_indices_scalar() {
    let flat = sampleString
    let big = BigString(flat)

    let (indices1, indices2) = checkScalarIndices(flat, big)

    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 20, seed: 0) {
      for j in randomStride(from: i, to: c, by: 20, seed: i) {
        let i2 = indices2[i]
        let j2 = big.unicodeScalars.index(i2, offsetBy: j - i)
        XCTAssertEqual(j2, indices2[j])
      }
    }
  }

  func test_indices_utf16() {
    let flat = sampleString
    let big = BigString(flat)

    let (indices1, indices2) = checkUTF16Indices(flat, big)

    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 20, seed: 0) {
      for j in randomStride(from: i, to: c, by: 20, seed: i) {
        let i2 = indices2[i]
        let j2 = big.utf16.index(i2, offsetBy: j - i)
        XCTAssertEqual(j2, indices2[j])
      }
    }
  }

  func test_indices_utf8() {
    let flat = sampleString
    let big = BigString(flat)

    let (indices1, indices2) = checkUTF8Indices(flat, big)

    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 40, seed: 0) {
      for j in randomStride(from: i, to: c, by: 40, seed: i) {
        let i2 = indices2[i]
        let j2 = big.utf8.index(i2, offsetBy: j - i)
        XCTAssertEqual(j2, indices2[j])
      }
    }
  }

  func test_append_string() {
    let flat = sampleString
    let ref = BigString(flat)
    for stride in [1, 2, 4, 8, 16, 32, 64, 128, 250, 1000, 10000, 20000] {
      var big: BigString = ""
      var i = flat.startIndex
      while i < flat.endIndex {
        let j = flat.unicodeScalars.index(i, offsetBy: stride, limitedBy: flat.endIndex) ?? flat.endIndex
        let next = String(flat[i ..< j])
        big.append(contentsOf: next)
        //big._invariantCheck()
        //XCTAssertEqual(String(big)[...], s[..<j])
        i = j
      }
      checkUTF8Indices(flat, big)
      checkUTF8Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
      XCTAssertEqual(big, ref)
    }
  }

  func test_append_big() {
    let flat = sampleString
    let ref = BigString(flat)
    for stride in [16, 32, 64, 128, 250, 1000, 10000, 20000] {
      var big: BigString = ""
      var i = flat.startIndex
      while i < flat.endIndex {
        let j = flat.unicodeScalars.index(i, offsetBy: stride, limitedBy: flat.endIndex) ?? flat.endIndex
        let s = flat[i ..< j]
        let piece = BigString(s)
        piece._invariantCheck()
        XCTAssertEqual(piece.utf8.count, s.utf8.count)
        big.append(contentsOf: piece)
        big._invariantCheck()
        i = j
      }
      checkUTF8Indices(flat, big)
      checkUTF8Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
      XCTAssertEqual(big, ref)
    }
  }

  func pieces(of str: String, by stride: Int) -> [(i: Int, str: String)] {
    var pieces: [(i: Int, str: String)] = []
    var c = 0
    var i = str.startIndex
    while i < str.endIndex {
      let j = str.unicodeScalars.index(i, offsetBy: stride, limitedBy: str.endIndex) ?? str.endIndex
      let next = String(str[i ..< j])
      pieces.append((c, next))
      c += 1
      i = j
    }
    return pieces
  }

  func test_insert_string() {
    let flat = sampleString
    let ref = BigString(flat)
    for stride in [1, 2, 4, 8, 16, 32, 64, 128, 250, 1000, 10000, 20000] {
      print("Stride: \(stride)")
      var pieces = pieces(of: flat, by: stride)
      var rng = RepeatableRandomNumberGenerator(seed: 0)
      pieces.shuffle(using: &rng)

      var big: BigString = ""
      var smol = ""
      for i in pieces.indices {
        let piece = pieces[i]
        let utf8Offset = pieces[..<i].reduce(into: 0) {
          guard $1.i < piece.i else { return }
          $0 += $1.str.utf8.count
        }

        let j = smol.utf8.index(smol.startIndex, offsetBy: utf8Offset)
        smol.insert(contentsOf: piece.str, at: j)

        let index = big.utf8.index(big.startIndex, offsetBy: utf8Offset)
        //print("\(i)/\(pieces.count): i: \(piece.i), start: \(index), str: \(piece.str._properDebugDescription)")
        big.insert(contentsOf: piece.str, at: index)

        if i % 20 == 0 {
          big._invariantCheck()

          XCTAssertEqual(String(big), smol)
          checkUTF8Indices(smol, big)
          checkUTF16Indices(smol, big)
          checkScalarIndices(smol, big)
          checkCharacterIndices(smol, big)
        }
      }
      big._invariantCheck()
      XCTAssertEqual(big, ref)
      checkUTF8Indices(flat, big)
      checkUTF16Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
    }
  }

  func test_insert_big() {
    let flat = sampleString
    let ref = BigString(flat)
    for stride in [64, 128, 250, 256, 257, 500, 512, 513, 1000, 2000, 10000, 20000] {
      print("Stride: \(stride)")
      var pieces = pieces(of: flat, by: stride)
      var rng = RepeatableRandomNumberGenerator(seed: 0)
      pieces.shuffle(using: &rng)

      var big: BigString = ""
      var smol = ""
      for i in pieces.indices {
        let piece = pieces[i]
        let utf8Offset = pieces[..<i].reduce(into: 0) {
          guard $1.i < piece.i else { return }
          $0 += $1.str.utf8.count
        }

        let j = smol.utf8.index(smol.startIndex, offsetBy: utf8Offset)
        smol.insert(contentsOf: piece.str, at: j)

        let index = big.utf8.index(big.startIndex, offsetBy: utf8Offset)
        //print("\(i)/\(pieces.count): i: \(piece.i), start: \(index), str: \(piece.str._properDebugDescription)")

        let p = BigString(piece.str)
        big.insert(contentsOf: p, at: index)

        if i % 20 == 0 {
          big._invariantCheck()
          XCTAssertEqual(String(big), smol)
          checkUTF8Indices(smol, big)
          checkUTF16Indices(smol, big)
          checkScalarIndices(smol, big)
          checkCharacterIndices(smol, big)
        }
      }
      big._invariantCheck()
      XCTAssertEqual(big, ref)
      checkUTF8Indices(flat, big)
      checkUTF16Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
    }
  }

  func test_replaceSubrange_string() {
    let input = sampleString
    let ref = BigString(input)
    for stride in [1, 2, 4, 8, 16, 32, 64, 128, 250, 1000, 10000, 20000] {
      print("Stride: \(stride)")
      var pieces = pieces(of: input, by: stride)
      var rng = RepeatableRandomNumberGenerator(seed: 0)
      pieces.shuffle(using: &rng)

      let placeholder: Character = " " // To make this super slow, replace with "\u{200D}"
      var big = BigString(repeating: placeholder, count: pieces.count)
      var smol = String(repeating: placeholder, count: pieces.count)
      for i in pieces.indices {
        let piece = pieces[i]
        let utf8Offset = pieces[..<i].reduce(into: piece.i * placeholder.utf8.count) {
          guard $1.i < piece.i else { return }
          $0 += $1.str.utf8.count - placeholder.utf8.count
        }

        let j1 = smol.utf8.index(smol.startIndex, offsetBy: utf8Offset)
        let j2 = smol.utf8.index(j1, offsetBy: placeholder.utf8.count)
        smol.replaceSubrange(j1 ..< j2, with: piece.str)

        let k1 = big.utf8.index(big.startIndex, offsetBy: utf8Offset)
        let k2 = big.utf8.index(k1, offsetBy: placeholder.utf8.count)
        //print("\(i)/\(pieces.count): i: \(piece.i), range: \(k1 ..< k2), str: \(piece.str.debugDescription)")

        big.replaceSubrange(k1 ..< k2, with: piece.str)

        if i % 20 == 0 {
          big._invariantCheck()
          XCTAssertEqual(String(big), smol)
          checkUTF8Indices(smol, big)
          checkUTF16Indices(smol, big)
          checkScalarIndices(smol, big)
          checkCharacterIndices(smol, big)
        }
      }
      big._invariantCheck()
      XCTAssertEqual(big, ref)
      checkUTF8Indices(input, big)
      checkUTF16Indices(input, big)
      checkScalarIndices(input, big)
      checkCharacterIndices(input, big)
    }
  }

  func test_init_from_substring() {
    let flat = sampleString
    let big = BigString(flat)

    let (indices1, indices2) = checkCharacterIndices(flat, big)

    for i in randomStride(from: 0, to: indices1.count, by: 1000, seed: 0) {
      let a1 = indices1[i]
      let a2 = indices2[i]
      for j in randomStride(from: i, to: indices1.count, by: 1000, seed: i) {
        let b1 = indices1[j]
        let b2 = indices2[j]

        let expected = String(flat[a1 ..< b1])
        let actual = BigString(big[a2 ..< b2])
        actual._invariantCheck()
        XCTAssertEqual(String(actual), expected)
        checkUTF8Indices(expected, actual)
        checkUTF16Indices(expected, actual)
        checkScalarIndices(expected, actual)
        checkCharacterIndices(expected, actual)
      }
    }
  }
}
#endif
