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

#if compiler(>=6.2) && !$Embedded

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  func utf16AlignIndex(_ i: Index) -> Index {
    var i = i

    if !i.isUTF16TrailingSurrogate {
      i = scalarIndex(roundingDown: i)
    }

    return i
  }

  func utf16Index(after i: Index) -> Index {
    let i = utf16AlignIndex(i)
    let len = self[scalar: i].utf8.count

    // Check for non-BMP scalars and mark the index as a trailing surrogate if
    // needed.
    if len == 4, !i.isUTF16TrailingSurrogate {
      return i.nextUTF16Trailing
    }

    return i.offset(by: len).scalarAligned
  }

  func utf16Index(before i: Index) -> Index {
    // If we have a trailing surrogate, then we just strip the bit to indicate
    // we're looking at the leading surrogate.
    if i.isUTF16TrailingSurrogate {
      return i.stripUTF16Trailing.scalarAligned
    }

    let i = utf16AlignIndex(i)
    var len = 1

    while UTF8.isContinuation(self[utf8: i.offset(by: -len)]) {
      len += 1
    }

    if len == 4 {
      return i.offset(by: -len).nextUTF16Trailing
    }

    return i.offset(by: -len).scalarAligned
  }

  func utf16Index(_ i: Index, offsetBy n: Int) -> Index {
    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")

    var i = utf16AlignIndex(i)

    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        i = utf16Index(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        i = utf16Index(before: i)
      }
    }

    return i
  }

  func utf16Index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
    guard limit <= endIndex else {
      return utf16Index(i, offsetBy: n)
    }

    precondition((startIndex ... endIndex).contains(i), "Index out of bounds")

    var i = utf16AlignIndex(i)
    let limit = utf16AlignIndex(limit)

    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        if i == limit {
          return nil
        }

        i = utf16Index(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        if i == limit {
          return nil
        }

        i = utf16Index(before: i)
      }
    }

    return i
  }

  func utf16Distance(from i: Index, to j: Index) -> Int {
    guard i != j else {
      return 0
    }

    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")
    precondition((startIndex ... endIndex).contains(j), "Index out of bounds")

    if j > i {
      return _distance(from: i, to: j)
    } else {
      return -_distance(from: j, to: i)
    }
  }

  func _distance(from i: Index, to j: Index) -> Int {
    let i = utf16AlignIndex(i)
    let j = utf16AlignIndex(j)

    var utf16Count = 0
    let utf8Offset = j.utf8Offset - i.utf8Offset
    var readPtr = _bytes.baseAddress.unsafelyUnwrapped + i.utf8Offset
    let endPtr = readPtr + utf8Offset

    while readPtr < endPtr {
      let byte = readPtr.pointee

      if !UTF8.isContinuation(byte) {
        break
      }

      readPtr += 1
    }

    while readPtr < endPtr {
      let byte = readPtr.pointee
      let len = utf8ScalarLength(byte)

      if readPtr + len <= endPtr {
        utf16Count += len == 4 ? 2 : 1
      }

      readPtr += len
    }

    switch (i.isUTF16TrailingSurrogate, j.isUTF16TrailingSurrogate) {
    case (false, false):
      return utf16Count
    case (false, true):
      return utf16Count + 1
    case (true, false):
      return utf16Count - 1
    case (true, true):
      return utf16Count
    }
  }

  subscript(utf16 i: Index) -> UInt16 {
    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")

    let s = self[scalar: i]

    if i.isUTF16TrailingSurrogate {
      return s.utf16[1]
    } else {
      return s.utf16[0]
    }
  }
}

#endif // compiler(>=6.2) && !$Embedded
