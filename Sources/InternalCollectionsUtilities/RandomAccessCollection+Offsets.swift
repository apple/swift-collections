//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension RandomAccessCollection {
  @_alwaysEmitIntoClient @inline(__always)
  package func _index(at offset: Int) -> Index {
    index(startIndex, offsetBy: offset)
  }

  @_alwaysEmitIntoClient @inline(__always)
  package func _offset(of index: Index) -> Int {
    distance(from: startIndex, to: index)
  }

  @_alwaysEmitIntoClient @inline(__always)
  package subscript(_offset offset: Int) -> Element {
    self[_index(at: offset)]
  }
}
