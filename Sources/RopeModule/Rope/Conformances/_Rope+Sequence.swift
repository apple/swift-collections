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

extension _Rope: Sequence {
  func makeIterator() -> Iterator {
    Iterator(self, from: self.startIndex)
  }
  
  func makeIterator(from start: Index) -> Iterator {
    Iterator(self, from: start)
  }
  
  struct Iterator: IteratorProtocol {
    let rope: _Rope
    private(set) var index: Index
    private var leaf: Node?
    
    init(_ rope: _Rope, from start: Index) {
      self.rope = rope
      self.index = start
      self.leaf = start == rope.endIndex ? nil : rope._leaf(at: start)
    }
    
    var isAtEnd: Bool {
      leaf == nil
    }
    
    var isAtStart: Bool {
      index == rope.startIndex
    }
    
    var current: Element {
      leaf!.readLeaf { $0.children[index[height: 0]].value }
    }
    
    func withCurrent<R>(_ body: (Element) -> R) -> R {
      leaf!.readLeaf { body($0.children[index[height: 0]].value) }
    }
    
    mutating func stepForward() -> Bool {
      guard let leaf = self.leaf else { return false }
      self.leaf = nil
      if leaf.formSuccessor(of: &index) {
        self.leaf = leaf
      } else if rope.root.formSuccessor(of: &index) {
        self.leaf = rope._leaf(at: index)
      } else {
        self.leaf = leaf
        return false
      }
      return true
    }

    mutating func stepBackward() -> Bool {
      guard let leaf = self.leaf else {
        guard !rope.isEmpty else { return false }
        self.index = rope.index(before: rope.endIndex)
        self.leaf = rope._leaf(at: index)
        return true
      }
      self.leaf = nil
      if leaf.formPredecessor(of: &index) {
        self.leaf = leaf
      } else if rope.root.formPredecessor(of: &index) {
        self.leaf = rope._leaf(at: index)
      } else {
        self.leaf = leaf
        return false
      }
      return true
    }
    
    mutating func stepToEnd() {
      leaf = nil
      index = rope.endIndex
    }

    mutating func next() -> Element? {
      guard !isAtEnd else { return nil }
      let item = self.current
      if !stepForward() {
        stepToEnd()
      }
      return item
    }
  }
}

extension _Rope {
  func _leaf(at index: Index) -> Node? {
    assert(index.height == root.height)
    var node = root
    while true {
      let h = node.height
      let slot = index[height: h]
      guard slot < node.childCount else { return nil }
      if h == 0 { break }
      node = node.readInner { $0.child(at: slot)! }
    }
    return node
  }
}
