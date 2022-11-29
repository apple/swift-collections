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

#if swift(>=5.7)
import _CollectionsUtilities

extension _HashNode {
  @inlinable
  internal func combining(
    _ level: _HashLevel,
    _ other: Self,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Self {
    assert(level.isAtRoot)
    let builder = try Self._combining_node_node(
      level,
      left: self,
      right: other,
      by: strategy)
    let root = builder.finalize(.top)
    root._fullInvariantCheck()
    return root
  }

  @inlinable
  internal static func _combining_node_node(
    _ level: _HashLevel,
    left: _HashNode,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    if left.raw.storage === right.raw.storage {
      switch strategy.commonBehavior {
      case .include:
        return .node(level, left)
      case .discard:
        return .empty(level)
      case .merge:
        return try .mergedUniqueBranch(level, left) { item in
          try strategy.merge(item.key, item.value, item.value)
        }
      }
    }

    let lc = left.isCollisionNode
    let rc = right.isCollisionNode
    if lc {
      if rc {
        return try Self._combining_collision_collision(
          level, left: left, right: right, by: strategy)
      }
      assert(!level.isAtBottom) // We must be on a compressed path
      return try Self._combining_collision_tree(
        level, left: left, right: right, by: strategy)
    }
    if rc {
      return try Self._combining_tree_collision(
        level, left: left, right: right, by: strategy)
    }

    return try left.read { l in
      try right.read { r in
        var result: Builder = .empty(level)

        let lmap = l.itemMap.union(l.childMap)
        let rmap = r.itemMap.union(r.childMap)

        var buckets = lmap.union(rmap)
        while let bucket = buckets.popFirst() {
          let branch: Builder
          if l.itemMap.contains(bucket) {
            let lslot = l.itemMap.slot(of: bucket)
            if r.itemMap.contains(bucket) {
              let rslot = r.itemMap.slot(of: bucket)
              branch = try Self._combining_item_item(
                level.descend(),
                left: l.itemPtr(at: lslot),
                right: r.itemPtr(at: rslot),
                at: bucket,
                by: strategy)
            }
            else if r.childMap.contains(bucket) {
              let rslot = r.childMap.slot(of: bucket)
              branch = try Self._combining_item_tree(
                level.descend(),
                left: l.itemPtr(at: lslot),
                right: r[child: rslot],
                by: strategy)
            }
            else {
              branch = try Self._combining_item_nil(
                level.descend(),
                left: l.itemPtr(at: lslot),
                at: bucket,
                by: strategy)
            }
          }
          else if l.childMap.contains(bucket) {
            let lslot = l.childMap.slot(of: bucket)
            if r.itemMap.contains(bucket) {
              let rslot = r.itemMap.slot(of: bucket)
              branch = try Self._combining_tree_item(
                level.descend(),
                left: l[child: lslot],
                right: r.itemPtr(at: rslot),
                by: strategy)
            }
            else if r.childMap.contains(bucket) {
              let rslot = r.childMap.slot(of: bucket)
              branch = try Self._combining_node_node(
                level.descend(),
                left: l[child: lslot],
                right: r[child: rslot],
                by: strategy)
            }
            else {
              branch = try Self._combining_tree_nil(
                level.descend(),
                left: l[child: lslot],
                by: strategy)
            }
          }
          else if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            branch = try Self._combining_nil_item(
              level.descend(),
              right: r.itemPtr(at: rslot),
              at: bucket,
              by: strategy)
          }
          else {
            assert(r.childMap.contains(bucket))
            let rslot = r.childMap.slot(of: bucket)
            branch = try Self._combining_nil_tree(
              level.descend(),
              right: r[child: rslot],
              by: strategy)
          }
          result.addNewChildBranch(level, branch, at: bucket)
        }
        return result
      }
    }
  }

