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
extension LinkedList: Container, PermutableContainer
where Element: ~Copyable
{}

#if false // FIXME: Implement. Implementing drainNext is tricky
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable
{
  @frozen
  @safe
  public struct SubrangeConsumer: ~Copyable, ~Escapable {
    @_alwaysEmitIntoClient
    package var _next: UnsafeMutablePointer<_Node>?

    @_alwaysEmitIntoClient
    package var _remaining: Int

    deinit {
      unsafe _dismantleList(_next)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.SubrangeConsumer: ContainerDrain<Element>
where Element: ~Copyable
{
  public typealias Failure = Never

  @_alwaysEmitIntoClient
  public var count: Int {
    _remaining
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func drainNext(maxCount: Int) -> InputSpan<Element> {

  }

  @_alwaysEmitIntoClient
  public consuming func finalize() -> LinkedList.Index {

  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList: DrainableContainer
where Element: ~Copyable
{
}
#endif
#endif
