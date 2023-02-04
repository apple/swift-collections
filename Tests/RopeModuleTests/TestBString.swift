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

#if DEBUG
@testable import RopeModule
import XCTest

class TestBString: XCTestCase {
  override class func setUp() {
    // Turn off output buffering.
    setbuf(stdout, nil)
    setbuf(stderr, nil)
    super.setUp()
  }
  
  override func setUp() {
    print("Global seed: \(globalSeed)")
  }
  
  func test_empty() {
    let s = _BString()
    s.invariantCheck()
    XCTAssertEqual(s.characterCount, 0)
    XCTAssertEqual(s.unicodeScalarCount, 0)
    XCTAssertEqual(s.utf16Count, 0)
    XCTAssertEqual(s.utf8Count, 0)
    XCTAssertTrue(s.isEmpty)
    XCTAssertEqual(s.startIndex, s.endIndex)
    XCTAssertEqual(s.startIndex._utf8Offset, 0)
  }
  
  func test_string_conversion() {
    let big = _BString(sampleString)
    
    big.invariantCheck()
    XCTAssertEqual(big.characterCount, sampleString.count)
    XCTAssertEqual(big.unicodeScalarCount, sampleString.unicodeScalars.count)
    XCTAssertEqual(big.utf16Count, sampleString.utf16.count)
    XCTAssertEqual(big.utf8Count, sampleString.utf8.count)
    
    let flat = String(_from: big)
    XCTAssertEqual(flat, sampleString)
  }
  
