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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTree {
  public mutating func delete(key: Key) {
    guard var node = root else { return }
    let isUnique = true
    switch _delete(node: &node, key: key, depth: 0, isUniquePath: isUnique) {
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

  private mutating func _delete(node: inout RawNode,
                                key: Key,
                                depth: Int,
                                isUniquePath: Bool) -> UpdateResult<RawNode?> {
    assert(!Const.testCheckUnique || isUniquePath, "unique path is expected in this test")

    if node.type == .leaf {
      let leaf: NodeLeaf<Spec> = node.toLeafNode()
      if !leaf.keyEquals(with: key, depth: depth) {
        return .noop
      }

      return .replaceWith(nil)
    }

    let isUnique = isUniquePath && node.isUnique
    var newDepth = depth
    var node: any InternalNode<Spec> = node.toInternalNode()

    if node.partialLength > 0 {
      let matchedBytes = node.prefixMismatch(withKey: key, fromIndex: depth)
      assert(matchedBytes <= node.partialLength)
      newDepth += matchedBytes
    }

    return node.updateChild(forKey: key[newDepth], isUnique: isUnique) {
      guard var child = $0 else { return .noop }
      return _delete(node: &child, key: key, depth: newDepth + 1, isUniquePath: isUnique)
    }
  }
}
