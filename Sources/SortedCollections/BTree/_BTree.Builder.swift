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

extension _BTree {
  /// Provides an interface for efficiently constructing a filled B-Tree from sorted data.
  ///
  /// A builder supports duplicate keys, in which case they are inserted in the same order they are received.
  /// However, is the `deduplicating` parameter is passed as `true`, operations will silently drop
  /// duplicates.
  ///
  /// This type has a few advantages when constructing a B-Tree over other approaches such as manually
  /// inserting each element or using a cursor:
  ///
  /// This works by maintaining a list of saplings and a view of the node currently being modified. For example
  /// the following tree:
  ///
  ///             ┌─┐
  ///             │D│
  ///         ┌───┴─┴───┐
  ///         │         │
  ///        ┌┴┐       ┌┴┐
  ///        │B│       │F│
  ///      ┌─┴─┴─┐   ┌─┴─┴─┐
  ///      │     │   │     │
  ///     ┌┴┐   ┌┴┐ ┌┴┐   ┌┴┐
  ///     │A│   │C│ │E│   │G│
  ///     └─┘   └─┘ └─┘   └─┘
  ///
  /// Would be represented in the following state:
  ///
  ///                 ┌─┐
  ///      Seedling:  │G│
  ///                 └─┘
  ///
  ///                    ┌─┐
  ///                    │B│       ┌─┐
  ///      Saplings:   ┌─┴─┴─┐     │E│
  ///                  │     │     └─┘
  ///                 ┌┴┐   ┌┴┐
  ///                 │A│   │C│
  ///                 └─┘   └─┘
  ///
  ///                 ┌─┐          ┌─┐
  ///     Separators: │D│          │F│
  ///                 └─┘          └─┘
  ///
  /// While the diagrams above represent a binary-tree, the representation of a B-Tree in the builder is
  /// directly analogous to this. By representing the state this way. Append operations can be efficiently
  /// performed, and the tree can also be efficiently reconstructed.
  ///
  /// Appending works by filling in a seedling, once a seedling is full, and an associated separator has been
  /// provided, the seedling-separator pair can be appended to the stack.
  @usableFromInline
  internal struct Builder {
    @usableFromInline
    enum State {
      /// The builder needs to add a separator to the node
      case addingSeparator
      
      /// The builder needs to try to append to the seedling node.
      case appendingToSeedling
    }
    
    @usableFromInline
    internal var _saplings: [Node]
    
    @usableFromInline
    internal var _separators: [Element]
    
    @usableFromInline
    internal var _seedling: Node?
    
    @inlinable
    @inline(__always)
    internal var seedling: Node {
      get {
        assert(_seedling != nil,
               "Simultaneous access or access on consumed builder.")
        return _seedling.unsafelyUnwrapped
      }
      _modify {
        assert(_seedling != nil,
               "Simultaneous mutable access or mutable access on consumed builder.")
        var value = _seedling.unsafelyUnwrapped
        _seedling = nil
        defer { _seedling = value }
        yield &value
      }
    }
    
    @usableFromInline
    internal var state: State
    
    @usableFromInline
    internal let leafCapacity: Int
    
    @usableFromInline
    internal let internalCapacity: Int
    
    @usableFromInline
    internal let deduplicating: Bool
    
    @usableFromInline
    internal var lastKey: Key?
    
    /// Creates a new B-Tree builder with default capacities
    /// - Parameter deduplicating: Whether duplicates should be removed.
    @inlinable
    @inline(__always)
    internal init(deduplicating: Bool = false) {
      self.init(
        deduplicating: deduplicating,
        leafCapacity: _BTree.defaultLeafCapacity,
        internalCapacity: _BTree.defaultInternalCapacity
      )
    }
    
    /// Creates a new B-Tree builder with a custom uniform capacity configuration
    /// - Parameters:
    ///   - deduplicating: Whether duplicates should be removed.
    ///   - capacity: The amount of elements per node.
    @inlinable
    @inline(__always)
    internal init(deduplicating: Bool = false, capacity: Int) {
      self.init(
        deduplicating: deduplicating,
        leafCapacity: capacity,
        internalCapacity: capacity
      )
    }
    
