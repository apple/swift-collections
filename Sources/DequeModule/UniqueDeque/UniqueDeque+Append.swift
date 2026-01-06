//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
extension UniqueDeque where Element: ~Copyable {
  /// Adds an element to the end of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1) as amortized over many invocations on the same deque.
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func append(_ newElement: consuming Element) {
    _ensureFreeCapacity(1)
    _storage._handle.uncheckedAppend(newElement)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items
  /// in the source buffer, then this automatically grows the deque's
  /// capacity, using a geometric growth rate.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.append(copying: newElements)
  }

  /// Copies the elements of a buffer to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to extend its capacity, using
  /// a geometric growth rate.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(newElements))
  }

  /// Copies the elements of a span to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: Span<Element>) {
    _ensureFreeCapacity(newElements.count)
    _storage.append(copying: newElements)
  }

  /// Copies the elements of a sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to extend its capacity, using
  /// a geometric growth rate. If the input sequence does not provide a correct
  /// estimate of its count, then the deque's storage may need to be resized
  /// more than once.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`, when
  ///     amortized over many invocations over the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      _ensureFreeCapacity(buffer.count)
      unsafe _storage.append(copying: buffer)
      return
    }
    if done != nil { return }

    _ensureFreeCapacity(newElements.underestimatedCount)
    var it = _storage._handle.uncheckedAppend(copyingPrefixOf: newElements)
    while let item = it.next() {
      _ensureFreeCapacity(1)
      _storage.append(item)
    }
  }
}

#endif
