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

extension BitSet {
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    var words = [_Word](repeating: .empty, count: _storage.count)
    let count = try words.withUnsafeMutableBufferPointer { buffer in
      var target = _UnsafeHandle(words: buffer, count: 0, mutable: true)
      for i in self {
        guard try isIncluded(i) else { continue }
        target.insert(UInt(i))
      }
      return target.count
    }
    return BitSet(_words: words, count: count)
  }
}
