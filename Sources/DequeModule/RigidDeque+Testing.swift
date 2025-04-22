//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension RigidDeque where Element: ~Copyable {
  /// True if consistency checking is enabled in the implementation of this
  /// type, false otherwise.
  ///
  /// Documented performance promises are null and void when this property
  /// returns true -- for example, operations that are documented to take
  /// O(1) time might take O(*n*) time, or worse.
  public static var _isConsistencyCheckingEnabled: Bool {
    _isCollectionsInternalCheckingEnabled
  }

  /// The number of the storage slot in this deque that holds the first element.
  /// (Or would hold it after an insertion in case the deque is currently
  /// empty.)
  ///
  /// This property isn't intended to be used outside of `RigidDeque`'s own test
  /// target.
  package var _unstableStartSlot: Int {
    _handle.startSlot.position
  }

  /// Constructs a deque instance of the specified contents and layout. Exposed
  /// as public to allow exhaustive input/output tests for `RigidDeque`'s members.
  /// This isn't intended to be used outside of `RigidDeque`'s own test target.
  package init(
    _capacity capacity: Int,
    startSlot: Int,
    count: Int,
    generator: (Int) -> Element
  ) {
    let startSlot = _Slot(at: startSlot)
    self.init(_handle: .allocate(capacity: capacity, startSlot: startSlot, count: count, generator: generator))
    assert(self._unstableStartSlot == startSlot.position)
    assert(self.count == count)
  }
}