  @inlinable
  internal static func _combining_nil_branch(
    _ level: _HashLevel,
    right: Builder,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    switch right.kind {
    case .empty:
      return .empty(level)
    case .item(let item, at: let bucket):
      guard let new = try strategy._processAdd(item) else {
        return .empty(level)
      }
      return .item(level, new, at: bucket)
    case .node(let node):
      return try _combining_nil_tree(level, right: node, by: strategy)
    case .collisionNode(let node):
      return try _combining_nil_collision(level, right: node, by: strategy)
    }
  }

  @inlinable
  internal static func _combining_branch_nil(
    _ level: _HashLevel,
    left: Builder,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    switch left.kind {
    case .empty:
      return .empty(level)
    case .item(let item, at: let bucket):
      guard let new = try strategy._processRemove(item) else {
        return .empty(level)
      }
      return .item(level, new, at: bucket)
    case .node(let node):
      return try _combining_tree_nil(level, left: node, by: strategy)
    case .collisionNode(let node):
      return try _combining_collision_nil(level, left: node, by: strategy)
    }
  }

  @inlinable
  internal static func _combining_item_item(
    _ level: _HashLevel,
    left: UnsafePointer<Element>,
    right: UnsafePointer<Element>,
    at bucket: _Bucket,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    if left.pointee.key == right.pointee.key {
      guard let item = try strategy._processCommon(left, right) else {
        return .empty(level)
      }
      return .item(level, item, at: bucket)
    } else {
      let item1 = try strategy._processRemove(left.pointee)
      let item2 = try strategy._processAdd(right.pointee)
      return .conflictingItems(level, item1, item2, at: bucket)
    }
  }

  @inlinable
  internal static func _combining_item_nil(
    _ level: _HashLevel,
    left: UnsafePointer<Element>,
    at bucket: _Bucket,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    guard let item = try strategy._processRemove(left.pointee) else {
      return .empty(level)
    }
    return .item(level, item, at: bucket)
  }

  @inlinable
  internal static func _combining_nil_item(
    _ level: _HashLevel,
    right: UnsafePointer<Element>,
    at bucket: _Bucket,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    guard let item = try strategy._processAdd(right.pointee) else {
      return .empty(level)
    }
    return .item(level, item, at: bucket)
  }

  @inlinable
  internal static func _combining_tree_nil(
    _ level: _HashLevel,
    left: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    switch strategy.removeBehavior {
    case .include:
      return .node(level, left)
    case .discard:
      return .empty(level)
    case .merge:
      return try Builder.mergedUniqueBranch(level, left) { item in
        try strategy.merge(item.key, item.value, nil)
      }
    }
  }

  @inlinable
  internal static func _combining_nil_tree(
    _ level: _HashLevel,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    switch strategy.addBehavior {
    case .include:
      return .node(level, right)
    case .discard:
      return .empty(level)
    case .merge:
      return try Builder.mergedUniqueBranch(level, right) { item in
        try strategy.merge(item.key, nil, item.value)
      }
    }
  }

  @inlinable
  internal static func _combining_item_tree(
    _ level: _HashLevel,
    left: UnsafePointer<Element>,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    let hash = _Hash(left.pointee.key)
    switch strategy.addBehavior {
    case .include:
      if var t = right.removing(level, left.pointee.key, hash) {
        guard let item = try strategy._processCommon(left, &t.removed) else {
          return t.replacement
        }
        var rnode = t.replacement.finalize(level)
        let t2 = rnode.insert(level, item, hash)
        assert(t2.inserted)
        return .node(level, rnode)
      }
      guard let item = try strategy._processRemove(left.pointee) else {
        return .node(level, right)
      }
      let t2 = right.inserting(level, item, hash)
      assert(t2.inserted)
      return .node(level, t2.node)
    case .discard:
      if let t = right.lookup(level, left.pointee.key, hash) {
        let item = try UnsafeHandle.read(t.node) { rn in
          try strategy._processCommon(left, rn.itemPtr(at: t.slot))
        }
        guard let item else { return .empty(level) }
        return .item(level, item, at: .invalid)
      }
      guard let item = try strategy._processRemove(left.pointee) else {
        return .empty(level)
      }
      return .item(level, item, at: .invalid)
    case .merge:
      if var t = right.removing(level, left.pointee.key, hash) {
        var rnode = t.replacement.finalize(level)
        let b = try Builder.mergedUniqueBranch(level, rnode) {
          try strategy.merge($0.key, nil, $0.value)
        }
        guard let item = try strategy._processCommon(left, &t.removed) else {
          return b
        }
        rnode = b.finalize(level)
        let t2 = rnode.insert(level, item, hash)
        assert(t2.inserted)
        return .node(level, rnode)
      }
      let b = try Builder.mergedUniqueBranch(level, right) {
        try strategy.merge($0.key, nil, $0.value)
      }
      guard let item = try strategy._processRemove(left.pointee) else {
        return b
      }
      var rnode = b.finalize(level)
      let t2 = rnode.insert(level, item, hash)
      assert(t2.inserted)
      return .node(level, rnode)
    }
  }