    /// Creates a new B-Tree builder with a custom capacity configuration
    /// - Parameters:
    ///   - deduplicating: Whether duplicates should be removed.
    ///   - leafCapacity: The amount of elements per leaf node.
    ///   - internalCapacity: The amount of elements per internal node.
    @inlinable
    @inline(__always)
    internal init(
      deduplicating: Bool = false,
      leafCapacity: Int,
      internalCapacity: Int
    ) {
      assert(leafCapacity > 1 && internalCapacity > 1,
             "Capacity must be greater than one")
      
      self._saplings = []
      self._separators = []
      self.state = .appendingToSeedling
      self._seedling = Node(withCapacity: leafCapacity, isLeaf: true)
      self.leafCapacity = leafCapacity
      self.internalCapacity = internalCapacity
      self.deduplicating = deduplicating
      self.lastKey = nil
    }
    
    /// Pops a sapling and it's associated separator
    @inlinable
    @inline(__always)
    internal mutating func popSapling()
      -> (leftNode: Node, separator: Element)? {
      return _saplings.isEmpty ? nil : (
        leftNode: _saplings.removeLast(),
        separator: _separators.removeLast()
      )
    }
    
    /// Appends a sapling with an associated separator
    @inlinable
    @inline(__always)
    internal mutating func appendSapling(
      _ sapling: __owned Node,
      separatedBy separator: Element
    ) {
      _saplings.append(sapling)
      _separators.append(separator)
    }
    
    /// Appends a sequence of sorted values to the tree
    @inlinable
    @inline(__always)
    internal mutating func append<S: Sequence>(
      contentsOf sequence: S
    ) where S.Element == Element {
      for element in sequence {
        self.append(element)
      }
    }
    
    /// Appends a new element to the tree
    /// - Parameter element: Element which is after all previous elements in sorted order.
    @inlinable
    internal mutating func append(_ element: __owned Element) {
      assert(lastKey == nil || lastKey! <= element.key,
             "New element must be non-decreasing.")
      defer { lastKey = element.key }
      if deduplicating {
        if let lastKey = lastKey {
          if lastKey == element.key { return }
        }
      }
      
      switch state {
      case .addingSeparator:
        completeSeedling(withSeparator: element)
        state = .appendingToSeedling

      case .appendingToSeedling:
        let isFull: Bool = seedling.update { handle in
          handle.appendElement(element)
          return handle.isFull
        }
        
        if _slowPath(isFull) {
          state = .addingSeparator
        }
      }
    }
    
    
    
