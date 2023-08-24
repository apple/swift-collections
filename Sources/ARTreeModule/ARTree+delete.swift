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
    if root == nil {
      return
    }

    let isUnique = root!.isUnique
    var child = root
    switch _delete(child: &child, key: key, depth: 0, isUniquePath: isUnique) {
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

  private mutating func _delete(child: inout RawNode?,
                                key: Key,
                                depth: Int,
                                isUniquePath: Bool) -> UpdateResult<RawNode?> {
    if child?.type == .leaf {
      let leaf: NodeLeaf<Spec> = child!.toLeafNode()
      if !leaf.keyEquals(with: key, depth: depth) {
        return .noop
      }

      return .replaceWith(nil)
    }

    assert(!Const.testCheckUnique || isUniquePath, "unique path is expected in this test")
    var node: any InternalNode<Spec> = child!.toInternalNode()
    var newDepth = depth

    if node.partialLength > 0 {
      let matchedBytes = node.prefixMismatch(withKey: key, fromIndex: depth)
      assert(matchedBytes <= node.partialLength)
      newDepth += matchedBytes
    }

    return node.updateChild(forKey: key[newDepth], isUniquePath: isUniquePath) {
      var child = $0
      return _delete(child: &child, key: key, depth: newDepth + 1, isUniquePath: $1)
    }
  }
}