  @inlinable
  internal static func _combining_tree_item(
    _ level: _HashLevel,
    left: _HashNode,
    right: UnsafePointer<Element>,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    let hash = _Hash(right.pointee.key)
    switch strategy.removeBehavior {
    case .include:
      if var t = left.removing(level, right.pointee.key, hash) {
        guard let item = try strategy._processCommon(&t.removed, right) else {
          return t.replacement
        }
        var lnode = t.replacement.finalize(level)
        let t2 = lnode.insert(level, item, hash)
        assert(t2.inserted)
        return .node(level, lnode)
      }
      guard let item = try strategy._processAdd(right.pointee) else {
        return .node(level, left)
      }
      let t2 = left.inserting(level, item, hash)
      assert(t2.inserted)
      return .node(level, t2.node)
    case .discard:
      if let t = left.lookup(level, right.pointee.key, hash) {
        let item = try UnsafeHandle.read(t.node) { ln in
          try strategy._processCommon(ln.itemPtr(at: t.slot), right)
        }
        guard let item else { return .empty(level) }
        return .item(level, item, at: .invalid)
      }
      guard let item = try strategy._processAdd(right.pointee) else {
        return .empty(level)
      }
      return .item(level, item, at: .invalid)
    case .merge:
      if var t = left.removing(level, right.pointee.key, hash) {
        var lnode = t.replacement.finalize(level)
        let b = try Builder.mergedUniqueBranch(level, lnode) {
          try strategy.merge($0.key, $0.value, nil)
        }
        guard let item = try strategy._processCommon(&t.removed, right) else {
          return b
        }
        lnode = b.finalize(level)
        let t2 = lnode.insert(level, item, hash)
        assert(t2.inserted)
        return .node(level, lnode)
      }
      let b = try Builder.mergedUniqueBranch(level, left) {
        try strategy.merge($0.key, $0.value, nil)
      }
      guard let item = try strategy._processAdd(right.pointee) else {
        return b
      }
      var lnode = b.finalize(level)
      let t2 = lnode.insert(level, item, hash)
      assert(t2.inserted)
      return .node(level, lnode)
    }
  }

  @inlinable
  internal static func _combining_collision_collision(
    _ level: _HashLevel,
    left: _HashNode,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(left.isCollisionNode && right.isCollisionNode)
    let lhash = left.collisionHash
    let rhash = right.collisionHash
    guard lhash == rhash else {
      let ln = try Self._combining_collision_nil(
        level, left: left, by: strategy)
      let rn = try Self._combining_nil_collision(
        level, right: right, by: strategy)
      return Builder(level, collisions1: ln, lhash, collisions2: rn, rhash)
    }

    return try left.read { l in
      try right.read { r in
        var result: Builder = .empty(level)

        let ritems = r.reverseItems
        try _UnsafeBitSet.withTemporaryBitSet(capacity: ritems.count) { bitset in
          bitset.insertAll(upTo: ritems.count)
          let hash = l.collisionHash
          for lslot: _HashSlot in .zero ..< l.itemsEndSlot {
            let lp = l.itemPtr(at: lslot)
            let match = r._findInCollision(lp.pointee.key)
            if match.found {
              bitset.remove(match.slot.value)
              let rp = r.itemPtr(at: match.slot)
              if let new = try strategy._processCommon(lp, rp) {
                result.addNewCollision(level, new, hash)
              }
            } else {
              if let new = try strategy._processRemove(lp.pointee) {
                result.addNewCollision(level, new, hash)
              }
            }
          }
          for offset in bitset {
            let rslot = _HashSlot(offset)
            let rp = r.itemPtr(at: rslot)
            if let new = try strategy._processAdd(rp.pointee) {
              result.addNewCollision(level, new, hash)
            }
          }
        }
        return result
      }
    }
  }

