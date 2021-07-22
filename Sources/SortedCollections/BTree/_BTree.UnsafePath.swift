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

// TODO: add 0 key validations
// TODO: potentially make operations mutating.

extension _BTree {
  /// Represents a specific element in a BTree. This does not hold any references to the
  /// element it points to.
  /// - Warning: Operations on this path will trap if the underlying node is deallocated.
  ///   and they become invalid if the tree is mutated, however this is not checked. For
  ///   safety, use ``_BTree.Index`` instead with its validation methods.
  @usableFromInline
  internal struct UnsafePath {
    @usableFromInline
    internal typealias Offsets = FixedSizeArray<UInt16>
    
    /// The position of each of the parent nodes in their parents. The path's depth
    /// is offsets.count + 1
    @usableFromInline
    internal var childSlots: Offsets
    
    @usableFromInline
    internal var node: Unmanaged<Node.Storage>
    
    @usableFromInline
    internal var slot: Int
    
    /// The absolute offset of the path's element in the entire tree
    @usableFromInline
    internal var offset: Int
    
    // MARK: Validation
    #if COLLECTIONS_INTERNAL_CHECKS
    @inline(never)
    @usableFromInline
    internal func validatePath() {
      precondition(slot >= 0, "Slot must be non-negative integer")
    }
    
    #else
    @inlinable
    @inline(__always)
    internal func validatePath() {}
    #endif // COLLECTIONS_INTERNAL_CHECKS
    
    
    // MARK: Path Initializers
    
    /// Creates a path representing a sequence of nodes to an element.
    /// - Parameters:
    ///   - node: The node to which this path points. 
    ///   - slot: The specific slot within node where the path points
    ///   - parents: The parent nodes and their children's offsets for this path.
    ///   - index: The absolute offset of this path's element in the tree.
    @inlinable
    internal init(
      node: Node,
      slot: Int,
      childSlots: Offsets,
      offset: Int
    ) {
      self.init(node: .passUnretained(node.storage), slot: slot, childSlots: childSlots, offset: offset)
    }
    
    /// Creates a path representing a sequence of nodes to an element.
    /// - Parameters:
    ///   - node: The node to which this path points.
    ///   - slot: The specific slot within node where the path points
    ///   - parents: The parent nodes and their children's offsets for this path.
    ///   - index: The absolute offset of this path's element in the tree.
    @inlinable
    internal init(
      node: Unmanaged<Node.Storage>,
      slot: Int,
      childSlots: Offsets,
      offset: Int
    ) {
      self.node = node
      self.slot = slot
      self.childSlots = childSlots
      self.offset = offset
      
      validatePath()
    }
    
    /// Gets the element the path points to.
    @inlinable
    @inline(__always)
    internal var element: Element {
      self.readNode { $0[elementAt: self.slot] }
    }
    
    /// Operators on a handle of the node
    @inlinable
    @inline(__always)
    internal func readNode<R>(
      _ body: (Node.UnsafeHandle) throws -> R
    ) rethrows -> R {
      return try self.node._withUnsafeGuaranteedRef { try $0.read(body) }
    }
  }
}

// MARK: Equatable
extension _BTree.UnsafePath: Equatable {
  /// Returns true if two paths are identical (point to the same node).
  /// - Precondition: expects both paths are from the same BTree.
  /// - Complexity: O(1)
  @inlinable
  public static func ==(lhs: _BTree.UnsafePath, rhs: _BTree.UnsafePath) -> Bool {
    // We assume the parents are the same
    return lhs.node.toOpaque() == rhs.node.toOpaque() && lhs.slot == rhs.slot
  }
}

// MARK: Comparable
extension _BTree.UnsafePath: Comparable {
  /// Returns true if the first path points to an element before the second path
  /// - Complexity: O(1)
  @inlinable
  public static func <(lhs: _BTree.UnsafePath, rhs: _BTree.UnsafePath) -> Bool {
    return lhs.offset < rhs.offset
  }
}
