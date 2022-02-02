//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitArray {
  public mutating func fill(with value: Bool = true) {
    fill(in: Range(uncheckedBounds: (0, count)), with: value)
  }

  public mutating func fill(in range: Range<Int>, with value: Bool = true) {
    _update { handle in
      if value {
        handle.fill(in: range)
      } else {
        handle.clear(in: range)
      }
    }
  }
}