  @inlinable
  internal static func _combining_collision_branch(
    _ level: _HashLevel,
    left: _HashNode,
    right: Builder,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(left.isCollisionNode)
    switch right.kind {
    case .empty:
      return try _combining_collision_nil(
        level,
        left: left,
        by: strategy)
    case .item(let item, at: _):
      return try _combining_collision_item(
        level,
        left: left,
        right: item,
        by: strategy)
    case .node(let node):
      return try _combining_collision_tree(
        level,
        left: left,
        right: node,
        by: strategy)
    case .collisionNode(let node):
      return try _combining_collision_collision(
        level,
        left: left,
        right: node,
        by: strategy)
    }
  }

  @inlinable
  internal static func _combining_branch_collision(
    _ level: _HashLevel,
    left: Builder,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(right.isCollisionNode)
    switch left.kind {
    case .empty:
      return try _combining_nil_collision(
        level,
        right: right,
        by: strategy)
    case .item(let item, at: _):
      return try _combining_item_collision(
        level,
        left: item,
        right: right,
        by: strategy)
    case .node(let node):
      return try _combining_tree_collision(
        level,
        left: node,
        right: right,
        by: strategy)
    case .collisionNode(let node):
      return try _combining_collision_collision(
        level,
        left: node,
        right: right,
        by: strategy)
    }
  }

  @inlinable
  internal static func _combining_collision_nil(
    _ level: _HashLevel,
    left: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(left.isCollisionNode)
    switch strategy.removeBehavior {
    case .include:
      return .node(level, left)
    case .discard:
      return .empty(level)
    case .merge:
      return try .mergedUniqueBranch(level, left) { item in
        try strategy.merge(item.key, item.value, nil)
      }
    }
  }

  @inlinable
  internal static func _combining_nil_collision(
    _ level: _HashLevel,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(right.isCollisionNode)
    switch strategy.addBehavior {
    case .include:
      return .node(level, right)
    case .discard:
      return .empty(level)
    case .merge:
      var result: Builder = .empty(level)
      try right.read { r in
        let hash = r.collisionHash
        for rslot: _HashSlot in .zero ..< r.itemsEndSlot {
          let rp = r.itemPtr(at: rslot)
          if let v = try strategy.merge(rp.pointee.key, nil, rp.pointee.value) {
            result.addNewCollision(level, (rp.pointee.key, v), hash)
          }
        }
      }
      return result
    }
  }

  @inlinable
  internal static func _combining_collision_tree(
    _ level: _HashLevel,
    left: _HashNode,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(left.isCollisionNode)
    assert(!right.isCollisionNode)
    return try left.read { l in
      let bucket = l.collisionHash[level]

      let (removed, remainder) = right.removing(level, bucket)

      var result = try _combining_nil_branch(
        level, right: remainder, by: strategy)

      let branch = try _combining_collision_branch(
        level.descend(),
        left: left,
        right: removed,
        by: strategy)
      result.addNewChildBranch(level, branch, at: bucket)
      return result
    }
  }

