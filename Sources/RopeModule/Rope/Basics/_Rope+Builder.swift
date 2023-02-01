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

extension _Rope {
  init(_ items: some Sequence<Element>) {
    if let items = items as? Self {
      self = items
      return
    }
    var builder = Builder()
    for item in items {
      builder.append(item)
    }
    self = builder.finalize()
  }
}

extension _Rope {
  struct Builder {
    typealias Rope = _Rope
    
    //       ║                    ║
    //       ║ ║                ║ ║
    //       ║ ║ ║            ║ ║ ║
    //       ║ ║ ║ ║        ║ ║ ║ ║
    //     ──╨─╨─╨─╨──╨──╨──╨─╨─╨─╨──
    // →prefixTrees→  ↑  ↑  ←suffixTrees←
    //           prefix  suffix
    
    private var prefixTrees: [_Rope] = []
    private var prefixLeaf: _Rope.Node?
    var prefix: _Rope.Item?
    
    var suffix: _Rope.Item?
    var suffixTrees: [_Rope] = []
    
    var isPrefixEmpty: Bool {
      if prefix != nil { return false }
      if let leaf = self.prefixLeaf, !leaf.isEmpty { return false }
      return prefixTrees.isEmpty
    }
    
    var isSuffixEmpty: Bool {
      if suffix != nil { return false }
      return suffixTrees.isEmpty
    }

    var prefixSummary: Summary {
      var sum = Summary.zero
      for sapling in prefixTrees {
        sum.add(sapling.summary)
      }
      if let leaf = prefixLeaf { sum.add(leaf.summary) }
      if let item = prefix { sum.add(item.summary) }
      return sum
    }

    var suffixSummary: Summary {
      var sum = Summary.zero
      if let item = suffix { sum.add(item.summary) }
      for rope in suffixTrees {
        sum.add(rope.summary)
      }
      return sum
    }

    var lastPrefixItem: _Rope.Item {
      get {
        assert(!isPrefixEmpty)
        if let item = self.prefix { return item }
        if let leaf = self.prefixLeaf { return leaf.lastItem }
        return prefixTrees.last!.root.lastItem
      }
      _modify {
        assert(!isPrefixEmpty)
        if prefix != nil {
          yield &prefix!
        } else if prefixLeaf?.isEmpty == false {
          yield &prefixLeaf!.lastItem
        } else {
          yield &prefixTrees[prefixTrees.count - 1].root.lastItem
        }
      }
    }
    
    var firstSuffixItem: _Rope.Item {
      get {
        assert(!isSuffixEmpty)
        if let suffix { return suffix }
        return suffixTrees[suffixTrees.count - 1].root.firstItem
      }
      _modify {
        assert(!isSuffixEmpty)
        if suffix != nil {
          yield &suffix!
        } else {
          yield &suffixTrees[suffixTrees.count - 1].root.firstItem
        }
      }
    }

    func forEachElementInPrefix(
      from position: Int,
      in metric: some _RopeMetric<Element>,
      _ body: (Element, Element.Index?) -> Bool
    ) -> Bool {
      var position = position
      var i = 0
      while i < prefixTrees.count {
        let size = metric.size(of: prefixTrees[i].summary)
        if position < size { break }
        position -= size
        i += 1
      }
      if i < prefixTrees.count {
        guard prefixTrees[i].forEachWhile(from: position, in: metric, body) else { return false }
        i += 1
        while i < prefixTrees.count {
          guard prefixTrees[i].forEachWhile({ body($0, nil) }) else { return false }
          i += 1
        }
        if let leaf = self.prefixLeaf {
          guard leaf.forEachWhile({ body($0, nil) }) else { return false }
        }
        if let item = self.prefix {
          guard body(item.value, nil) else { return false }
        }
        return true
      }

      if let leaf = self.prefixLeaf {
        let size = metric.size(of: leaf.summary)
        if position < size {
          guard leaf.forEachWhile(from: position, in: metric, body) else { return false }
          if let item = self.prefix {
            guard body(item.value, nil) else { return false }
          }
          return true
        }
        position -= size
      }
      if let item = self.prefix {
        let i = metric.index(at: position, in: item.value)
        guard body(item.value, i) else { return false}
      }
      return true
    }
    
