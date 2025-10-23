//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedAppend(_ newElement: consuming Element) {
    _handle.uncheckedAppend(newElement)
  }

  /// Adds an element to the end of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func append(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque is full")
    uncheckedAppend(newElement)
  }

  /// Adds an element to the end of the deque, if possible.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this returns the given item without appending it; otherwise it
  /// returns nil.
  ///
  /// - Parameter item: The element to append to the collection.
  /// - Returns: `item` if the deque is full; otherwise nil.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func pushLast(_ item: consuming Element) -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isFull { return item }
    append(item)
    return nil
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidDeque capacity overflow")
    guard newElements.count > 0 else { return }
    _handle.uncheckedAppend(contentsOf: newElements)
  }

  /// Copies the elements of a buffer to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///        the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(items))
  }

  /// Copies the elements of a span to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(copying items: Span<Element>) {
    unsafe items.withUnsafeBufferPointer { source in
      unsafe self.append(copying: source)
    }
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func _append<S: Sequence<Element>>(
    prefixOf items: S
  ) -> S.Iterator {
    let (it, c) = _handle.availableSegments().initialize(fromSequencePrefix: items)
    _handle.count += c
    return it
  }

  /// Copies the elements of a sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      unsafe self.append(copying: buffer)
      return
    }
    if done != nil { return }

    var it = self._append(prefixOf: newElements)
    precondition(it.next() == nil, "RigidDeque capacity overflow")
  }
}

#endif
