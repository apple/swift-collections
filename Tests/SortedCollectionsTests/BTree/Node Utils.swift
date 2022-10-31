//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if DEBUG
import _CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

struct NodeTemplate {
  let keys: [Int]
  let children: [NodeTemplate]?
  
  func toNode(ofCapacity capacity: Int) -> _Node<Int, Int> {
    let kvs = self.keys.map { (key: $0, value: $0 * 2) }
    return _Node(
      _keyValuePairs: kvs,
      children: children?.map({ $0.toNode(ofCapacity: capacity) }),
      capacity: capacity
    )
  }
  
  func toBTree(ofCapacity capacity: Int) -> _BTree<Int, Int> {
    return _BTree(rootedAt: self.toNode(ofCapacity: capacity), internalCapacity: capacity)
  }
  
  func matches(_ btree: _BTree<Int, Int>) -> Bool {
    return self.matches(btree.root)
  }
  
  func matches(_ node: _Node<Int, Int>) -> Bool {
    return node.read { handle in
      if self.keys.count != handle.elementCount { return false }
      if (self.children == nil) != handle.isLeaf { return false }
      
      if let children = self.children {
        for (i, child) in children.enumerated() {
          if !child.matches(handle[childAt: i]) {
            return false
          }
        }
      }
      
      for (i, key) in self.keys.enumerated() {
        if handle[keyAt: i] != key {
          return false
        }
      }
      
      return true
    }
  }
}

@resultBuilder
struct NodeTemplateBuilder {
  static func buildBlock(_ components: Any...) -> NodeTemplate {
    var keys = [Int]()
    var children = [NodeTemplate]()
    for c in components {
      switch c {
      case let c as Int:
        keys.append(c)
      case let c as NodeTemplate:
        children.append(c)
      default:
        preconditionFailure("NodeTemplate child must be either key or child.")
      }
    }
    precondition(children.count == 0 || children.count == keys.count + 1,
                 "NodeTemplate must be either leaf or internal node.")
    return NodeTemplate(keys: keys, children: children.isEmpty ? nil : children)
  }
}

func tree(@NodeTemplateBuilder _ builder: () -> NodeTemplate) -> NodeTemplate {
  return builder()
}
#endif
