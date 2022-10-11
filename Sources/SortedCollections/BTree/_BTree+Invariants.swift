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
  #if COLLECTIONS_INTERNAL_CHECKS
  @inline(never)
  @discardableResult
  fileprivate func checkInvariants(
    for node: Node,
    expectedDepth: Int,
    isRoot: Bool = false
  ) -> (
    minimum: Key?,
    maximum: Key?
  ) {
    node.read { handle in
      assert(handle.depth == expectedDepth, "Node depth mismatch.")
      assert(isRoot || handle.elementCount > 0, "Node cannot be empty")
      
      if handle.elementCount > 1 {
        for i in 0..<(handle.elementCount - 1) {
          assert(handle[keyAt: i] <= handle[keyAt: i + 1],
                 "Node keys out of order.")
        }
      }
      
      if handle.isLeaf {
        assert(handle.elementCount == handle.subtreeCount,
               "Element and subtree count should match for leaves.")
        assert(handle.depth == 0, "Non-zero depth for leaf.")
        assert(isRoot || handle.isBalanced, "Unbalanced node.")
        
        if handle.elementCount > 0 {
          return (
            minimum: handle[keyAt: 0],
            maximum: handle[keyAt: handle.elementCount - 1]
          )
        } else {
          return (nil, nil)
        }
      } else {
        var totalCount = 0
        var subtreeMinimum: Key!
        var subtreeMaximum: Key!
        
        for i in 0..<handle.childCount {
          let (
            minimum,
            maximum
          ) = checkInvariants(
            for: handle[childAt: i],
            expectedDepth: expectedDepth - 1
          )
          
          if i == 0 { subtreeMinimum = minimum }
          if i == handle.childCount - 1 { subtreeMaximum = maximum }
          
          if i == handle.childCount - 1 {
            assert(minimum! >= handle[keyAt: i - 1],
                   "Last subtree must be greater than or equal to last key.")
          } else {
            assert(maximum! <= handle[keyAt: i],
                   "Subtree must be less than or equal to corresponding key.")
          }
          
          totalCount += handle[childAt: i].read { $0.subtreeCount }
        }
        
        assert(handle.subtreeCount == handle.elementCount + totalCount,
               "Subtree count mismatch.")
        
        return (
          minimum: subtreeMinimum,
          maximum: subtreeMaximum
        )
      }
    }
  }
  
  @inline(never)
  @usableFromInline
  internal func checkInvariants() {
    checkInvariants(
      for: root,
      expectedDepth: root.storage.header.depth,
      isRoot: true
    )
  }
  #else
  @inlinable
  @inline(__always)
  internal func checkInvariants() {}
  #endif // COLLECTIONS_INTERNAL_CHECKS
}
