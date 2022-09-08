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
/// Base class for fixed-stack iterators that traverse a hash-trie. The iterator
/// performs a depth-first pre-order traversal, which yields first all payload
/// elements of the current node before traversing sub-nodes (left to right).
internal struct _BaseIterator<T: _Node> {
  var currentValueCursor: Int = 0
  var currentValueLength: Int = 0
  var currentValueNode: T? = nil

  private var currentStackLevel: Int = -1
  private var nodeCursorsAndLengths: [Int] = (
    Array(repeating: 0, count: _maxDepth * 2))
  private var nodes: [T?] = Array(repeating: nil, count: _maxDepth)

  init(rootNode: T) {
    if rootNode.hasNodes { pushNode(rootNode) }
    if rootNode.hasPayload { setupPayloadNode(rootNode) }
  }

  private mutating func setupPayloadNode(_ node: T) {
    currentValueNode = node
    currentValueCursor = 0
    currentValueLength = node.payloadArity
  }

  private mutating func pushNode(_ node: T) {
    currentStackLevel = currentStackLevel + 1

    let cursorIndex = currentStackLevel * 2
    let lengthIndex = currentStackLevel * 2 + 1

    nodes[currentStackLevel] = node
    nodeCursorsAndLengths[cursorIndex] = 0
    nodeCursorsAndLengths[lengthIndex] = node.nodeArity
  }

  private mutating func popNode() {
    currentStackLevel = currentStackLevel - 1
  }

  ///
  /// Searches for next node that contains payload values,
  /// and pushes encountered sub-nodes on a stack for depth-first traversal.
  ///
  private mutating func searchNextValueNode() -> Bool {
    while currentStackLevel >= 0 {
      let cursorIndex = currentStackLevel * 2
      let lengthIndex = currentStackLevel * 2 + 1

      let nodeCursor = nodeCursorsAndLengths[cursorIndex]
      let nodeLength = nodeCursorsAndLengths[lengthIndex]

      if nodeCursor < nodeLength {
        nodeCursorsAndLengths[cursorIndex] += 1

        let currentNode = nodes[currentStackLevel]!
        let nextNode = currentNode.getNode(nodeCursor)

        if nextNode.hasNodes   { pushNode(nextNode) }
        if nextNode.hasPayload { setupPayloadNode(nextNode) ; return true }
      } else {
        popNode()
      }
    }

    return false
  }

  mutating func hasNext() -> Bool {
    return (currentValueCursor < currentValueLength) || searchNextValueNode()
  }
}
#endif
