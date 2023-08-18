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

// TODO:
// * Check deallocate of nodes.
// * Path compression when deleting.
// * Range delete.
// * Delete node should delete all sub-childs (for range deletes)
// * Confirm to Swift Dictionary/Iterator protocols.
// * Fixed sized array.
// * Generic/any serializable type?
// * Binary search Node16.
// * SIMD instructions for Node4.
// * Replace some loops with memcpy.
// * Better test cases.
// * Fuzz testing.
// * Leaf don't need to store entire key.
// * Memory safety in Swift?
// * Values should be whatever.

public struct ARTree<Value> {
  var root: RawNode?

  public init() {
    self.root = RawNode(from: Node4.allocate())
  }
}
