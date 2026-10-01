//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension _HashNode {
  @inlinable
  internal func mapValues<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> _HashNode<Key, T> {
    let c = self.count
    return unsafe try read { source in
      var result: _HashNode<Key, T>
      if isCollisionNode {
        result = unsafe _HashNode<Key, T>.allocateCollision(
          count: c, source.collisionHash,
          initializingWith: { _ in }
        ).node
      } else {
        result = unsafe _HashNode<Key, T>.allocate(
          itemMap: source.itemMap,
          childMap: source.childMap,
          count: c,
          initializingWith: { _, _ in }
        ).node
      }
      unsafe try result.update { target in
        let sourceItems = unsafe source.reverseItems
        let targetItems = unsafe target.reverseItems
        assert(sourceItems.count == targetItems.count)

        let sourceChildren = unsafe source.children
        let targetChildren = unsafe target.children
        assert(sourceChildren.count == targetChildren.count)

        var i = 0
        var j = 0

        var success = false

        defer {
          if !success {
            unsafe targetItems.prefix(i).deinitialize()
            unsafe targetChildren.prefix(j).deinitialize()
            unsafe target.clear()
          }
        }

        while i < targetItems.count {
          let key = unsafe sourceItems[i].key
          let value = unsafe try transform(sourceItems[i])
          unsafe targetItems.initializeElement(at: i, to: (key, value))
          i += 1
        }
        while j < targetChildren.count {
          let child = unsafe try sourceChildren[j].mapValues(transform)
          unsafe targetChildren.initializeElement(at: j, to: child)
          j += 1
        }
        success = true
      }
      result._invariantCheck()
      return result
    }
  }

  @inlinable
  internal func mapValuesToVoid(
    copy: Bool = false, extraBytes: Int = 0
  ) -> _HashNode<Key, Void> {
    if Value.self == Void.self {
      let node = unsafe unsafeBitCast(self, to: _HashNode<Key, Void>.self)
      guard copy || !node.hasFreeSpace(extraBytes) else { return node }
      return node.copy(withFreeSpace: extraBytes)
    }
    let node = mapValues { _ in () }
    guard !node.hasFreeSpace(extraBytes) else { return node }
    return node.copy(withFreeSpace: extraBytes)
  }
}
