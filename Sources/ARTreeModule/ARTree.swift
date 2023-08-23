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
// - Ranged Operations
//     - Subsequence Delete
//     - Subsequence Iteration
// - Bulk insert
// - Merge operation
// - Disk-backed storage
// - Confirm to Swift Dictionary protocol
// - Optimizations
//     - SIMD for Node4
//     - Binary Search for Node16
//     - Replace for loops with memcpy
//     - Reduce refcount traffic
//     - Leaf shouldn’t store entire key
// - Testing
//     - Tests around edge cases in general
//     - Tests around prefixes greater than maxPrefixLimit
//     - Fuzz testing
// - Instrumentation and Profiling
//     - Track number of allocations and deallocations
//     - Write some performance benchmarks to compare against other data-structures
//         - Use some well known datasets
//     - Cost of dynamic dispatch
// - Refactoring and Maintenance 
//     - Documentation
//     - Add assert to ensure invariants
//     - Safer use of unmanaged objects
//     - Potentially refactor to use FixedSizeArray and hence classes

public struct ARTreeImpl<Spec: ARTreeSpec> {
  public typealias Spec = Spec
  public typealias Value = Spec.Value

  internal var root: RawNode?

  public init() {
    self.root = nil
  }
}

/// A
public typealias ARTree<Value> = ARTreeImpl<DefaultSpec<Value>>
