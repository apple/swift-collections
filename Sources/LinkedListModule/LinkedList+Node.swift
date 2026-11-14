//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4)

@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @safe
  @usableFromInline
  @frozen
  @_addressableForDependencies
  package struct _Node: ~Copyable {
    @usableFromInline
    package var next: UnsafeMutablePointer<_Node>?

    // FIXME: This _really_ should not be optional; but we can't decompose
    // noncopyable structs, so that would make it impossible to remove
    // an element from a list.
    @usableFromInline
    package var _value: Element?

    @_alwaysEmitIntoClient
    @_transparent
    package init(
      _ value: consuming Element,
      next: UnsafeMutablePointer<_Node>? = nil
    ) {
      unsafe self.next = next
      self._value = consume value
    }

    deinit {
      unsafe _dismantleList(self.next)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList._Node where Element: ~Copyable {
  @_alwaysEmitIntoClient
  package static func allocate(
    _ value: consuming Element,
    next: UnsafeMutablePointer<Self>? = nil
  ) -> UnsafeMutablePointer<Self> {
    let new = UnsafeMutablePointer<Self>.allocate(capacity: 1)
    unsafe new.initialize(to: Self(value, next: next))
    return unsafe new
  }

  @_alwaysEmitIntoClient
  package var span: Span<Element> {
    @_transparent
    @_lifetime(borrow self)
    get {
      _value._span
    }
  }

  @_alwaysEmitIntoClient
  package var mutableSpan: MutableSpan<Element> {
    @_transparent
    @_lifetime(&self)
    mutating get {
      _value._mutableSpan
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  package consuming func deconstruct() -> Element {
    unsafe assert(next == nil)
    return self._value.take()._consumingUnsafelyUnwrap()
  }
}

#endif
