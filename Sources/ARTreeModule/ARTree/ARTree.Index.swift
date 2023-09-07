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
extension ARTreeImpl {
  public struct Index {
    internal typealias _ChildIndex = InternalNode<Spec>.Index

    internal weak var root: RawNodeBuffer? = nil
    internal var current: (any ArtNode<Spec>)? = nil
    internal var path: [(any InternalNode<Spec>, _ChildIndex)] = []
    internal let version: Int

    internal init(forTree tree: ARTreeImpl<Spec>) {
      self.version = tree.version

      if let root = tree._root {
        assert(root.type != .leaf, "root can't be leaf")
        self.root = tree._root?.buf
        self.current = tree._root?.toArtNode()
      }
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTreeImpl.Index {
  internal var isOnLeaf: Bool {
    if let current = self.current {
      return current.type == .leaf
    }

    return false
  }

  internal mutating func descentToLeftMostChild() {
    while !isOnLeaf {
      descend { $0.startIndex }
    }
  }

  internal mutating func descend(_ to: (any InternalNode<Spec>)
                                   -> (any InternalNode<Spec>).Index) {
    assert(!isOnLeaf, "can't descent on a leaf node")
    assert(current != nil, "current node can't be nil")

    let currentNode: any InternalNode<Spec> = current!.rawNode.toInternalNode()
    let index = to(currentNode)
    self.path.append((currentNode, index))
    self.current = currentNode.child(at: index)?.toArtNode()
  }

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
}


@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTreeImpl.Index: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    if case (let lhs?, let rhs?) = (lhs.current, rhs.current) {
      return lhs.equals(rhs)
    }

    return false
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTreeImpl.Index: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    for ((_, idxL), (_, idxR)) in zip(lhs.path, rhs.path) {
      if idxL < idxR {
        return true
      } else if idxL > idxR {
        return false
      }
    }

    return false
  }
}