  @discardableResult
  func checkCharacterIndices(
    _ flat: String,
    _ big: _BString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [_BString.Index]) {
    // Check iterators
    var it1 = flat.makeIterator()
    var it2 = big.makeCharacterIterator()
    while true {
      let a = it1.next()
      let b = it2.next()
      guard a == b else {
        XCTAssertEqual(a, b)
        break
      }
      if a == nil { break }
    }

    // Check indices
    let indices1 = Array(flat.indices) + [flat.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.characterIndex(after: $0)
      }
    )
    
    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)
    for i in 0 ..< min(indices1.count, indices2.count) {
      let d1 = flat.utf8.distance(from: flat.startIndex, to: indices1[i])
      let d2 = big.utf8Distance(from: big.startIndex, to: indices2[i])
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(indices1[i]), i2: \(indices2[i])", file: file, line: line)
    }
    return (indices1, indices2)
  }
  
  @discardableResult
  func checkScalarIndices(
    _ flat: String,
    _ big: _BString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [_BString.Index]) {
    // Check iterators
    var it1 = flat.unicodeScalars.makeIterator()
    var it2 = big.makeUnicodeScalarIterator()
    while true {
      let a = it1.next()
      let b = it2.next()
      guard a == b else {
        XCTAssertEqual(a, b)
        break
      }
      if a == nil { break }
    }

    // Check indices
    let indices1 = Array(flat.unicodeScalars.indices) + [flat.unicodeScalars.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.unicodeScalarIndex(after: $0)
      }
    )
    
    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)
    for i in 0 ..< min(indices1.count, indices2.count) {
      let d1 = flat.utf8.distance(from: flat.startIndex, to: indices1[i])
      let d2 = big.utf8Distance(from: big.startIndex, to: indices2[i])
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(indices1[i]), i2: \(indices2[i])", file: file, line: line)
    }
    return (indices1, indices2)
  }
  
  @discardableResult
  func checkUTF8Indices(
    _ flat: String,
    _ big: _BString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [_BString.Index]) {
    // Check iterators
    var it1 = flat.utf8.makeIterator()
    var it2 = big.makeUTF8Iterator()
    while true {
      let a = it1.next()
      let b = it2.next()
      guard a == b else {
        XCTAssertEqual(a, b)
        break
      }
      if a == nil { break }
    }

    // Check indices
    let indices1 = Array(flat.utf8.indices) + [flat.utf8.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.utf8Index(after: $0)
      }
    )
    
    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)
    for i in 0 ..< min(indices1.count, indices2.count) {
      let d1 = flat.utf8.distance(from: flat.startIndex, to: indices1[i])
      let d2 = big.utf8Distance(from: big.startIndex, to: indices2[i])
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(indices1[i]), i2: \(indices2[i])", file: file, line: line)
    }
    return (indices1, indices2)
  }
  
  @discardableResult
  func checkUTF16Indices(
    _ flat: String,
    _ big: _BString,
    file: StaticString = #file, line: UInt = #line
  ) -> (flat: [String.Index], big: [_BString.Index]) {
    // Check iterators
    var it1 = flat.utf16.makeIterator()
    var it2 = big.makeUTF16Iterator()
    while true {
      let a = it1.next()
      let b = it2.next()
      guard a == b else {
        XCTAssertEqual(a, b)
        break
      }
      if a == nil { break }
    }

    // Check indices
    let indices1 = Array(flat.utf16.indices) + [flat.utf16.endIndex]
    let indices2 = Array(
      sequence(first: big.startIndex) {
        $0 == big.endIndex ? nil : big.utf16Index(after: $0)
      }
    )
    
    XCTAssertEqual(indices2.count, indices1.count, file: file, line: line)
    for i in 0 ..< min(indices1.count, indices2.count) {
      let d1 = flat.utf8.distance(from: flat.startIndex, to: indices1[i])
      let d2 = big.utf8Distance(from: big.startIndex, to: indices2[i])
      XCTAssertEqual(d2, d1, "i: \(i), i1: \(indices1[i]._description), i2: \(indices2[i])", file: file, line: line)
    }
    return (indices1, indices2)
  }
  
  func test_indices_character() {
    let flat = sampleString
    let big = _BString(flat)
    
    let (indices1, indices2) = checkCharacterIndices(flat, big)
    
    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 5, seed: 0) {
      for j in randomStride(from: i, to: c, by: 5, seed: i) {
        let i1 = indices1[i]
        let j1 = indices1[j]
        let a = String(sampleString[i1 ..< j1])
        
        let i2 = indices2[i]
        let j2 = big.characterIndex(i2, offsetBy: j - i)
        let b = String(_from: big, in: i2 ..< j2)
        XCTAssertEqual(b, a)
      }
    }
  }
  
  func test_indices_scalar() {
    let flat = sampleString
    let big = _BString(flat)
    
    let (indices1, indices2) = checkScalarIndices(flat, big)
    
    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 20, seed: 0) {
      for j in randomStride(from: i, to: c, by: 20, seed: i) {
        let a = String(sampleString.unicodeScalars[indices1[i] ..< indices1[j]])
        
        let i2 = indices2[i]
        let j2 = big.unicodeScalarIndex(i2, offsetBy: j - i)
        let b = String(_from: big, in: i2 ..< j2)
        XCTAssertEqual(b, a)
      }
    }
  }
  
  func test_indices_utf16() {
    let flat = sampleString
    let big = _BString(flat)
    
    let (indices1, indices2) = checkUTF16Indices(flat, big)
    
    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 20, seed: 0) {
      for j in randomStride(from: i, to: c, by: 20, seed: i) {
        let a = String(sampleString.unicodeScalars[indices1[i] ..< indices1[j]])
        
        let i2 = indices2[i]
        let j2 = big.utf16Index(i2, offsetBy: j - i)
        let b = String(_from: big, in: i2 ..< j2)
        XCTAssertEqual(b, a)
      }
    }
  }
  
  func test_indices_utf8() {
    let flat = sampleString
    let big = _BString(flat)
    
    let (indices1, indices2) = checkUTF8Indices(flat, big)
    
    let c = min(indices1.count, indices2.count)
    for i in randomStride(from: 0, to: c, by: 40, seed: 0) {
      for j in randomStride(from: i, to: c, by: 40, seed: i) {
        let a = String(sampleString.unicodeScalars[indices1[i] ..< indices1[j]])
        
        let i2 = indices2[i]
        let j2 = big.utf8Index(i2, offsetBy: j - i)
        let b = String(_from: big, in: i2 ..< j2)
        XCTAssertEqual(b, a)
      }
    }
  }
  
  func test_append_string() {
    let flat = sampleString
    let ref = _BString(flat)
    for stride in [1, 2, 4, 8, 16, 32, 64, 128, 250, 1000, 10000, 20000] {
      var big: _BString = ""
      var i = flat.startIndex
      while i < flat.endIndex {
        let j = flat.unicodeScalars.index(i, offsetBy: stride, limitedBy: flat.endIndex) ?? flat.endIndex
        let next = String(flat[i ..< j])
        big.append(contentsOf: next)
        //big.invariantCheck()
        //XCTAssertEqual(String(big)[...], s[..<j])
        i = j
      }
      checkUTF8Indices(flat, big)
      checkUTF8Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
      XCTAssertTrue(big.utf8IsEqual(to: ref))
    }
  }
  
  func test_append_big() {
    let flat = sampleString
    let ref = _BString(flat)
    for stride in [16, 32, 64, 128, 250, 1000, 10000, 20000] {
      var big: _BString = ""
      var i = flat.startIndex
      while i < flat.endIndex {
        let j = flat.unicodeScalars.index(i, offsetBy: stride, limitedBy: flat.endIndex) ?? flat.endIndex
        let s = flat[i ..< j]
        let piece = _BString(s)
        piece.invariantCheck()
        XCTAssertEqual(piece.utf8Count, s.utf8.count)
        big.append(contentsOf: piece)
        big.invariantCheck()
        i = j
      }
      checkUTF8Indices(flat, big)
      checkUTF8Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
      XCTAssertTrue(big.utf8IsEqual(to: ref))
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
    let ref = _BString(flat)
    for stride in [1, 2, 4, 8, 16, 32, 64, 128, 250, 1000, 10000, 20000] {
      print("Stride: \(stride)")
      var pieces = pieces(of: flat, by: stride)
      var rng = RepeatableRandomNumberGenerator(seed: 0)
      pieces.shuffle(using: &rng)
      
      var big: _BString = ""
      var smol = ""
      for i in pieces.indices {
        let piece = pieces[i]
        let utf8Offset = pieces[..<i].reduce(into: 0) {
          guard $1.i < piece.i else { return }
          $0 += $1.str.utf8.count
        }
        
        let j = smol._utf8Index(at: utf8Offset)
        smol.insert(contentsOf: piece.str, at: j)
        
        let index = big.utf8Index(big.startIndex, offsetBy: utf8Offset)
        //print("\(i)/\(pieces.count): i: \(piece.i), start: \(index), str: \(piece.str._properDebugDescription)")
        big.insert(contentsOf: piece.str, at: index)
        
        if i % 20 == 0 {
          big.invariantCheck()
          
          XCTAssertEqual(String(_from: big), smol)
          checkUTF8Indices(smol, big)
          checkUTF16Indices(smol, big)
          checkScalarIndices(smol, big)
          checkCharacterIndices(smol, big)
        }
      }
      big.invariantCheck()
      XCTAssertTrue(big.utf8IsEqual(to: ref))
      checkUTF8Indices(flat, big)
      checkUTF16Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
    }
  }
  
  func test_insert_big() {
    let flat = sampleString
    let ref = _BString(flat)
    for stride in [64, 128, 250, 256, 257, 500, 512, 513, 1000, 2000, 10000, 20000] {
      print("Stride: \(stride)")
      var pieces = pieces(of: flat, by: stride)
      var rng = RepeatableRandomNumberGenerator(seed: 0)
      pieces.shuffle(using: &rng)
      
      var big: _BString = ""
      var smol = ""
      for i in pieces.indices {
        let piece = pieces[i]
        let utf8Offset = pieces[..<i].reduce(into: 0) {
          guard $1.i < piece.i else { return }
          $0 += $1.str.utf8.count
        }
        
        let j = smol._utf8Index(at: utf8Offset)
        smol.insert(contentsOf: piece.str, at: j)
        
        let index = big.utf8Index(big.startIndex, offsetBy: utf8Offset)
        //print("\(i)/\(pieces.count): i: \(piece.i), start: \(index), str: \(piece.str._properDebugDescription)")
        
        let p = _BString(piece.str)
        big.insert(contentsOf: p, at: index)
        
        if i % 20 == 0 {
          big.invariantCheck()
          XCTAssertEqual(String(_from: big), smol)
          checkUTF8Indices(smol, big)
          checkUTF16Indices(smol, big)
          checkScalarIndices(smol, big)
          checkCharacterIndices(smol, big)
        }
      }
      big.invariantCheck()
      XCTAssertTrue(big.utf8IsEqual(to: ref))
      checkUTF8Indices(flat, big)
      checkUTF16Indices(flat, big)
      checkScalarIndices(flat, big)
      checkCharacterIndices(flat, big)
    }
  }
}
#endif
