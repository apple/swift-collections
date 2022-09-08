//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary: Sequence {
  public typealias Element = (key: Key, value: Value)

  public struct Iterator {
    // Fixed-stack iterator for traversing a hash-trie. The iterator performs a
    // depth-first pre-order traversal, which yields first all payload elements
    // of the current node before traversing sub-nodes (left to right).

    typealias _KeyValueBuffer = UnsafeBufferPointer<(key: Key, value: Value)>
    typealias _NodeBuffer = UnsafeBufferPointer<_Node>

    private var payloadIterator: _KeyValueBuffer.Iterator?

    private var trieIteratorStackTop: _NodeBuffer.Iterator?
    private var trieIteratorStackRemainder: [_NodeBuffer.Iterator]

    internal init(_root root: _Node) {
      trieIteratorStackRemainder = []
      trieIteratorStackRemainder.reserveCapacity(_maxDepth)

      if root.hasNodes {
        trieIteratorStackTop = root._trieSlice.makeIterator()
      }
      if root.hasPayload {
        payloadIterator = root._dataSlice.makeIterator()
      }
    }
  }

  public __consuming func makeIterator() -> Iterator {
    return Iterator(_root: rootNode)
  }
}

extension PersistentDictionary.Iterator: IteratorProtocol {
  public typealias Element = (key: Key, value: Value)
  public mutating func next() -> Element? {
    if let payload = payloadIterator?.next() {
      return payload
    }

    while trieIteratorStackTop != nil {
      if let nextNode = trieIteratorStackTop!.next() {
        if nextNode.hasNodes {
          trieIteratorStackRemainder.append(trieIteratorStackTop!)
          trieIteratorStackTop = nextNode._trieSlice.makeIterator()
        }
        if nextNode.hasPayload {
          payloadIterator = nextNode._dataSlice.makeIterator()
          return payloadIterator?.next()
        }
      } else {
        trieIteratorStackTop = trieIteratorStackRemainder.popLast()
      }
    }

    // Clean-up state
    payloadIterator = nil

    assert(payloadIterator == nil)
    assert(trieIteratorStackTop == nil)
    assert(trieIteratorStackRemainder.isEmpty)

    return nil
  }
}
