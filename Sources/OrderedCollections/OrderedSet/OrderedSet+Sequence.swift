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

extension OrderedSet: Sequence {
  /// The type that allows iteration over an ordered set's elements.
  public typealias Iterator = IndexingIterator<Self>

  @inlinable
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    _find(element).index != nil
  }

  @inlinable
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    _elements._copyToContiguousArray()
  }

  @inlinable
  public __consuming func _copyContents(
    initializing ptr: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    guard !isEmpty else { return (makeIterator(), 0) }
    let copied: Int = _elements.withUnsafeBufferPointer { buffer in
      guard let p = ptr.baseAddress else {
        preconditionFailure("Attempt to copy contents into nil buffer pointer")
      }
      let c = Swift.min(buffer.count, ptr.count)
      p.initialize(from: buffer.baseAddress!, count: c)
      return c
    }
    return (Iterator(_elements: self, _position: copied), copied)
  }

  /// Call `body(p)`, where `p` is a buffer pointer to the collection’s
  /// contiguous storage. Ordered sets always have contiguous storage.
  ///
  /// - Parameter body: A function to call. The function must not escape its
  ///    unsafe buffer pointer argument.
  ///
  /// - Returns: The value returned by `body`.
  ///
  /// - Complexity: O(1) (ignoring time spent in `body`)
  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    try _elements.withContiguousStorageIfAvailable(body)
  }
}
