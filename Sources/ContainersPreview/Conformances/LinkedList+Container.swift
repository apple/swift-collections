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

#if COLLECTIONS_FOUNDATION_TOOLCHAIN_MODULE
import _FoundationCollections
#elseif COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import LinkedListModule
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension LinkedList: Container, PermutableContainer, MutableContainer
where Element: ~Copyable
{}

@available(SwiftStdlib 6.4, *)
extension LinkedList: DrainableContainer
where Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    SubrangeConsumer(_base: &self, subrange: subrange)
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable
{
  @frozen
  @safe
  public struct SubrangeConsumer: ~Copyable, ~Escapable {
    @_alwaysEmitIntoClient
    package var _next: UnsafeMutablePointer<_Node>?

    @_alwaysEmitIntoClient
    package var _prev: UnsafeMutablePointer<_Node>?

    @_alwaysEmitIntoClient
    package var _remaining: Int

    @_alwaysEmitIntoClient
    package var _finalIndex: Index

    @_alwaysEmitIntoClient
    @_lifetime(&_base)
    package init(
      _base: inout LinkedList, subrange: Range<Index>
    ) {
      let r = unsafe _base._extract(subrange)
      self._remaining = unsafe r.count
      self._finalIndex = unsafe r.index
      unsafe self._next = r.first
      unsafe self._prev = nil
    }

    deinit {
      unsafe _prev?.deallocate() // See note in `drainNext` below.
      unsafe _dismantleList(_next)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.SubrangeConsumer: ContainerDrain<Element>
where Element: ~Copyable
{
  public typealias Failure = Never
  public typealias Index = LinkedList.Index

  @_alwaysEmitIntoClient
  public var count: Int {
    _remaining
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func drainNext(maxCount: Int) -> InputSpan<Element> {
    precondition(maxCount > 0, "maxCount must be positive")
    unsafe _prev?.deallocate() // See note below.
    guard let next = unsafe _next else {
      unsafe _prev = nil
      return .init()
    }
    self._remaining &-= 1
    unsafe self._prev = next
    unsafe self._next = exchange(&next.pointee.next, with: nil)
    // Note: the returned InputSpan ensures that the value will be deinitialized
    // before the next `drainNext` invocation, or before `self` is destroyed.
    // We don't need to (and cannot) run `_Node.deinit`, as we've taken over its
    // duties. We just need to deallocate the node after the input span is gone,
    // which we do with the `_prev?.deallocate()` calls above.
    return unsafe next._drainOrphanNode(mutating: &self)
  }

  @_alwaysEmitIntoClient
  public consuming func finalize() -> Index {
    _finalIndex
  }
}
#endif
