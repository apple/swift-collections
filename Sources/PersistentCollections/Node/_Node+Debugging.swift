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
  internal func _itemString(at offset: Int) -> String {
    let item = self[item: offset]
    let hash = _Hash(item.key).description
    return "hash: \(hash), key: \(item.key), value: \(item.value)"
  }

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
      for offset in 0 ..< itemCount {
        print("\(restPrefix)[\(offset)] \(_itemString(at: offset))")
      }
    } else {
      var itemOffset = 0
      var childOffset = 0
      for b in 0 ..< UInt(_Bitmap.capacity) {
        let bucket = _Bucket(b)
        let bucketStr = "#\(String(b, radix: _Bitmap.capacity, uppercase: true))"
        if itemMap.contains(bucket) {
          print("\(restPrefix)  \(bucketStr) \(_itemString(at: itemOffset))")
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
