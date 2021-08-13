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

extension Heap {
  @usableFromInline @frozen
  struct _UnsafeHandle {
    @usableFromInline
    var buffer: UnsafeMutableBufferPointer<Element>

    @inlinable @inline(__always)
    init(_ buffer: UnsafeMutableBufferPointer<Element>) {
      self.buffer = buffer
    }
  }

  @inlinable @inline(__always)
  mutating func _update<R>(_ body: (_UnsafeHandle) -> R) -> R {
    #if false
    @inline(__always)
    func _body(
      _ buffer: inout UnsafeMutableBufferPointer<Element>
    ) -> R {
      body(_UnsafeHandle(buffer))
    }

    return _storage.withUnsafeMutableBufferPointer(_body)
    #else
    _storage.withUnsafeMutableBufferPointer { buffer in
      body(_UnsafeHandle(buffer))
    }
    #endif
  }
}

extension Heap._UnsafeHandle {
  @inlinable @inline(__always)
  internal var count: Int {
    buffer.count
  }

  @inlinable
  subscript(node: _Node) -> Element {
    @inline(__always)
    get {
      buffer[node.offset]
    }
    @inline(__always)
    nonmutating _modify {
      yield &buffer[node.offset]
    }
  }

  /// Swaps the elements in the heap at the given indices.
  @inlinable @inline(__always)
  internal func swapAt(_ i: _Node, _ j: _Node) {
    buffer.swapAt(i.offset, j.offset)
  }

  /// Swaps the element at the given node with the supplied value.
  @inlinable @inline(__always)
  internal func swapAt(_ i: _Node, with value: inout Element) {
    let p = buffer.baseAddress.unsafelyUnwrapped + i.offset
    swap(&p.pointee, &value)
  }
}

extension Heap._UnsafeHandle {
  // Note: the releasenone annotation here tells the compiler that this function
  // will not release any strong references, so it doesn't need to worry about
  // retaining things. This is true in the sense that `bubbleUp` just reorders
  // storage contents, but it does call `Element.<`, which we cannot really
  // promise anything about -- it may release things!
  //
  // FWIW, I think `Element`'s Comparable implementation can only cause the
  // heap's storage to be released if it included an exclusivity violation --
  // `bubbleUp` is only ever called from mutating heap members, after all.
  // So if there is an issue, I think it would be triggered by the `Comparable`
  // implementation releasing something inside `Element`, and/or by the
  // `releasenone` annotation here having an effect in client code that called
  // into `Heap`.
  @_effects(releasenone)
  @inlinable
  internal func bubbleUp(_ node: _Node) {
    guard let parent = node.parent() else {
      // We're already at the root -- can't go any further
      return
    }

    if node.isMinLevel {
      if self[node] > self[parent] {
        swapAt(node, parent)
        bubbleUpMax(parent)
      } else {
        bubbleUpMin(node)
      }
    } else {
      if self[node] < self[parent] {
        swapAt(node, parent)
        bubbleUpMin(parent)
      } else {
        bubbleUpMax(node)
      }
    }
  }

  @_effects(releasenone)
  @inline(__always)
  @inlinable
  internal func bubbleUpMin(_ node: _Node) {
    var node = node

    while let grandparent = node.grandParent(),
          self[node] < self[grandparent] {
      swapAt(node, grandparent)
      node = grandparent
    }
  }

  @_effects(releasenone)
  @inline(__always)
  @inlinable
  internal func bubbleUpMax(_ node: _Node) {
    var node = node

    while let grandparent = node.grandParent(),
          self[node] > self[grandparent] {
      swapAt(node, grandparent)
      node = grandparent
    }
  }
}

extension Heap._UnsafeHandle {
  @_effects(releasenone)
  @inlinable
  internal func trickleDownMin(_ node: _Node) {
    assert(node.isMinLevel)
    var node = node

    while let minDescendant = minChildOrGrandchild(of: node) {
      guard self[minDescendant] < self[node] else {
        return
      }
      swapAt(minDescendant, node)

      if minDescendant.level == node.level + 1 {
        return
      }

      // Smallest is a grandchild
      let parent = minDescendant.parent()!
      if self[minDescendant] > self[parent] {
        swapAt(minDescendant, parent)
      }

      node = minDescendant
    }
  }

