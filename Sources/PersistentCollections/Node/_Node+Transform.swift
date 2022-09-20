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
  @inlinable
  internal func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> _Node<Key, T> {
    let c = self.count
    return try read { source in
      var result = _Node<Key, T>.allocate(
        itemMap: source.itemMap,
        childMap: source.childMap,
        count: c,
        initializingWith: { _, _ in }
      ).node
      try result.update { target in
        let sourceItems = source.reverseItems
        let targetItems = target.reverseItems
        assert(sourceItems.count == targetItems.count)

        let sourceChildren = source.children
        let targetChildren = target.children
        assert(sourceChildren.count == targetChildren.count)

        var i = 0
        var j = 0

        var success = false

        defer {
          if !success {
            targetItems.prefix(i).deinitialize()
            targetChildren.prefix(j).deinitialize()
            target.clear()
          }
        }

        while i < targetItems.count {
          let key = sourceItems[i].key
          let value = try transform(sourceItems[i].value)
          targetItems.initializeElement(at: i, to: (key, value))
          i += 1
        }
        while j < targetChildren.count {
          let child = try sourceChildren[j].mapValues(transform)
          targetChildren.initializeElement(at: j, to: child)
          j += 1
        }
        success = true
      }
      return result
    }
  }
}
