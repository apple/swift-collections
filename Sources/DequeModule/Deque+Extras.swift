//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension Deque {
    
    /// Creates a deque with the specified capacity, then executes the given
    /// closure with access to the deque’s uninitialized memory.
    ///
    /// Inside the closure, you are responsible for initializing elements
    /// within the provided buffer and setting the `initializedCount` to the
    /// number of elements that were written. At the end of the closure’s
    /// execution:
    ///
    /// - The memory in the range `buffer[0..<initializedCount]` must be
    ///   initialized.
    /// - The memory in the range `buffer[initializedCount...]` must remain
    ///   uninitialized.
    ///
    /// These conditions must hold even if the closure throws an error.
    ///
    /// - Note: The resulting deque may allocate more capacity than requested,
    ///   but the buffer passed into the closure will always have exactly the
    ///   requested size.
    ///
    /// - Parameters:
    ///   - capacity: The number of elements to allocate space for.
    ///   - initializer: A closure that initializes elements in the buffer and
    ///     updates the deque’s count.
    ///     - Parameters:
    ///       - buffer: A buffer covering uninitialized memory with room for
    ///         exactly `capacity` elements.
    ///       - initializedCount: The number of elements you have initialized.
    ///         This value begins at zero and must be updated by the closure.
    ///
    /// - Complexity: O(`capacity`)
    @inlinable
    public init(
      unsafeUninitializedCapacity capacity: Int,
      initializingWith initializer:
        (inout UnsafeMutableBufferPointer<Element>, inout Int) throws -> Void
    ) rethrows {
      self._storage = .init(minimumCapacity: capacity)
      self._maxCapacity = nil
      try _storage.update { handle in
        handle.startSlot = .zero
        var count = 0
        var buffer = handle.mutableBuffer(for: .zero ..< _Slot(at: capacity))
        defer {
          precondition(count <= capacity,
            "Initialized count set to greater than specified capacity")
          let b = handle.mutableBuffer(for: .zero ..< _Slot(at: capacity))
          precondition(buffer.baseAddress == b.baseAddress && buffer.count == b.count,
            "Initializer relocated Deque storage")
          handle.count = count
        }
        try initializer(&buffer, &count)
      }
    }
}

extension Deque {
  /// Removes and returns the first element of this deque, if it exists.
  ///
  /// - Returns: The first element of the original collection if the collection
  ///    isn't empty; otherwise, `nil`.
  ///
  /// - Complexity: O(1) when this instance has a unique reference to its
  ///    underlying storage; O(`count`) otherwise.
  @inlinable
  public mutating func popFirst() -> Element? {
    // FIXME: Add this to the stdlib on BidirectionalCollection
    // where Self == Self.SubSequence
    guard count > 0 else { return nil }
    _storage.ensureUnique()
    return _storage.update {
      $0.uncheckedRemoveFirst()
    }
  }

    /// Inserts a new element at the front of the deque.
    ///
    /// Use this method to add a single element to the beginning of a deque:
    ///
    ///     var numbers: Deque = [1, 2, 3, 4, 5]
    ///     numbers.prepend(100)
    ///     print(numbers)
    ///     // Prints "[100, 1, 2, 3, 4, 5]"
    ///
    /// A deque grows its capacity using an exponential strategy. This means that
    /// prepending is typically a constant-time operation when averaged over many
    /// calls to `prepend(_:)`. Specifically:
    ///
    /// - If the deque has available capacity and its storage is uniquely held,
    ///   prepending is O(1).
    /// - If the deque needs to reallocate storage or is sharing storage with
    ///   another deque, prepending is O(*count*).
    ///
    /// If the deque has a fixed maximum capacity and is already full, calling
    /// `prepend(_:)` removes the last element before inserting the new one.
    ///
    /// - Parameter newElement: The element to insert at the front of the deque.
    ///
    /// - Complexity: Amortized O(1).
    ///
    /// - SeeAlso: `append(_:)`
    @inlinable
    public mutating func prepend(_ newElement: Element) {
        if let maxCap = _maxCapacity, count >= maxCap {
            _ = removeLast()
        }
        _storage.ensureUnique(minimumCapacity: count + 1)
        return _storage.update {
            $0.uncheckedPrepend(newElement)
        }
    }


  /// Adds the elements of a collection to the front of the deque.
  ///
  /// Use this method to prepend the elements of a collection to the front of
  /// this deque. This example prepends the elements of a `Range<Int>` instance
  /// to a deque of integers.
  ///
  ///     var numbers: Deque = [1, 2, 3, 4, 5]
  ///     numbers.prepend(contentsOf: 10...15)
  ///     print(numbers)
  ///     // Prints "[10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]"
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: Amortized O(`newElements.count`).
  ///
  /// - SeeAlso: `append(contentsOf:)`
  @inlinable
  public mutating func prepend(
    contentsOf newElements: some Collection<Element>
  ) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      _storage.ensureUnique(minimumCapacity: count + source.count)
      _storage.update { $0.uncheckedPrepend(contentsOf: source) }
    }
    guard done == nil else { return }

    let c = newElements.count
    guard c > 0 else { return }
    _storage.ensureUnique(minimumCapacity: count + c)
    _storage.update { target in
      let gaps = target.availableSegments().suffix(c)
      gaps.initialize(from: newElements)
      target.count += c
      target.startSlot = target.slot(target.startSlot, offsetBy: -c)
    }
  }

  /// Adds the elements of a sequence to the front of the deque.
  ///
  /// Use this method to prepend the elements of a sequence to the front of this
  /// deque. This example prepends the elements of a `Range<Int>` instance to a
  /// deque of integers.
  ///
  ///     var numbers: Deque = [1, 2, 3, 4, 5]
  ///     numbers.prepend(contentsOf: 10...15)
  ///     print(numbers)
  ///     // Prints "[10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]"
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: Amortized O(`newElements.count`).
  ///
  /// - SeeAlso: `append(contentsOf:)`
  @inlinable
  public mutating func prepend(contentsOf newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      _storage.ensureUnique(minimumCapacity: count + source.count)
      _storage.update { $0.uncheckedPrepend(contentsOf: source) }
    }
    guard done == nil else { return }

    let originalCount = self.count
    self.append(contentsOf: newElements)
    let newCount = self.count
    let c = newCount - originalCount
    _storage.update { target in
      target.startSlot = target.slot(forOffset: originalCount)
      target.count = target.capacity
      target.closeGap(offsets: c ..< c + (target.capacity - newCount))
      assert(target.count == newCount)
    }
  }
}
