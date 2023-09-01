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

extension UnsafeMutableBufferPointer {
  // Doesn't clear the shifted bytes.
  func shiftRight(startIndex: Int, endIndex: Int, by: Int) {
    var idx = endIndex
    while idx >= startIndex {
      self[idx + by] = self[idx]
      idx -= 1
    }
  }

  func shiftLeft(startIndex: Int, endIndex: Int, by: Int) {
    var idx = startIndex
    while idx <= endIndex {
      self[idx - by] = self[idx]
      idx += 1
    }
  }
}
