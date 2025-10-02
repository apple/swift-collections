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
  func utf8Distance(from i: Index, to j: Index) -> Int {
    j.utf8Offset - i.utf8Offset
  }

  subscript(utf8 i: Index) -> UInt8 {
    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")
    return span[i.utf8Offset]
  }
}

#endif // compiler(>=6.2) && !$Embedded
