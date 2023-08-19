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
  public mutating func delete(key: Key) {
    guard let node = root else { return }
    switch _delete(node: node, key: key, depth: 0) {
    case .noop:
      return
    case .replaceWith(let newValue):
      root = newValue
    }
  }

  public mutating func deleteRange(start: Key, end: Key) {
    // TODO
    fatalError("not implemented")
  }

  private mutating func _delete(node: RawNode,
                                key: Key,
                                depth: Int) -> UpdateResult<RawNode?> {
    if node.type == .leaf {
      let leaf = node.toLeafNode()
      if !leaf.keyEquals(with: key, depth: depth) {
        return .noop
      }

      return .replaceWith(nil)
    }

    var newDepth = depth
    var node = node.toInternalNode()

    if node.partialLength > 0 {
      let matchedBytes = node.prefixMismatch(withKey: key, fromIndex: depth)
      assert(matchedBytes <= node.partialLength)
      newDepth += matchedBytes
    }

    return node.updateChild(forKey: key[newDepth]) {
      guard let child = $0 else { return .noop }
      return _delete(node: child, key: key, depth: newDepth + 1)
    }
  }
}