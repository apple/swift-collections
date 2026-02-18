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

// This file contains exported but non-public entry points to support clear box
// testing.

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// The number of the storage slot in this deque that holds the first element.
  /// (Or would hold it after an insertion in case the deque is currently
  /// empty.)
  ///
  /// This property isn't intended to be used outside of `DequeModule`'s own test
  /// target.
  @usableFromInline
  package var _startSlot: Int {
    _handle.startSlot.position
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque {
  /// Constructs a deque instance of the specified contents and layout. Exposed
  /// as public to allow exhaustive input/output tests for `RigidDeque` members.
  ///
  /// This initializer isn't intended to be used outside of `DequeModule`'s
  /// own test target.
  @usableFromInline
  package init(
    _capacity capacity: Int,
    startSlot: Int,
    copying contents: some Sequence<Element>
  ) {
    let contents = Array(contents)
    
    self.init(capacity: capacity)
    _handle.startSlot = _handle.slot(_handle.startSlot, offsetBy: startSlot)
    self.append(copying: contents)
    assert(self.capacity == capacity)
    assert(self._startSlot == startSlot)
    assert(self.count == contents.count)
  }
}

#endif
