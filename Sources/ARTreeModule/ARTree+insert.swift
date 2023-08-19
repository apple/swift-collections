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
  public mutating func insert(key: Key, value: Value) -> Bool {
    var current: RawNode = root!

    // Location of child (current) pointer in parent, i.e. memory address where the
    // address of current node is stored inside the parent node.
    // TODO: Fix warning here?
    var ref: ChildSlotPtr? = ChildSlotPtr(&root)

    var depth = 0
    while depth < key.count {
      // Reached leaf already, replace it with a new node, or update the existing value.
      if current.type == .leaf {
        let leaf: NodeLeaf = current.toLeafNode()
        if leaf.keyEquals(with: key) {
          //TODO: Replace value.
          fatalError("replace not supported")
        }

        let newLeaf = Self.allocateLeaf(key: key, value: value)
        var longestPrefix = leaf.longestCommonPrefix(with: newLeaf, fromIndex: depth)

        var newNode = Node4.allocate()
        newNode.addChild(forKey: leaf.key[depth + longestPrefix], node: leaf)
        newNode.addChild(forKey: newLeaf.key[depth + longestPrefix], node: newLeaf)

        while longestPrefix > 0 {
          let nBytes = Swift.min(Const.maxPartialLength, longestPrefix)
          let start = depth + longestPrefix - nBytes
          newNode.partialLength = nBytes
          newNode.partialBytes.copy(src: key[...], start: start, count: nBytes)
          longestPrefix -= nBytes + 1

          if longestPrefix <= 0 {
            break
          }

          var nextNode = Node4.allocate()
          nextNode.addChild(forKey: key[start - 1], node: newNode)
          newNode = nextNode
        }

        ref?.pointee = RawNode(from: newNode)  // Replace child in parent.
        return true
      }

      var node = current.toInternalNode()
      if node.partialLength > 0 {
        let partialLength = node.partialLength
        let prefixDiff = node.prefixMismatch(withKey: key, fromIndex: depth)
        if prefixDiff >= partialLength {
          // Matched all partial bytes. Continue to next child.
          depth += partialLength
        } else {
          // Incomplete match with partial bytes, hence needs splitting.
          var newNode = Node4.allocate()
          newNode.partialLength = prefixDiff
          // TODO: Just copy min(maxPartialLength, prefixDiff) bytes
          newNode.partialBytes = node.partialBytes

          assert(
            node.partialLength <= Const.maxPartialLength,
            "partial length is always bounded")
          newNode.addChild(forKey: node.partialBytes[prefixDiff], node: node)
          node.partialBytes.shiftLeft(toIndex: prefixDiff + 1)
          node.partialLength -= prefixDiff + 1

          let newLeaf = Self.allocateLeaf(key: key, value: value)
          newNode.addChild(forKey: key[depth + prefixDiff], node: newLeaf)
          ref?.pointee = newNode.rawNode
          return true
        }
      }

      // Find next child to continue.
      guard let next = node.child(forKey: key[depth], ref: &ref) else {
        // No child, insert leaf within us.
        let newLeaf = Self.allocateLeaf(key: key, value: value)
        node.addChild(forKey: key[depth], node: newLeaf, ref: ref)
        return true
      }

      depth += 1
      current = next
    }

    return false
  }
}
