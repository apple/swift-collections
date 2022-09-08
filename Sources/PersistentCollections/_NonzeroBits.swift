//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  internal func _nonzeroBits() -> _NonzeroBits<Self> {
    return _NonzeroBits(from: self)
  }

  internal func _zeroBits() -> _NonzeroBits<Self> {
    return _NonzeroBits(from: ~self)
  }
}

internal struct _NonzeroBits<_Bitmap: FixedWidthInteger>
: Sequence, IteratorProtocol, CustomStringConvertible
{
  var bitmap: _Bitmap

  init(from bitmap: _Bitmap) {
    self.bitmap = bitmap
  }

  public mutating func next() -> Int? {
    guard bitmap != 0 else { return nil }

    let index = bitmap.trailingZeroBitCount
    bitmap ^= 1 << index

    return index
  }

  public var description: String {
    "[\(self.map { $0.description }.joined(separator: ", "))]"
  }
}