    mutating func mutatingForEachSuffix<R>(
      _ body: (inout Element) -> R?
    ) -> R? {
      if self.suffix != nil,
         let r = body(&self.suffix!.value) {
        return r
      }
      for i in stride(from: suffixTrees.count - 1, through: 0, by: -1) {
        if let r = self.suffixTrees[i].mutatingForEach(body) {
          return r
        }
      }
      return nil
    }
    
    mutating func append(_ item: __owned Element) {
      append(_Rope.Item(item))
    }
    
    mutating func append(_ item: __owned _Rope.Item) {
      guard !item.isEmpty else { return }
      guard var prefix = self.prefix._take() else {
        self.prefix = item
        return
      }
      var item = item
      if prefix.rebalance(nextNeighbor: &item) {
        self.prefix = prefix
        return
      }
      _append(prefix)
      self.prefix = item
    }
    
    mutating func _append(_ item: __owned _Rope.Item) {
      assert(self.prefix == nil)
      assert(!item.isUndersized)
      var leaf = self.prefixLeaf._take() ?? .createLeaf()
      leaf._appendItem(item)
      if leaf.isFull {
        self._append(leaf)
      } else {
        self.prefixLeaf = leaf
      }
      invariantCheck()
    }
    
    mutating func append(_ rope: __owned Rope) {
      guard rope._root != nil else { return }
      append(rope.root)
    }
    
    mutating func append(_ node: __owned Rope.Node) {
      defer { invariantCheck() }
      var node = node
      if node.height == 0 {
        if node.childCount == 1 {
          append(node.firstItem)
          return
        }
        if let item = self.prefix._take() {
          if let spawn = node.prepend(item) {
            append(node)
            append(spawn)
            return
          }
        }
        if var leaf = self.prefixLeaf._take() {
          if leaf.rebalance(nextNeighbor: &node), !leaf.isFull {
            self.prefixLeaf = leaf
            return
          }
          self._append(leaf)
        }
        
        if node.isFull {
          self._append(node)
        } else {
          self.prefixLeaf = node
        }
        return
      }
      
      if var prefix = self.prefix._take() {
        if !prefix.isUndersized || !node.firstItem.rebalance(prevNeighbor: &prefix) {
          self._append(prefix)
        }
      }
      if let leaf = self.prefixLeaf._take() {
        _append(leaf)
      }
      _append(node)
    }

    mutating func _append(_ rope: __owned Rope.Node) {
      assert(self.prefix == nil && self.prefixLeaf == nil)
      var new = rope
      while !prefixTrees.isEmpty {
        // Join previous saplings together until they grow at least as deep as the new one.
        var previous = prefixTrees.removeLast()
        while previous.height < new.height {
          if prefixTrees.isEmpty {
            previous.append(new)
            prefixTrees.append(previous)
            return
          }
          previous.prepend(prefixTrees.removeLast())
        }
        
        if previous.height == new.height {
          if previous.root.rebalance(nextNeighbor: &new) {
            new = previous.root
          } else {
            new = .createInner(children: previous.root, new)
          }
          continue
        }
        
        if new.isFull, !previous.root.isFull, previous.height == new.height + 1 {
          // Graft node under the last sapling, as a new child branch.
          previous.root._appendNode(new)
          new = previous.root
          continue
        }
        
        // The new seedling can be appended to the line and we're done.
        prefixTrees.append(previous)
        break
      }
      prefixTrees.append(Rope(root: new))
    }
    
    mutating func prependSuffix(_ item: __owned Item) {
      guard !item.isEmpty else { return }
      if var suffixItem = self.suffix._take() {
        var item = item
        if !(suffixItem.isUndersized && item.rebalance(nextNeighbor: &suffixItem)) {
          if suffixTrees.isEmpty {
            suffixTrees.append(Rope(root: .createLeaf(suffixItem)))
          } else {
            suffixTrees[suffixTrees.count - 1].prepend(suffixItem.value)
          }
        }
      }
      self.suffix = item
    }
    
