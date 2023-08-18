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

extension ARTree: Sequence {
  public typealias Element = (Key, Value)

  public struct Iterator {
    typealias _ChildIndex = InternalNode.Index

    private let tree: ARTree
    private var path: [(any InternalNode, _ChildIndex?)]

    init(tree: ARTree) {
      self.tree = tree
      self.path = []
      if let node = tree.root {
        let n = node as! any InternalNode
        self.path = [(n, n.index())]
      }
    }
  }

  public func makeIterator() -> Iterator {
    return Iterator(tree: self)
  }
}

// TODO: Instead of index, use node iterators, to advance to next child.
extension ARTree.Iterator: IteratorProtocol {
  public typealias Element = (Key, Value)

  // Exhausted childs on the tip of path. Forward to sibling.
  mutating private func advanceToSibling() {
    let _ = path.popLast()
    advanceToNextChild()
  }

  mutating private func advanceToNextChild() {
    guard let (node, index) = path.popLast() else {
      return
    }

    path.append((node, node.next(index: index!)))
  }

  mutating public func next() -> Element? {
    while !path.isEmpty {
      while let (node, _index) = path.last {
        guard let index = _index else {
          advanceToSibling()
          break
        }

        let next = node.child(at: index)!
        if next.type == .leaf {
          let leaf = next as! NodeLeaf<Value>
          let result = (leaf.key, leaf.value)
          advanceToNextChild()
          return result
        }

        path.append((next as! any InternalNode, node.index()))
      }
    }

    return nil
  }
}
