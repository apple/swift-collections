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

// This file contains exported but non-public entry points to support clear box
// testing.

extension Deque {
  /// True if consistency checking is enabled in the implementation of this
  /// type, false otherwise.
  ///
  /// Documented performance promises are null and void when this property
  /// returns true -- for example, operations that are documented to take
  /// O(1) time might take O(*n*) time, or worse.
  public static var _isConsistencyCheckingEnabled: Bool {
    _isCollectionsInternalCheckingEnabled
  }

  /// The maximum number of elements this deque is currently able to store
  /// without reallocating its storage buffer.
  ///
  /// This information isn't exposed as public, as the returned value isn't
  /// guaranteed to be stable, and may even differ between equal deques,
  /// violating value semantics.
  ///
  /// This property isn't intended to be used outside of `Deque`'s own test
  /// target.
  @_spi(Testing)
  public var _unstableCapacity: Int {
    _capacity
  }

  /// The number of the storage slot in this deque that holds the first element.
  /// (Or would hold it after an insertion in case the deque is currently
  /// empty.)
  ///
  /// This property isn't intended to be used outside of `Deque`'s own test
  /// target.
  @_spi(Testing)
  public var _unstableStartSlot: Int {
    _storage.value._handle.startSlot.position
  }

  /// Constructs a deque instance of the specified contents and layout. Exposed
  /// as public to allow exhaustive input/output tests for `Deque`'s members.
  /// This isn't intended to be used outside of `Deque`'s own test target.
  @_spi(Testing)
  public init(
    _capacity capacity: Int,
    startSlot: Int,
    contents: some Sequence<Element>
  ) {
    let contents = ContiguousArray(contents)
    let d = RigidDeque<Element>(
      _capacity: capacity,
      startSlot: startSlot,
      count: contents.count
    ) { contents[$0] }
    self.init(_storage: d)
    assert(self._unstableCapacity == capacity)
    assert(self._unstableStartSlot == startSlot)
    assert(self.count == contents.count)
  }
}
