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
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

//MARK: - Protocol Definition

@available(SwiftStdlib 6.4, *)
public protocol DrainableContainer<Element>
: Container, ~Copyable, ~Escapable
where Element: ~Copyable {
  // MARK: Core requirements

  associatedtype SubrangeConsumer:
    ContainerDrain<Element> & ~Copyable & ~Escapable
  where SubrangeConsumer.Index == Index

  @_lifetime(&self)
  mutating func consumeSubrange(_ subrange: Range<Index>) -> SubrangeConsumer

  // FIXME: `consumeAll(where:)`
  // FIXME: `removeAll(where:)`
  // These should ideally be using SubrangeConsumer, but that requires Drain
  // to support partial consumption -- a large complication.

  // MARK: Requirements with default implementations

  /// Removes and returns the element at the specified position.
  ///
  /// - Parameter index: The position of the element to remove. `index` must be
  ///   a valid index that is not equal to the end index.
  ///   On return, `index` is updated to address the position following the
  ///   removed element.
  /// - Returns: The removed element.
  @discardableResult
  mutating func remove(at index: inout Index) -> Element

  @discardableResult
  mutating func consumeSubrange(
    _ bounds: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index

  @discardableResult
  mutating func removeSubrange(_ bounds: Range<Index>) -> Index

  mutating func removeAll()

  mutating func removeFirst(_ n: Int)

  mutating func _customRemoveLast() -> Element?

  @_lifetime(&self)
  mutating func _customConsumeLast(_ n: Int) -> SubrangeConsumer?

  mutating func _customRemoveLast(_ n: Int) -> Bool
}

//MARK: - Default Implementations

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func remove(at index: inout Index) -> Element {
    let range = Range(uncheckedBounds: (index, self.index(after: index)))
    var result: Element?
    index = self.consumeSubrange(range) {
      result = $0.removeFirst()
    }
    guard let result else {
      preconditionFailure("Invalid RangeReplaceableContainer")
    }
    return result
  }

  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func removeSubrange(_ bounds: Range<Index>) -> Index {
    consumeSubrange(bounds) { _ in }
  }

  @_alwaysEmitIntoClient
  public mutating func removeAll() {
    removeSubrange(startIndex ..< endIndex)
  }

  @_alwaysEmitIntoClient
  public mutating func removeFirst(_ n: Int) {
    if n == 0 { return }
    precondition(n >= 0, "Number of elements to remove should be non-negative")
    let start = self.startIndex
    guard let end = self.index(start, offsetBy: n, limitedBy: endIndex) else {
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
  @_lifetime(&self)
  public mutating func _customConsumeLast(_ n: Int) -> SubrangeConsumer? {
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
  @_lifetime(&self)
  public mutating func consumeAll() -> SubrangeConsumer {
    consumeSubrange(startIndex ..< endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: some RangeExpression2<Index>
  ) -> SubrangeConsumer {
    consumeSubrange(subrange.relative(to: self))
  }

  // This unavailable default implementation of the protocol requirement
  // prevents incomplete RangeReplaceableContainer implementations from
  // satisfying the protocol through the use of the generic algorithm above.
  @available(*, unavailable)
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    fatalError()
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: UnboundedRange
  ) -> SubrangeConsumer {
    consumeAll()
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
    return consumeSubrange(start ..< i)
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
    if let drain = self._customConsumeLast(n) {
      return drain
    }
    precondition(n >= 0, "Count of elements to consume is out of bounds")
    let end = self.endIndex
    var i = end
    var distance = -n
    self.formIndex(&i, offsetBy: &distance, limitedBy: self.startIndex)
    precondition(distance == 0, "Count of elements to consume is out of bounds")
    return consumeSubrange(i ..< end)
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  /// - Returns: A valid index addressing the position following the consumed
  ///    subrange.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ bounds: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    var drain = self.consumeSubrange(bounds)
    while true {
      var span = drain.drainNext()
      guard !span.isEmpty else { break }
      consumer(&span)
    }
    return drain.finalize()
  }

  @_alwaysEmitIntoClient
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consumeSubrange(startIndex ..< endIndex, consumingWith: consumer)
  }

  /// - Returns: A valid index addressing the position following the consumed
  ///    subrange.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ subrange: some RangeExpression2<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    consumeSubrange(subrange.relative(to: self), consumingWith: consumer)
  }

  /// - Returns: A valid index addressing the position following the consumed
  ///    subrange.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ subrange: UnboundedRange,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    consumeAll(consumingWith: consumer)
    return self.endIndex
  }
}

@available(SwiftStdlib 6.4, *)
extension DrainableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @inline(always)
  @discardableResult
  public mutating func remove(at index: Index) -> Element {
    var index = index
    return remove(at: &index)
  }

  @_alwaysEmitIntoClient
  public mutating func removeFirst() -> Element {
    precondition(
      !isEmpty,
      "Can't remove first element from an empty container")
    return self.remove(at: self.startIndex)
  }

  /// - Returns: A valid index addressing the position following the removed
  ///    subrange.
  @_alwaysEmitIntoClient
  @inline(always)
  @discardableResult
  public mutating func removeSubrange(
    _ subrange: some RangeExpression2<Index>
  ) -> Index {
    self.removeSubrange(subrange.relative(to: self))
  }

  /// - Returns: A valid index addressing the position following the removed
  ///    subrange.
  @_alwaysEmitIntoClient
  @inline(always)
  @discardableResult
  public mutating func removeSubrange(
    _ subrange: UnboundedRange
  ) -> Index {
    self.removeAll()
    return self.startIndex
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
