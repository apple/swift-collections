Adaptive Radix Tree
===================

Todo
----

- Ranged Operations
  - Subsequence Delete
  - Subsequence Iteration
- Bulk insert
- Merge operation
- Disk-backed storage
- Confirm to Swift Collections protocol
  - Implement non-owning Index/UnsafePath for ARTree
  - Use Index/UnsafePath for sequence implementation
- Optimizations
  - SIMD for Node4
  - Binary Search for Node16
  - Replace for loops with memcpy
  - Reduce refcount traffic
    - Leaf shouldn’t store entire key
- Testing
  - Tests around edge cases in general
  - Tests around prefixes greater than maxPrefixLimit
  - Reuse some existing tests from other collections
  - Use test assertion library in swift-collections
  - Fuzz testing
- Instrumentation and Profiling
  - Track number of allocations and deallocations
  - Write some performance benchmarks to compare against other data-structures
    - Use some well known datasets
    - Cost of dynamic dispatch
- Refactoring and Maintenance
  - Documentation
  - Add assert to ensure invariants
  - Safer use of unmanaged objects. Be more specific about ownership
  - Potentially refactor to use FixedSizeArray and hence classes
  - ArtNode* is unmanaged and make its use contained within closures
