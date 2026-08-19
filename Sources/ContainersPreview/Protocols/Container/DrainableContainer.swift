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

#if compiler(>=6.4) && UnstableContainersPreview

//MARK: - Protocol Definition

@available(SwiftStdlib 6.4, *)
public protocol DrainableContainer<Element>
: Container, ~Copyable, ~Escapable
where
  Element: ~Copyable,
  Index: Comparable // For `Range<Index>`
{
  // MARK: Core requirements

  associatedtype SubrangeConsumer: Drain<Element> & ~Copyable & ~Escapable

  @_lifetime(&self)
  mutating func consume(_ subrange: Range<Index>) -> SubrangeConsumer

  // FIXME: `removeAll(where:)`
  // FIXME: `consumeAll(where:)`?
  // These should ideally be using SubrangeConsumer, but that requires Drain
  // to support partial consumption -- a large complication.

  // MARK: Requirements with default implementations

  mutating func remove(at index: Index) -> Element
  mutating func removeSubrange(_ bounds: Range<Index>)
  mutating func removeAll()
  mutating func removeFirst() -> Element
  mutating func removeFirst(_ n: Int)
  mutating func _customRemoveLast() -> Element?
  mutating func _customRemoveLast(_ n: Int) -> Bool
}

//MARK: - Default Implementations

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func remove(at index: Index) -> Element {
    let range = Range(uncheckedBounds: (index, self.index(after: index)))
    var result: Element?
    self.consume(range) {
      result = $0.removeFirst()
    }
    guard let result else {
      preconditionFailure("Invalid RangeReplaceableContainer")
    }
    return result
  }

  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _ = consume(bounds)
  }

  @_alwaysEmitIntoClient
  public mutating func removeFirst() -> Element {
    precondition(
      !isEmpty,
      "Can't remove first element from an empty container")
    return self.remove(at: self.startIndex)
  }

  @_alwaysEmitIntoClient
  public mutating func removeFirst(_ n: Int) {
    if n == 0 { return }
    precondition(n >= 0, "Number of elements to remove should be non-negative")
    let start = self.startIndex
    guard
      let end = self.index(start, offsetBy: n, limitedBy: endIndex)
        else {
      preconditionFailure(
        "Can't remove more items from a container than it has")
    }
    removeSubrange(start ..< end)
  }

  @_alwaysEmitIntoClient
  public mutating func _customRemoveLast() -> Element? {
    nil
  }

  @_alwaysEmitIntoClient
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    false
  }
}

//MARK: - Standard Extensions

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func consume(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    var drain = self.consume(subrange)
    while true {
      var chunk = drain.drainNext()
      guard !chunk.isEmpty else { break }
      consumer(&chunk)
    }
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeAll() -> SubrangeConsumer {
    consume(startIndex ..< endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: some RangeExpression2<Index>
  ) -> SubrangeConsumer {
    consume(subrange.relative(to: self))
  }

  // This unavailable default implementation of the protocol requirement
  // prevents incomplete RangeReplaceableContainer implementations from
  // satisfying the protocol through the use of the generic algorithm above.
  @available(*, unavailable)
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consume(_ subrange: Range<Index>) -> SubrangeConsumer {
    fatalError()
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: UnboundedRange
  ) -> SubrangeConsumer {
    consume(startIndex ..< endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeFirst(_ n: Int) -> SubrangeConsumer {
    precondition(n >= 0, "Count of elements to consume is out of bounds")
    let start = self.startIndex
    var i = start
    var n = n
    self.formIndex(&i, offsetBy: &n, limitedBy: self.endIndex)
    precondition(n == 0, "Count of elements to consume is out of bounds")
    return consume(start ..< i)
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where
  Self: BidirectionalContainer,
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeLast(_ n: Int) -> SubrangeConsumer {
    precondition(n >= 0, "Count of elements to consume is out of bounds")
    let end = self.endIndex
    var i = end
    var distance = -n
    self.formIndex(&i, offsetBy: &distance, limitedBy: self.startIndex)
    precondition(distance == 0, "Count of elements to consume is out of bounds")
    return consume(i ..< end)
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func removeAll() {
    removeSubrange(startIndex ..< endIndex)
  }

  @_alwaysEmitIntoClient
  public mutating func removeSubrange(
    _ bounds: some RangeExpression2<Index>
  ) {
    removeSubrange(bounds.relative(to: self))
  }

  @_alwaysEmitIntoClient
  public mutating func removeSubrange(
    _ bounds: UnboundedRange
  ) {
    removeAll()
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: BidirectionalContainer & ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func removeLast() -> Element {
    precondition(
      !self.isEmpty,
      "Can't remove last element from an empty container")
    if let result = self._customRemoveLast() { return result }
    return self.remove(at: self.index(before: self.endIndex))
  }

  @_alwaysEmitIntoClient
  public mutating func removeLast(_ n: Int) {
    if n == 0 { return }
    precondition(n >= 0, "Number of elements to remove should be non-negative")
    if self._customRemoveLast(n) {
      return
    }
    let end = self.endIndex
    guard let start = self.index(end, offsetBy: -n, limitedBy: self.startIndex)
    else {
      preconditionFailure(
        "Can't remove more items from a collection than it contains")
    }
    self.removeSubrange(start ..< end)
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: BidirectionalContainer & ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    if self.isEmpty { return nil }
    if let result = self._customRemoveLast() { return result }
    return self.remove(at: self.index(before: self.endIndex))
  }
}


#endif
