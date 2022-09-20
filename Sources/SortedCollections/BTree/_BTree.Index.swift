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
  
  /// An index to an element of the BTree represented as a path.
  /// - Warning: This has the capability to perform safety checks, however they must be explicitly be
  ///     performed using the validation methods.
  @usableFromInline
  internal struct Index {
    /// A fixed-size array large enough to represent all offsets within a B-Tree index
    @usableFromInline
    internal typealias Offsets = _FixedSizeArray<Slot>
    
    /// The position of each of the parent nodes in their parents. The path's depth
    /// is offsets.count + 1
    @usableFromInline
    internal var childSlots: Offsets
    
    /// The bottom most node that the index point to
    ///
    /// This is equal to `root` to indicate the `endIndex`
    @usableFromInline
    internal var node: Unmanaged<Node.Storage>
    
    /// The slot within the bottom most node which the index points to.
    ///
    /// This is equal to `-1` to indicate the `endIndex`
    @usableFromInline
    internal var slot: Int
    
    /// The absolute offset of the path's element in the entire tree.
    @usableFromInline
    internal var offset: Int
    
    /// The tree that this index references.
    @usableFromInline
    internal weak var root: Node.Storage?
    
    /// The age of the tree when this index was captures.
    @usableFromInline
    internal let version: Int
    
    /// Creates an index represented as a sequence of nodes to an element.
    /// - Parameters:
    ///   - node: The node to which this index points.
    ///   - slot: The specific slot within node where the path points
    ///   - childSlots: The children's offsets for this path.
    ///   - index: The absolute offset of this path's element in the tree.
    ///   - tree: The tree of this index.
    @inlinable
    @inline(__always)
    internal init(
      node: Unmanaged<Node.Storage>,
      slot: Int,
      childSlots: Offsets,
      offset: Int,
      forTree tree: _BTree
    ) {
      self.node = node
      self.slot = slot
      self.childSlots = childSlots
      self.offset = offset
      
      self.root = tree.root.storage
      self.version = tree.version
    }
    
    
    // MARK: Index Validation
    /// Ensures the precondition that the index is valid for a given dictionary.
    @inlinable
    @inline(__always)
    internal func ensureValid(forTree tree: _BTree) {
      precondition(
        self.root === tree.root.storage && self.version == tree.version,
        "Attempt to use an invalid index.")
    }
    
    /// Ensures the precondition that the index is valid for use with another index
    @inlinable
    @inline(__always)
    internal func ensureValid(with index: Index) {
      precondition(
        self.root != nil &&
          self.root === index.root &&
          self.version == index.version,
        "Attempt to use an invalid indices.")
    }
  }
}

// MARK: Index Read Operations
extension _BTree.Index {
  /// Operators on a handle of the node
  /// - Warning: Ensure this is never called on an endIndex.
  @inlinable
  @inline(__always)
  internal func readNode<R>(
    _ body: (_BTree.Node.UnsafeHandle) throws -> R
  ) rethrows -> R {
    assert(self.slot != -1, "Invalid operation to read end index.")
    return try self.node._withUnsafeGuaranteedRef { try $0.read(body) }
  }
  
  /// Gets the element the path points to.
  @inlinable
  @inline(__always)
  internal var element: _BTree.Element {
    assert(self.slot != -1, "Cannot dereference out-of-bounds slot.")
    return self.readNode { $0[elementAt: self.slot] }
  }
}

// MARK: Comparable
extension _BTree.Index: Comparable {
  /// Returns true if two indices are identical (point to the same node).
  /// - Precondition: expects both indices are from the same B-Tree.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  internal static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.offset == rhs.offset
  }
  
  /// Returns true if the first path points to an element before the second path
  /// - Precondition: expects both indices are from the same B-Tree.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  internal static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs.offset < rhs.offset
  }
}
