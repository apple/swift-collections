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
  /// Represents a specific element in a BTree. This holds strong references to the
  /// element it points to.
  /// - Warning: Operations on this path will trap if the underlying node is deallocated.
  ///   and they become invalid if the tree is mutated, however this is not checked. For
  ///   safety, use ``_BTree.Index`` instead
  @usableFromInline
  internal struct UnsafePath {
    @usableFromInline
    internal struct PackedOffsetList {
      @usableFromInline
      internal var depth: UInt8
      
      @usableFromInline
      internal var offsets: UInt64
      
      @inlinable
      @inline(__always)
      internal init() {
        self.depth = 0
        self.offsets = 0
      }
      
      @inlinable
      @inline(__always)
      internal mutating func pop() {
        assert(depth != 0, "Attempted to ascend from root path.")
        self.depth &-= 1
      }
      
      @inlinable
      @inline(__always)
      internal mutating func move(by slots: UInt16) {
        let level: UInt8 = depth << 4
        let mask: UInt64 = UInt64(0xFFFF) << level
        
        var oldSlot = (offsets & mask) >> level
        oldSlot &+= UInt64(slots)
        
        offsets = (offsets & ~mask) | (oldSlot << level)
      }
      
      @inlinable
      @inline(__always)
      internal mutating func child(at slot: UInt16) {
        assert(depth != 3, "Attempted to exceed maximum depth.")
        depth &+= 1
        
        let level: UInt8 = depth << 4
        let mask: UInt64 = UInt64(0xFFFF) << level
        
        offsets = (offsets & ~mask) | (UInt64(slot) << level)
      }
    }
    
    // TODO: potentially make compact (U)Int8/16 type to be more compact
    /// The position of each of the parent nodes in their parents. The path's depth
    /// is offsets.count + 1
    @usableFromInline
    internal var childSlots: Array<Int>
    
    @usableFromInline
    internal unowned(unsafe) var node: Node.Storage
    
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
      childSlots: Array<Int>,
      offset: Int) {
      self.init(node: node.storage, slot: slot, childSlots: childSlots, offset: offset)
    }
    
    /// Creates a path representing a sequence of nodes to an element.
    /// - Parameters:
    ///   - node: The node to which this path points.
    ///   - slot: The specific slot within node where the path points
    ///   - parents: The parent nodes and their children's offsets for this path.
    ///   - index: The absolute offset of this path's element in the tree.
    @inlinable
    internal init(
      node: Node.Storage,
      slot: Int,
      childSlots: Array<Int>,
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
      return Node(self.node).read { $0[elementAt: self.slot] }
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
    return lhs.node === rhs.node && lhs.slot == rhs.slot
  }
}

// MARK: Comparable
extension _BTree.UnsafePath: Comparable {
  /// Returns true if the first path points to an element before the second path
  /// - Complexity: O(`log n`)
  @inlinable
  public static func <(lhs: _BTree.UnsafePath, rhs: _BTree.UnsafePath) -> Bool {
    for i in 0..<min(lhs.childSlots.count, rhs.childSlots.count) {
      if lhs.childSlots[i] < rhs.childSlots[i] {
        return true
      }
    }
    
    if lhs.childSlots.count < rhs.childSlots.count {
      let rhsOffset = rhs.childSlots[lhs.childSlots.count - 1]
      return lhs.slot < rhsOffset
    } else if rhs.childSlots.count < lhs.childSlots.count {
      let lhsOffset = lhs.childSlots[rhs.childSlots.count - 1]
      return lhsOffset <= rhs.slot
    } else {
      return lhs.slot < rhs.slot
    }
  }
}