  @inlinable
  internal static func _combining_tree_collision(
    _ level: _HashLevel,
    left: _HashNode,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(!left.isCollisionNode)
    assert(right.isCollisionNode)
    return try right.read { r in
      let bucket = r.collisionHash[level]

      let (removed, remainder) = left.removing(level, bucket)

      var result = try _combining_branch_nil(
        level, left: remainder, by: strategy)

      let branch = try _combining_branch_collision(
        level.descend(),
        left: removed,
        right: right,
        by: strategy)
      result.addNewChildBranch(level, branch, at: bucket)
      return result
    }
  }

  @inlinable
  internal static func _combining_collision_item(
    _ level: _HashLevel,
    left: _HashNode,
    right: Element,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(left.isCollisionNode)
    let hash = _Hash(right.key)
    if left.collisionHash == hash {
      if let r = left.removing(level, right.key, hash) {
        var result = try _combining_branch_nil(
          level, left: r.replacement, by: strategy)
        if let removed = try strategy._processCommon(r.removed, right) {
          result.addNewCollision(level, removed, hash)
        }
        return result
      }
      var result = try _combining_collision_nil(
        level, left: left, by: strategy)
      if let new = try strategy._processAdd(right) {
        result.addNewCollision(level, new, hash)
      }
      return result
    }

    let branch = try _combining_collision_nil(level, left: left, by: strategy)
    guard let item = try strategy._processAdd(right) else {
      return branch
    }
    var result: Builder = .empty(level)
    result.addNewItem(level, item, at: hash[level])
    result.addNewChildBranch(level, branch, at: left.collisionHash[level])
    return result
  }

  @inlinable
  internal static func _combining_item_collision(
    _ level: _HashLevel,
    left: Element,
    right: _HashNode,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Builder {
    assert(right.isCollisionNode)
    let hash = _Hash(left.key)
    if right.collisionHash == hash {
      if let r = right.removing(level, left.key, hash) {
        var result = try _combining_nil_branch(
          level, right: r.replacement, by: strategy)
        if let removed = try strategy._processCommon(left, r.removed) {
          result.addNewCollision(level, removed, hash)
        }
        return result
      }
      var result = try _combining_nil_collision(
        level, right: right, by: strategy)
      if let new = try strategy._processRemove(left) {
        result.addNewCollision(level, new, hash)
      }
      return result
    }

    let branch = try _combining_nil_collision(level, right: right, by: strategy)
    guard let item = try strategy._processRemove(left) else {
      return branch
    }
    var result: Builder = .empty(level)
    result.addNewItem(level, item, at: hash[level])
    result.addNewChildBranch(level, branch, at: right.collisionHash[level])
    return result
  }


}

extension TreeDictionaryCombiningStrategy {
  @inlinable
  internal func _processCommon(
    _ p1: UnsafePointer<Element>,
    _ p2: UnsafePointer<Element>
  ) throws -> Element? {
    try _processCommon(p1.pointee, p2.pointee)
  }

  @inlinable
  internal func _processCommon(
    _ item1: Element,
    _ item2: Element
  ) throws -> Element? {
    assert(item1.key == item2.key)
    let b = commonBehavior
    if
      b == .merge
        || !areEquivalentValues(item1.value, item2.value)
    {
      let v = try merge(item1.key, item1.value, item2.value)
      guard let v = v else { return nil }
      return (item1.key, v)
    }
    if b == .include {
      return item1
    }
    return nil
  }

  @inlinable
  internal func _processRemove(_ item: Element) throws -> Element? {
    switch addBehavior {
    case .include:
      return item
    case .discard:
      return nil
    case .merge:
      let v = try merge(item.key, item.value, nil)
      guard let v = v else { return nil }
      return (item.key, v)
    }
  }

  @inlinable
  internal func _processAdd(_ item: Element) throws -> Element? {
    switch removeBehavior {
    case .include:
      return item
    case .discard:
      return nil
    case .merge:
      let v = try merge(item.key, nil, item.value)
      guard let v = v else { return nil }
      return (item.key, v)
    }
  }
}
#endif
