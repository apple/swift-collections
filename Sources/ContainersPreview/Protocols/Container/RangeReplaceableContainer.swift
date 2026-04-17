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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

//MARK: - Protocol Definition

@available(SwiftStdlib 5.0, *)
public protocol RangeReplaceableContainer<Element>
: Container, ~Copyable, ~Escapable
where
  Element: ~Copyable,
  Index: Comparable // For `Range<Index>`
{
  // Core requirements

  var freeCapacity: Int { get }

  mutating func replace<E: Error>(
    removing subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  associatedtype SubrangeConsumer: Drain<Element> & ~Copyable & ~Escapable

  @_lifetime(&self)
  mutating func consume(_ subrange: Range<Index>) -> SubrangeConsumer

  // Requirements with default implementations

  mutating func remove(at index: Index) -> Element
  mutating func removeSubrange(_ bounds: Range<Index>)
  mutating func removeAll()

  mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Index,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  mutating func insert(_ item: consuming Element, at index: Index)

  mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E)

  mutating func append(_ item: consuming Element)
}

//MARK: - Default Implementations

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
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

  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Index>) {
    replace(
      removing: bounds,
      consumingWith: { _ in },
      addingCount: 0,
      initializingWith: { _ in })
  }

  @inlinable
  public mutating func removeAll() {
    removeSubrange(startIndex ..< endIndex)
  }

  @inlinable
  public mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Index,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try self.replace(
      removing: index ..< index,
      consumingWith: { _ in },
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  @inlinable
  public mutating func insert(
    _ item: consuming Element, at index: Index
  ) {
    var item: Optional = item
    insert(addingCount: 1, at: index) { target in
      target.append(item.take()!)
    }
  }

  @inlinable
  public mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try self.insert(
      addingCount: newItemCount,
      at: endIndex,
      initializingWith: initializer)
  }

  @inlinable
  public mutating func append(_ item: consuming Element) {
    insert(item, at: endIndex)
  }
}

//MARK: - Standard Extensions

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public mutating func replace<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    removing subrange: some RangeExpression2<Index>,
    addingCount: Int,
    from producer: inout P
  ) throws(P.ProducerError)
  where P.Element: ~Copyable
  {
    try replace(
      removing: subrange.relative(to: self),
      consumingWith: { _ in },
      addingCount: count,
      initializingWith: { target throws(E) in
        while !target.isFull, try producer.generate(into: &target) {
        }
      })
  }

  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: some RangeExpression2<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try replace(
      removing: subrange.relative(to: self),
      consumingWith: consumer,
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: some RangeExpression2<Index>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try replace(
      removing: subrange.relative(to: self),
      consumingWith: { _ in },
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  @inlinable
  public mutating func replace<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    removing targetSubrange: some RangeExpression2<Index>,
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C
  ) {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    let targetSubrange = targetSubrange.relative(to: self)
    self.replace(removing: targetSubrange, addingCount: c, from: &producer)
    if !producer._isAtEnd() {
      preconditionFailure("Invalid Container")
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public mutating func consume(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    self.replace(
      removing: subrange,
      consumingWith: consumer,
      addingCount: 0,
      initializingWith: {
        precondition($0.isFull, "Invalid RangeReplaceableContainer")
      })
  }

  @inlinable
  @_lifetime(&self)
  public mutating func consumeAll() -> SubrangeConsumer {
    consume(startIndex ..< endIndex)
  }

  @inlinable
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: some RangeExpression2<Index>
  ) -> SubrangeConsumer {
    consume(subrange.relative(to: self))
  }

  @inlinable
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: UnboundedRange
  ) -> SubrangeConsumer {
    consume(startIndex ..< endIndex)
  }

  @inlinable
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where
  Self: BidirectionalContainer,
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public mutating func removeSubrange(
    _ bounds: some RangeExpression2<Index>
  ) {
    removeSubrange(bounds.relative(to: self))
  }

  @inlinable
  public mutating func removeSubrange(
    _ bounds: UnboundedRange
  ) {
    removeAll()
  }
}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int,
    at index: Index,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    try self.insert(addingCount: newItemCount, at: index) { target throws(E) in
      while !target.isFull, try producer.generate(into: &target) {
      }
    }
  }

  @inlinable
  public mutating func insert<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    at index: Index,
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C
  ) {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    self.insert(addingCount: c, at: index, from: &producer)
    if !producer._isAtEnd() {
      preconditionFailure("Invalid Container")
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public mutating func append<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    try insert(addingCount: newItemCount, at: endIndex, from: &producer)
  }

  @inlinable
  public mutating func append<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C
  ) {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    self.append(addingCount: c, from: &producer)
    if !producer._isAtEnd() {
      preconditionFailure("Invalid Container")
    }
  }
}

//MARK: - Standard Extensions Requiring Copyability

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where
  Self: ~Copyable & ~Escapable,
  Element: Copyable
{
  @inlinable
  public mutating func replace<C: Container<Element> & ~Copyable & ~Escapable>(
    removing subrange: Range<Index>,
    copying items: borrowing C
  ) {
    var c = items.count
    var i = items.startIndex
    self.replace(removing: subrange, addingCount: c) { target in
      let source = items.nextSpan(after: &i, maximumCount: target.freeCapacity)
      target._append(copying: source)
      c -= source.count
    }
    precondition(c == 0, "Invalid RangeReplaceableContainer")
  }

  @inlinable
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing C,
    at index: Index
  ) {
    var c = items.count
    var i = items.startIndex
    insert(addingCount: c, at: index) { target in
      let source = items.nextSpan(after: &i, maximumCount: target.freeCapacity)
      c -= source.count
      target._append(copying: source)
    }
    precondition(c == 0, "Invalid RangeReplaceableContainer")
  }

  @inlinable
  public mutating func append(
    copying items: Span<Element>
  ) {
    guard !items.isEmpty else { return }
    var items = items
    append(addingCount: items.count) { target in
      target._append(copying: items._trim(first: target.freeCapacity))
    }
    precondition(items.isEmpty, "Invalid RangeReplaceableContainer")
  }

  @inlinable
  public mutating func append<
    S: BorrowingSequence_<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) {
    var it = items.makeBorrowingIterator_()
    while true {
      let span = it.nextSpan_()
      guard !span.isEmpty else { break }
      self.append(copying: span)
    }
  }
}

#endif
