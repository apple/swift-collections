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

import _CollectionsUtilities

extension _Node {
  @usableFromInline
  internal func dump(
    firstPrefix: String = "", restPrefix: String = "", limit: Int = Int.max
  ) {
    read {
      $0.dump(
        firstPrefix: firstPrefix,
        restPrefix: restPrefix,
        extra: "count: \(count), ",
        limit: limit)
    }
  }
}

extension _Node.Storage {
  @usableFromInline
  final internal func dump() {
    UnsafeHandle.read(self) { $0.dump() }
  }
}

extension _Node.UnsafeHandle {
  @usableFromInline
  internal func dump(
    firstPrefix: String = "",
    restPrefix: String = "",
    extra: String = "",
    limit: Int = Int.max
  ) {
    print("""
      \(firstPrefix)\(isCollisionNode ? "CollisionNode" : "Node")(\
      at: \(_addressString(for: _header)), \
      \(extra)\
      byteCapacity: \(byteCapacity), \
      freeBytes: \(bytesFree))
      """)
    guard limit > 0 else { return }
    if isCollisionNode {
      let items = self._items
      for offset in items.indices {
        let item = items[offset]
        let hash = _Hash(item.key).description
        let itemStr = "hash: \(hash), key: \(item.key), value: \(item.value)"
        print("\(restPrefix)  \(offset): \(itemStr)")
      }
    } else {
      var itemOffset = 0
      var childOffset = 0
      for b in 0 ..< UInt(_Bitmap.capacity) {
        let bucket = _Bucket(b)
        let bucketStr = "#\(String(b, radix: _Bitmap.capacity, uppercase: true))"
        if itemMap.contains(bucket) {
          let item = self[item: itemOffset]
          let hash = _Hash(item.key).description
          let itemStr = "hash: \(hash), key: \(item.key), value: \(item.value)"
          print("\(restPrefix)  \(bucketStr) \(itemStr)")
          itemOffset += 1
        } else if childMap.contains(bucket) {
          self[child: childOffset].dump(
            firstPrefix: "\(restPrefix)  \(bucketStr) ",
            restPrefix: "\(restPrefix)     ",
            limit: limit - 1)
          childOffset += 1
        }
      }
    }
  }
}
