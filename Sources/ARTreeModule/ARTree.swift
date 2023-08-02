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
  var root: NodePtr?

  public init() {
    self.root = Node4.allocate().pointer
  }
}
