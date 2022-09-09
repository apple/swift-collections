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
    // Fixed-stack iterator for traversing a hash tree. The iterator performs a
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

      if root.hasChildren {
        trieIteratorStackTop = root._children.makeIterator()
      }
      if root.hasItems {
        payloadIterator = root._items.makeIterator()
      }
    }
  }

  public __consuming func makeIterator() -> Iterator {
    return Iterator(_root: _root)
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
        if nextNode.hasChildren {
          trieIteratorStackRemainder.append(trieIteratorStackTop!)
          trieIteratorStackTop = nextNode._children.makeIterator()
        }
        if nextNode.hasItems {
          payloadIterator = nextNode._items.makeIterator()
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