    /// Declares that the current seedling is finished with insertion and creates a new seedling to
    /// further operate on.
    @inlinable
    internal mutating func completeSeedling(
      withSeparator newSeparator: __owned Element
    ) {
      var sapling = Node(withCapacity: leafCapacity, isLeaf: true)
      swap(&sapling, &self.seedling)
      
      // Prepare a new sapling to insert.
      // There are a few invariants we're thinking about here:
      //   - Leaf nodes are coming in fully filled. We can treat them as atomic
      //     bits
      //   - The stack has saplings of decreasing depth.
      //   - Saplings on the stack are completely filled except for their roots.
      if case (var previousSapling, let separator)? = self.popSapling() {
        let saplingDepth = sapling.storage.header.depth
        let previousSaplingDepth = previousSapling.storage.header.depth
        let previousSaplingIsFull = previousSapling.read({ $0.isFull })
        
        assert(previousSaplingDepth >= saplingDepth,
               "Builder invariant failure.")
        
        if saplingDepth == previousSaplingDepth && previousSaplingIsFull {
          // This is when two nodes are full:
          //
          //              ┌───┐   ┌───┐
          //              │ A │   │ C │
          //              └───┘   └───┘
          //                ▲       ▲
          //                │       │
          //      previousSapling  sapling
          //
          // We then use the separator (B) to transform this into a subtree of a
          // depth increase:
          //     ┌───┐
          //     │ B │ ◄─── sapling
          //    ┌┴───┴┐
          //    │     │
          //  ┌─┴─┐ ┌─┴─┐
          //  │ A │ │ C │
          //  └───┘ └───┘
          // If the sapling is full. We create a splinter. This is when the
          // depth of our B-Tree increases
          sapling = _Node(
            leftChild: previousSapling,
            separator: separator,
            rightChild: sapling,
            capacity: internalCapacity
          )
        } else if saplingDepth + 1 == previousSaplingDepth && !previousSaplingIsFull {
          // This is when we can append the node with the separator:
          //
          //     ┌───┐
          //     │ B │ ◄─ previousSapling
          //    ┌┴───┴┐
          //    │     │
          //  ┌─┴─┐ ┌─┴─┐      ┌───┐
          //  │ A │ │ C │      │ E │ ◄─ sapling
          //  └───┘ └───┘      └───┘
          //
          // We then use the separator (D) to append this to previousSapling.
          //      ┌────┬───┐
          //      │  B │ D │   ◄─ sapling
          //     ┌┴────┼───┴┐
          //     │     │    │
          //   ┌─┴─┐ ┌─┴─┐ ┌┴──┐
          //   │ A │ │ C │ │ E │
          //   └───┘ └───┘ └───┘
          previousSapling.update {
            $0.appendElement(separator, withRightChild: sapling)
          }
          sapling = previousSapling
        } else {
          // In this case, we need to work on creating a new sapling. Say we
          // have:
          //
          //      ┌────┬───┐
          //      │  B │ D │ ◄─ previousSapling
          //     ┌┴────┼───┴┐
          //     │     │    │
          //   ┌─┴─┐ ┌─┴─┐ ┌┴──┐     ┌───┐
          //   │ A │ │ C │ │ E │     │ G │ ◄─ sapling
          //   └───┘ └───┘ └───┘     └───┘
          //
          // Where previousSapling is full. We'll commit sapling and keep
          // working on it until it is of the same depth as `previousSapling`.
          // Once it is the same depth, we can join the nodes.
          //
          // The goal is once we have a full tree of equal depth:
          //
          //      ┌────┬───┐           ┌────┬───┐
          //      │  B │ D │           │  H │ J │
          //     ┌┴────┼───┴┐         ┌┴────┼───┴┐
          //     │     │    │         │     │    │
          //   ┌─┴─┐ ┌─┴─┐ ┌┴──┐    ┌─┴─┐ ┌─┴─┐ ┌┴──┐
          //   │ A │ │ C │ │ E │    │ G │ │ I │ │ K │
          //   └───┘ └───┘ └───┘    └───┘ └───┘ └───┘
          //
          // We can string them together using the previous cases.
          self.appendSapling(previousSapling, separatedBy: separator)
        }
      }
      
      self.appendSapling(sapling, separatedBy: newSeparator)
    }
    
    /// Finishes building a tree.
    ///
    /// This consumes the builder and it is no longer valid to operate on after this.
    ///
    /// - Returns: A usable, fully-filled B-Tree
    @inlinable
    internal mutating func finish() -> _BTree {
      var root: Node = seedling
      _seedling = nil
      
      while case (var sapling, let separator)? = self.popSapling() {
        root = _Node.join(
          &sapling,
          with: &root,
          separatedBy: separator,
          capacity: internalCapacity
        )
      }
      
      let tree = _BTree(rootedAt: root, internalCapacity: internalCapacity)
      tree.checkInvariants()
      return tree
    }
  }
}

extension _BTree.Builder where Value == Void {
  /// Appends a value to a B-Tree builder without values.
  @inlinable
  @inline(__always)
  internal mutating func append(_ key: __owned Key) {
    self.append((key, ()))
  }
}
