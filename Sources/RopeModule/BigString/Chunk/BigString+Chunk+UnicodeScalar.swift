//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  func utf8ScalarLength(_ byte: UInt8) -> Int {
    if UTF8.isASCII(byte) {
      return 1
    }
    
    return (~byte).leadingZeroBitCount
  }
  
  func scalarIndex(roundingDown i: Index) -> Index {
    if i.isKnownScalarAligned || i.utf8Offset == 0 {
      return i.scalarAligned
    }
    
    if i == endIndex {
      return endIndex
    }
    
    var i = i
    
    while UTF8.isContinuation(_bytes[i.utf8Offset]) {
      i = i.offset(by: -1)
    }
    
    return i.scalarAligned
  }
  
  func scalarIndex(after i: Index) -> Index {
    var i = scalarIndex(roundingDown: i)

    i = i.offset(by: 1)
    
    while i < endIndex, UTF8.isContinuation(_bytes[i.utf8Offset]) {
      i = i.offset(by: 1)
    }
    
    return i.scalarAligned
  }
  
  func scalarIndex(before i: Index) -> Index {
    var i = scalarIndex(roundingDown: i)
    
    i = i.offset(by: -1)
    
    while i > startIndex, UTF8.isContinuation(_bytes[i.utf8Offset]) {
      i = i.offset(by: -1)
    }
    
    return i.scalarAligned
  }
  
  func scalarIndex(_ i: Index, offsetBy n: Int) -> Index {
    var i = scalarIndex(roundingDown: i)
    
    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        i = scalarIndex(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        i = scalarIndex(before: i)
      }
    }
    
    return i
  }
  
  func scalarDistance(from start: Index, to end: Index) -> Int {
    let start = scalarIndex(roundingDown: start)
    let end = scalarIndex(roundingDown: end)
    
    var i = start
    var count = 0
    
    if i < end {
      while i < end {
        count += 1
        i = scalarIndex(after: i)
      }
    } else if i > end {
      while i > end {
        count -= 1
        i = scalarIndex(before: i)
      }
    }
    
    return count
  }
  
  subscript(scalar i: Index) -> Unicode.Scalar {
    precondition((startIndex..<endIndex).contains(i), "Index out of bounds")
    
    let i = scalarIndex(roundingDown: i)
    
    let x = _bytes[i.utf8Offset]
    
    if UTF8.isASCII(x) {
      return Unicode.Scalar(x)
    }
    
    switch utf8ScalarLength(x) {
    case 2:
      let x = UInt32(x & 0b0001_1111)
      let cont = UInt32(_bytes[i.offset(by: 1).utf8Offset] & 0b0011_1111)
      let c = (x &<< 6) | cont
      return Unicode.Scalar(c).unsafelyUnwrapped
    case 3:
      let x = UInt32(x & 0b0000_1111)
      let cont1 = UInt32(_bytes[i.offset(by: 1).utf8Offset] & 0b0011_1111)
      let cont2 = UInt32(_bytes[i.offset(by: 2).utf8Offset] & 0b0011_1111)
      let c = (x &<< 12) | (cont1 &<< 6) | cont2
      return Unicode.Scalar(c).unsafelyUnwrapped
    case 4:
      let x = UInt32(x & 0b0000_0111)
      let cont1 = UInt32(_bytes[i.offset(by: 1).utf8Offset] & 0b0011_1111)
      let cont2 = UInt32(_bytes[i.offset(by: 2).utf8Offset] & 0b0011_1111)
      let cont3 = UInt32(_bytes[i.offset(by: 3).utf8Offset] & 0b0011_1111)
      let c = (x &<< 18) | (cont1 &<< 12) | (cont2 &<< 6) | cont3
      return Unicode.Scalar(c).unsafelyUnwrapped
    default:
      fatalError()
    }
  }
}
