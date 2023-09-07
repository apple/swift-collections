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
extension ARTreeImpl: Sequence {
  public typealias Iterator = _Iterator

  public struct _Iterator {
    typealias _ChildIndex = InternalNode<Spec>.Index

    private let tree: ARTreeImpl<Spec>
    private var path: [(any InternalNode<Spec>, _ChildIndex)]

    init(tree: ARTreeImpl<Spec>) {
      self.tree = tree
      self.path = []
      guard let node = tree._root else { return }

      assert(node.type != .leaf, "root can't be leaf")
      let n: any InternalNode<Spec> = node.toInternalNode()
      if n.count > 0 {
        self.path = [(n, n.startIndex)]
      }
    }
  }

  public func makeIterator() -> Iterator {
    return Iterator(tree: self)
  }
}

// TODO: Instead of index, use node iterators, to advance to next child.
@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTreeImpl._Iterator: IteratorProtocol {
  public typealias Element = (Key, Spec.Value)  // TODO: Why just Value fails?

  // Exhausted childs on the tip of path. Forward to sibling.
  mutating private func advanceToSibling() {
    let _ = path.popLast()
    advanceToNextChild()
  }

  mutating private func advanceToNextChild() {
    guard let (node, index) = path.popLast() else {
      return
    }

    path.append((node, node.index(after: index)))
  }

  mutating func next() -> Element? {
    while !path.isEmpty {
      while let (node, index) = path.last {
        if index == node.endIndex {
          advanceToSibling()
          break
        }

        let next = node.child(at: index)!
        if next.type == .leaf {
          let leaf: NodeLeaf<Spec> = next.toLeafNode()
          let result = (leaf.key, leaf.value)
          advanceToNextChild()
          return result
        }

        let nextNode: any InternalNode<Spec> = next.toInternalNode()
        path.append((nextNode, nextNode.startIndex))
      }
    }

    return nil
  }
}