    mutating func prependSuffix(_ rope: __owned Rope) {
      assert(suffix == nil)
      assert(suffixTrees.isEmpty || rope.height <= suffixTrees.last!.height)
      suffixTrees.append(rope)
    }
    
    mutating func prependSuffix(_ rope: __owned Rope.Node) {
      prependSuffix(_Rope(root: rope))
    }

    mutating func append(slots: Range<Int>, in node: __owned Rope.Node) {
      assert(slots.lowerBound >= 0 && slots.upperBound <= node.childCount)
      let c = slots.count
      guard c > 0 else { return }
      if c == 1 {
        if node.isLeaf {
          let item = node.readLeaf { $0.children[slots.lowerBound] }
          append(item)
        } else {
          let child = node.readInner { $0.children[slots.lowerBound] }
          append(child)
        }
        return
      }
      let copy = node.copy(slots: slots)
      append(copy)
    }

    mutating func prependSuffix(slots: Range<Int>, in node: __owned Rope.Node) {
      assert(slots.lowerBound >= 0 && slots.upperBound <= node.childCount)
      let c = slots.count
      guard c > 0 else { return }
      if c == 1 {
        if node.isLeaf {
          let item = node.readLeaf { $0.children[slots.lowerBound] }
          prependSuffix(item)
        } else {
          let child = node.readInner { $0.children[slots.lowerBound] }
          prependSuffix(child)
        }
        return
      }
      let copy = node.copy(slots: slots)
      prependSuffix(copy)
    }


    mutating func finalize() -> Rope {
      // Integrate prefix & suffix chunks.
      if let suffixItem = self.suffix._take() {
        append(suffixItem)
      }
      if var prefix = self.prefix._take() {
        if !prefix.isUndersized {
          _append(prefix)
        } else if !self.isPrefixEmpty {
          if !self.lastPrefixItem.rebalance(nextNeighbor: &prefix) {
            _append(prefix)
          }
        } else if !self.isSuffixEmpty {
          if !self.firstSuffixItem.rebalance(prevNeighbor: &prefix) {
            _append(prefix)
          }
        } else {
          // We only have the seed; allow undersized chunk
          return Rope(root: .createLeaf(prefix))
        }
      }
      assert(self.prefix == nil && self.suffix == nil)
      while let tree = suffixTrees.popLast() {
        append(tree)
      }
      // Merge all saplings, the seedling and the seed into a single rope.
      if let item = self.prefix._take() {
        _append(item)
      }
      var rope = Rope(root: prefixLeaf._take())
      while let tree = prefixTrees.popLast() {
        rope.prepend(tree)
      }
      assert(prefixLeaf == nil && prefixTrees.isEmpty && suffixTrees.isEmpty)
      rope.invariantCheck()
      return rope
    }
    
    func invariantCheck() {
#if DEBUG
      var h = UInt8.max
      for sapling in prefixTrees {
        precondition(sapling.height <= h)
        sapling.invariantCheck()
        h = sapling.height
      }
      if let leaf = self.prefixLeaf {
        precondition(leaf.height == 0)
        precondition(!leaf.isFull)
        leaf.invariantCheck(depth: 0, height: 0)
      }
      h = 0
      for tree in suffixTrees.reversed() {
        precondition(tree.height >= h)
        tree.invariantCheck()
        h = tree.height
      }
#endif
      
    }
    
    func dump(heightLimit: Int = Int.max) {
      for i in self.prefixTrees.indices {
        print("Sapling \(i):")
        self.prefixTrees[i].dump(heightLimit: heightLimit, firstPrefix: "  ", restPrefix: "  ")
      }
      if let leaf = self.prefixLeaf {
        print("Seedling:")
        leaf.dump(heightLimit: heightLimit, firstPrefix: "  ", restPrefix: "  ")
      }
      if let item = self.prefix {
        print("Seed:")
        print("  \(item)")
      }
      print("---")
      var i = 0
      if let item = self.suffix {
        print("Suffix \(i):")
        i += 1
        print("  \(item)")
      }
      for tree in self.suffixTrees.reversed() {
        print("Suffix \(i)")
        i += 1
        tree.dump(heightLimit: heightLimit, firstPrefix: "  ", restPrefix: "  ")
      }
    }
  }
}
