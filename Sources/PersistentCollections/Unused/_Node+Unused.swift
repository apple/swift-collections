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

#if false
extension PersistentDictionary._Node {
  final func count(upTo mask: Int) -> Int {
    let bitpos = _bitposFrom(mask)

    let dataIndex = _indexFrom(dataMap, mask, bitpos)
    let trieIndex = _indexFrom(trieMap, mask, bitpos)

    let buffer = UnsafeMutableBufferPointer(
      start: trieBaseAddress, count: header.trieCount)
    let children = buffer.prefix(upTo: trieIndex).map { $0.count }.reduce(0, +)
    let count = dataIndex + children

    assert(count == _counts.prefix(upTo: mask).reduce(0, +))
    return count
  }
}
#endif
