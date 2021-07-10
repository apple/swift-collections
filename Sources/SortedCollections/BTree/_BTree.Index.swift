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
  @usableFromInline
  internal struct Index: Comparable {
    /// The path to the element in the BTree. A `nil` value indicates
    /// the endIndex
    @usableFromInline
    internal var path: UnsafePath?
    
    /// The tree that this index references.
    @usableFromInline
    internal weak var root: Node.Storage?
    
    /// The age of the tree when this index was captures.
    @usableFromInline
    internal let age: Int32
    
    // TODO: optimize this to potentially avoid capturing a weak
    // reference for `nil` or endIndex by using another mechanism
    // to perform validity checks.
    @inlinable
    @inline(__always)
    internal init(_ path: UnsafePath?, forTree tree: _BTree) {
      self.path = path
      self.root = tree.root.storage
      self.age = tree.age
    }
    
    @inlinable
    @inline(__always)
    internal static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs.path?.node === rhs.path?.node
    }
    
    @inlinable
    @inline(__always)
    internal static func <(lhs: Index, rhs: Index) -> Bool {
      switch (lhs.path, rhs.path) {
      case let (lhsPath?, rhsPath?):
        return lhsPath < rhsPath
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      case (nil, nil):
        return false
      }
    }
    
    /// Ensures the precondition that the index is valid for a given dictionary.
    @inlinable
    @inline(__always)
    internal func ensureValid(for tree: _BTree) {
      precondition(
        self.root === tree.root.storage && self.age == tree.age,
        "Attempt to use an invalid index.")
    }
    
    /// Ensures the precondition that the index is valid for use with another index
    @inlinable
    @inline(__always)
    internal func ensureValid(with index: Index) {
      precondition(
        self.root != nil && self.root === index.root && self.age == index.age,
        "Attempt to use an invalid indices.")
    }
  }
}
