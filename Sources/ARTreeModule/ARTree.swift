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
// * Range delete.
// * Delete node should delete all sub-childs (for range deletes)
// * Confirm to Swift dictionary protocols.
// * Generic/any serializable type?
// * Binary search Node16.
// * SIMD instructions for Node4.
// * Replace some loops with memcpy.
// * Better test cases.
// * Fuzz testing.
// * Leaf don't need to store entire key.

public typealias ARTree<Value> = ARTreeImpl<DefaultSpec<Value>>

public struct ARTreeImpl<Spec: ARTreeSpec> {
  public typealias Spec = Spec
  public typealias Value = Spec.Value

  var root: RawNode?

  public init() {
    self.root = Node4<Spec>.allocate().read { $0.rawNode }
  }
}
