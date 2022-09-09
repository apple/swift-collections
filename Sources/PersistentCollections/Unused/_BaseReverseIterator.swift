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

#if false
/// Base class for fixed-stack iterators that traverse a hash tree in reverse
/// order. The base iterator performs a depth-first post-order traversal,
/// traversing sub-nodes (right to left).
internal struct _BaseReverseIterator<T: _NodeProtocol> {
  var currentValueCursor: Int = -1
  var currentValueNode: T? = nil

  private var currentStackLevel: Int = -1
  private var nodeIndex: [Int] = Array(repeating: 0, count: _maxDepth + 1)
  private var nodeStack: [T?] = Array(repeating: nil, count: _maxDepth + 1)

  init(rootNode: T) {
    pushNode(rootNode)
    searchNextValueNode()
  }

  private mutating func setupPayloadNode(_ node: T) {
    currentValueNode = node
    currentValueCursor = node.itemCount - 1
  }

  private mutating func pushNode(_ node: T) {
    currentStackLevel = currentStackLevel + 1

    nodeStack[currentStackLevel] = node
    nodeIndex[currentStackLevel] = node.childCount - 1
  }

  private mutating func popNode() {
    currentStackLevel = currentStackLevel - 1
  }

  ///
  /// Searches for rightmost node that contains payload values,
  /// and pushes encountered sub-nodes on a stack for depth-first traversal.
  ///
  @discardableResult
  private mutating func searchNextValueNode() -> Bool {
    while currentStackLevel >= 0 {
      let nodeCursor = nodeIndex[currentStackLevel]
      nodeIndex[currentStackLevel] = nodeCursor - 1

      if nodeCursor >= 0 {
        let currentNode = nodeStack[currentStackLevel]!
        let nextNode = currentNode.child(at: nodeCursor)
        pushNode(nextNode)
      } else {
        let currNode = nodeStack[currentStackLevel]!
        popNode()

        if currNode.hasItems {
          setupPayloadNode(currNode)
          return true
        }
      }
    }

    return false
  }

  mutating func hasNext() -> Bool {
    return (currentValueCursor >= 0) || searchNextValueNode()
  }
}
#endif