  @_effects(releasenone)
  @inlinable
  internal func trickleDownMax(_ node: _Node) {
    assert(!node.isMinLevel)
    var node = node

    while let maxDescendant = maxChildOrGrandchild(of: node) {
      guard self[maxDescendant] > self[node] else {
        return
      }
      swapAt(maxDescendant, node)

      if maxDescendant.level == node.level + 1 {
        return
      }

      // Largest is a grandchild
      let parent = maxDescendant.parent()!
      if self[maxDescendant] < self[parent] {
        swapAt(maxDescendant, parent)
      }

      node = maxDescendant
    }
  }

  /// Returns the lowest priority child or grandchild of the element at the
  /// given index.
  ///
  /// Returns `nil` if the element has no descendants.
  ///
  /// - parameter index: The index of the element whose descendants should be
  ///                    compared.
  @inline(__always)
  @inlinable
  internal func minChildOrGrandchild(of node: _Node) -> _Node? {
    assert(node.isMinLevel)
    guard let leftChild = node.leftChild(limit: count) else {
      return nil
    }

    guard let rightChild = node.rightChild(limit: count) else {
      return leftChild
    }

    guard let grandchildren = node.grandchildren(limit: count) else {
      // We have no grandchildren -- compare the two children instead
      return (self[rightChild] < self[leftChild] ? rightChild : leftChild)
    }

    var minValue = self[leftChild]
    var minNode = leftChild

    // If we have at least 3 grandchildren, we can skip comparing the children
    // as the heap invariants will ensure that the grandchildren will be smaller.
    // Otherwise, we need to do the comparison.
    if grandchildren._count < 3 {
      // Compare the two children
      let rightValue = self[rightChild]
      if rightValue < minValue {
        minValue = rightValue
        minNode = rightChild
      }
    }

    // Iterate through the grandchildren
    grandchildren._forEach { grandchild in
      let value = self[grandchild]
      if value < minValue {
        minValue = value
        minNode = grandchild
      }
    }

    return minNode
  }

  /// Returns the highest priority child or grandchild of the element at the
  /// given index.
  ///
  /// Returns `nil` if the element has no descendants.
  ///
  /// - parameter index: The index of the item whose descendants should be
  ///                    compared.
  @inline(__always)
  @inlinable
  internal func maxChildOrGrandchild(of node: _Node) -> _Node? {
    assert(!node.isMinLevel)
    guard let leftChild = node.leftChild(limit: count) else {
      return nil
    }

    guard let rightChild = node.rightChild(limit: count) else {
      return leftChild
    }

    guard let grandchildren = node.grandchildren(limit: count) else {
      // We have no grandchildren -- compare the two children instead
      return (self[rightChild] > self[leftChild] ? rightChild : leftChild)
    }

    var maxValue = self[leftChild]
    var maxNode = leftChild

    // If we have at least 3 grandchildren, we can skip comparing the children
    // as the heap invariants will ensure that the grandchildren will be smaller.
    // Otherwise, we need to do the comparison.
    if grandchildren._count < 3 {
      // Compare the two children
      let rightValue = self[rightChild]
      if rightValue > maxValue {
        maxValue = rightValue
        maxNode = rightChild
      }
    }

    // Iterate through the grandchildren
    grandchildren._forEach { grandchild in
      let value = self[grandchild]
      if value > maxValue {
        maxValue = value
        maxNode = grandchild
      }
    }

    return maxNode
  }
}

extension Heap._UnsafeHandle {
  @inlinable
  internal func heapify() {
    let limit = count / 2 // The first offset without a left child
    var level = _Node.level(forOffset: limit &- 1)
    while level >= 0 {
      let nodes = _Node.allNodes(onLevel: level, limit: limit)
      if _Node.isMinLevel(level) {
        nodes?._forEach { node in
          trickleDownMin(node)
        }
      } else {
        nodes?._forEach { node in
          trickleDownMax(node)
        }
      }
      level &-= 1
    }
  }
}
