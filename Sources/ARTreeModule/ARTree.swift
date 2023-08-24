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
//
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
//     - ArtNode* is unmanaged and make its use contained within closures.

/// An ordered collection of unique keys and associated values, optimized for space,
/// mutating shared copies, and efficient range operations, particularly read
/// operations.
///
/// `ARTree` has the same functionality as a standard `Dictionary`, and it largely
/// implements the same APIs. However, `ARTree` is optimized specifically for use cases
/// where underlying keys share common prefixes. The underlying data-structure is a
/// _persistent variant of _Adaptive Radix Tree (ART)_.
public typealias ARTree<Value> = ARTreeImpl<DefaultSpec<Value>>

/// Implements a persistent Adaptive Radix Tree (ART).
public struct ARTreeImpl<Spec: ARTreeSpec> {
  public typealias Spec = Spec
  public typealias Value = Spec.Value

  @usableFromInline
  internal var _root: RawNode?

  @inlinable
  public init() {
    self._root = nil
  }
}
