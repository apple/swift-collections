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

extension ARTree {
  public func getValue(key: Key) -> Value? {
    assert(root != nil, "root can't be nil")
    var current = root
    var depth = 0
    while depth <= key.count {
      guard let _rawNode = current else {
        return nil
      }

      if _rawNode.type == .leaf {
        let leaf: NodeLeaf = _rawNode.toLeafNode()
        return leaf.keyEquals(with: key)
          ? leaf.value()
          : nil
      }

      let node = _rawNode.toInternalNode()
      if node.partialLength > 0 {
        let prefixLen = node.prefixMismatch(withKey: key, fromIndex: depth)
        assert(prefixLen <= Const.maxPartialLength, "partial length is always bounded")
        if prefixLen != node.partialLength {
          return nil
        }
        depth = depth + node.partialLength
      }

      current = node.child(forKey: key[depth])
      depth += 1
    }

    return nil
  }

  public mutating func getRange(start: Key, end: Key) {
    // TODO
    fatalError("not implemented")
  }
}