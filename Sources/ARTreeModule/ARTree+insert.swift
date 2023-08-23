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
  fileprivate enum InsertAction {
    case replace(NodeLeaf<Spec>)
    case splitLeaf(NodeLeaf<Spec>, depth: Int)
    case splitNode(any InternalNode<Spec>, depth: Int, prefixDiff: Int)
    case insertInto(any InternalNode<Spec>, depth: Int)
  }

  @discardableResult
  public mutating func insert(key: Key, value: Value) -> Bool {
    guard var (action, ref) = _findInsertNode(key: key) else { return false }

    switch action {
    case .replace(_):
      fatalError("replace not supported")

    case .splitLeaf(let leaf, let depth):
      let newLeaf = Self.allocateLeaf(key: key, value: value)
      var longestPrefix = newLeaf.read {
        leaf.longestCommonPrefix(with: $0, fromIndex: depth)
      }

      var newNode = Node4<Spec>.allocate()
      _ = newNode.addChild(forKey: leaf.key[depth + longestPrefix], node: leaf)
      _ = newNode.addChild(forKey: key[depth + longestPrefix], node: newLeaf)

      while longestPrefix > 0 {
        let nBytes = Swift.min(Const.maxPartialLength, longestPrefix)
        let start = depth + longestPrefix - nBytes
        newNode.partialLength = nBytes
        newNode.partialBytes.copy(src: key[...], start: start, count: nBytes)
        longestPrefix -= nBytes + 1

        if longestPrefix <= 0 {
          break
        }

        var next = Node4<Spec>.allocate()
        _ = next.addChild(forKey: key[start - 1], node: newNode)
        newNode = next
      }

      ref.pointee = newNode.rawNode  // Replace child in parent.

    case .splitNode(var node, let depth, let prefixDiff):
      var newNode = Node4<Spec>.allocate()
      newNode.partialLength = prefixDiff
      newNode.partialBytes = node.partialBytes // TODO: Just copy min(maxPartialLength, prefixDiff)

      assert(
        node.partialLength <= Const.maxPartialLength,
        "partial length is always bounded")
      _ = newNode.addChild(forKey: node.partialBytes[prefixDiff], node: node)
      node.partialBytes.shiftLeft(toIndex: prefixDiff + 1)
      node.partialLength -= prefixDiff + 1

      let newLeaf = Self.allocateLeaf(key: key, value: value)
      _ = newNode.addChild(forKey: key[depth + prefixDiff], node: newLeaf)
      ref.pointee = newNode.rawNode

    case .insertInto(var node, let depth):
      Self.allocateLeaf(key: key, value: value).read { newLeaf in
        if case .replaceWith(let newNode) = node.addChild(forKey: key[depth], node: newLeaf) {
          ref.pointee = newNode
        }
      }
    }

    return true
  }

  // TODO: Make sure that the node returned have
  fileprivate mutating func _findInsertNode(key: Key) -> (InsertAction, NodeReference)? {
    if root == nil {
      // NOTE: Should we just create leaf? Likely tree will have more items anyway.
      root = Node4<Spec>.allocate().read { $0.rawNode }
    }

    var depth = 0
    var current: any ArtNode<Spec> = root!.toArtNode()
    var isUnique = isKnownUniquelyReferenced(&root!.buf)
    var ref = NodeReference(&root)

    while current.type != .leaf && depth < key.count {
      assert(!Const.testCheckUnique || isUnique,
             "unique path is expected in this test, depth=\(depth)")

      if !isUnique {
        // TODO: Why making this one-liner crashes?
        let clone = current.rawNode.clone(spec: Spec.self)
        current = clone.toArtNode()
        ref.pointee = current.rawNode
      }

      var node: any InternalNode<Spec> = current.rawNode.toInternalNode()
      if node.partialLength > 0 {
        let partialLength = node.partialLength
        let prefixDiff = node.prefixMismatch(withKey: key, fromIndex: depth)
        if prefixDiff >= partialLength {
          // Matched all partial bytes. Continue to next child.
          depth += partialLength
        } else {
          // Incomplete match with partial bytes, hence needs splitting.
          return (.splitNode(node, depth: depth, prefixDiff: prefixDiff), ref)
        }
      }

      // Find next child to continue.
      guard let (next, _isUnique) =
              (node.maybeReadChild(forKey: key[depth], ref: &ref) { ($0, $1) }) else {
        return (.insertInto(node, depth: depth), ref)
      }

      depth += 1
      current = next
      isUnique = _isUnique
    }

    assert(current.type == .leaf)
    // Reached leaf already, replace it with a new node, or update the existing value.
    if current.type == .leaf {
      assert(!Const.testCheckUnique || isUnique,
             "unique path is expected in this test, depth=\(depth)")

      let leaf: NodeLeaf<Spec> = current.rawNode.toLeafNode()
      if leaf.keyEquals(with: key) {
        return (.replace(leaf), ref)
      }

      if isUnique {
        return (.splitLeaf(leaf, depth: depth), ref)
      } else {
        let clone = leaf.clone()
        ref.pointee = clone.node.rawNode
        return (.splitLeaf(clone.node, depth: depth), ref)
      }
    }

    fatalError("unexpected state")
  }
}
