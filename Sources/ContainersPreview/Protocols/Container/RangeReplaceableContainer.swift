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

@available(SwiftStdlib 5.0, *)
public protocol RangeReplaceableContainer<Element>
: Container, ~Copyable, ~Escapable
where
  Element: ~Copyable,
  Index: Comparable // For `Range<Index>`
{
  // MARK: Core requirements

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

  // MARK: Requirements with default implementations

  mutating func remove(at index: Index) -> Element
  mutating func removeSubrange(_ bounds: Range<Index>)
  mutating func removeAll()
  mutating func removeFirst() -> Element
  mutating func removeFirst(_ n: Int)
  mutating func _customRemoveLast() -> Element?
  mutating func _customRemoveLast(_ n: Int) -> Bool

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
    replace(
      removing: bounds,
      consumingWith: { _ in },
      addingCount: 0,
      initializingWith: { _ in })
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

  @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
  public mutating func insert(
    _ item: consuming Element, at index: Index
  ) {
    var item: Optional = item
    insert(addingCount: 1, at: index) { target in
      target.append(item.take()!)
    }
  }

  @_alwaysEmitIntoClient
  public mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try self.insert(
      addingCount: newItemCount,
      at: endIndex,
      initializingWith: initializer)
  }

  @_alwaysEmitIntoClient
  public mutating func append(_ item: consuming Element) {
    insert(item, at: endIndex)
  }
}

//MARK: - Standard Extensions

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func replace<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    removing subrange: some RangeExpression2<Index>,
    addingCount: Int,
    from producer: inout P
  ) throws(P.Failure)
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

  @_alwaysEmitIntoClient
  public mutating func replace<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    removing subrange: some RangeExpression2<Index>,
    addingFrom producer: consuming P
  ) throws(P.Failure)
  where P.Element: ~Copyable
  {
    try replace(
      removing: subrange,
      addingCount: producer.count,
      from: &producer)
    try producer._expectEnd("Invalid Container")
  }

  @_alwaysEmitIntoClient
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

  // This unavailable default implementation of the protocol requirement
  // prevents incomplete RangeReplaceableContainer implementations from
  // satisfying the protocol through the use of the generic algorithm above.
  @available(*, unavailable)
  @_alwaysEmitIntoClient
  public mutating func replace<E: Error>(
    removing subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    fatalError()
  }

  @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
  public mutating func replace<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    removing targetSubrange: some RangeExpression2<Index>,
    moving source: inout C
  ) where C.Element: ~Copyable {
    replace(removing: targetSubrange, addingFrom: source.consumeAll())
  }

  @_alwaysEmitIntoClient
  public mutating func replace<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    removing targetSubrange: some RangeExpression2<Index>,
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C
  ) where C.Element: ~Copyable {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    let targetSubrange = targetSubrange.relative(to: self)
    self.replace(removing: targetSubrange, addingCount: c, from: &producer)
    producer._expectEnd("Invalid Container")
  }

  @_alwaysEmitIntoClient
  public mutating func replace<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    removing targetSubrange: some RangeExpression2<Index>,
    consuming source: consuming C
  ) where C.Element: ~Copyable {
    replace(removing: targetSubrange, addingFrom: source.consumeAll())
  }

}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
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

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: BidirectionalContainer & ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    if self.isEmpty { return nil }
    if let result = self._customRemoveLast() { return result }
    return self.remove(at: self.index(before: self.endIndex))
  }
}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  /// Inserts at most `newItemCount` items generated by a producer into this
  /// container, starting at the given index.
  ///
  /// The target container must be able to accommodate the specified number
  /// of new items.
  ///
  /// This operation inserts as many items as the producer can generate before
  /// either reaching `newItemCount`, or the producer hitting its end, or
  /// throwing an error. If the producer has more than `newItemCount` items
  /// left in it, then extra items remain available after this method returns.
  ///
  /// If the operation ends up inserting fewer than `newItemCount` items, then
  /// it may leave a gap that needs to be closed (e.g., by compacting storage)
  /// to restore invariants before the function returns. This may add some
  /// overhead compared to adding exactly as many items as promised.
  ///
  /// - Parameters:
  ///    - newItemCount: The maximum number of items to insert into the container.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the container.
  ///    - producer: A producer that generates the items to append.
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int,
    from producer: inout P,
    at index: Index
  ) throws(E)
  where P.Element: ~Copyable
  {
    try self.insert(addingCount: newItemCount, at: index) { target throws(E) in
      while !target.isFull, try producer.generate(into: &target) {
        // Do nothing
      }
    }
  }

  /// Inserts all items generated by a producer into this container,
  /// starting at the given index.
  ///
  /// The target container must be able to accommodate every item that the
  /// producer generates.
  ///
  /// This operation inserts as many items as the producer can generate before
  /// hitting its end, or throwing an error.
  ///
  /// If the producer throws an error, then the operation preserves all items
  /// that it previously managed to insert before rethrowing the error.
  /// If this happens, then the failed insertions may leave a gap that needs to
  /// be carefully closed (e.g., by compacting storage) to restore invariants
  /// before the function returns. This may add some overhead compared to adding
  /// exactly as many items as promised.
  ///
  /// - Parameters:
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the container.
  ///    - producer: A producer that generates the items to append.
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: consuming P,
    at index: Index
  ) throws(E)
  where P.Element: ~Copyable
  {
    let c = producer.count
    try self.insert(addingCount: c, at: index) { target throws(E) in
      while !target.isFull, try producer.generate(into: &target) {
      }
    }
    try producer._expectEnd("Invalid Container")
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    moving source: inout C,
    at index: Index
  ) where C.Element: ~Copyable {
    self.insert(from: source.consumeAll(), at: index)
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C,
    at index: Index
  ) where C.Element: ~Copyable {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    self.insert(addingCount: c, from: &producer, at: index)
    producer._expectEnd("Invalid Container")
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    consuming source: consuming C,
    at index: Index
  ) where C.Element: ~Copyable {
    self.insert(from: source.consumeAll(), at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  /// Appends at most `newItemCount` items generated by a producer to the end of
  /// this container.
  ///
  /// The container must be able to accommodate the specified number of new
  /// items.
  ///
  /// This operation appends as many items as the producer can generate before
  /// either reaching its end, throwing an error, or filling the specified
  /// capacity. This operation only consumes the first `newItemCount` items in the
  /// producer; if the producer has more, then they remain available after this
  /// method returns.
  ///
  /// - Parameters:
  ///    - newItemCount: The number of items to append to the container.
  ///    - producer: A producer that generates the items to append.
  @_alwaysEmitIntoClient
  public mutating func append<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    try insert(addingCount: newItemCount, from: &producer, at: endIndex)
  }

  /// Appends all items generated by the given producer to the end of
  /// this container.
  ///
  /// The container must be able to accommodate all items.
  ///
  /// This operation appends all items the producer generates before reaching
  /// its end or throwing an error. If the producer throws an error, the
  /// operation preserves all previously appended items before rethrowing the
  /// error.
  ///
  /// - Parameters:
  ///    - producer: A producer that generates the items to append.
  @_alwaysEmitIntoClient
  public mutating func append<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: consuming P
  ) throws(E)
  where P.Element: ~Copyable
  {
    try append(addingCount: producer.count, from: &producer)
    try producer._expectEnd("Invalid Container")
  }

  /// Moves the elements of a given container into the end of this one, leaving
  /// the source container empty.
  ///
  /// The target container must be able to accommodate all items in the source
  /// container.
  ///
  /// - Parameters:
  ///    - items: A container whose contents to move into this container.
  @_alwaysEmitIntoClient
  public mutating func append<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    moving items: inout C
  ) where C.Element: ~Copyable {
    self.append(from: items.consumeAll())
  }

  @_alwaysEmitIntoClient
  public mutating func append<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    moving sourceSubrange: some RangeExpression2<C.Index>,
    from source: inout C
  ) where C.Element: ~Copyable {
    let sourceSubrange = sourceSubrange.relative(to: source)
    let c = source.distance(from: sourceSubrange.lowerBound, to: sourceSubrange.upperBound)
    var producer = source.consume(sourceSubrange)
    self.append(addingCount: c, from: &producer)
    producer._expectEnd("Invalid Container")
  }

  /// Appends the elements of a given container to the end of this one by
  /// consuming the source container.
  ///
  /// The target container must be able to accommodate all items in the source
  /// container.
  ///
  /// - Parameters:
  ///    - items: A container whose contents to move into this container.
  @_alwaysEmitIntoClient
  public mutating func append<
    C: RangeReplaceableContainer<Element> & ~Copyable & ~Escapable
  >(
    consuming items: consuming C
  ) where C.Element: ~Copyable {
    self.append(from: items.consumeAll())
  }
}

//MARK: - Standard Extensions Requiring Copyability

@available(SwiftStdlib 5.0, *)
extension RangeReplaceableContainer
where
  Self: ~Copyable & ~Escapable,
  Element: Copyable
{
  @_alwaysEmitIntoClient
  public mutating func replace<C: Container<Element> & ~Copyable & ~Escapable>(
    removing subrange: Range<Index>,
    copying items: borrowing C
  ) {
    var c = items.count
    var i = items.startIndex
    self.replace(removing: subrange, addingCount: c) { target in
      let source = items.nextSpan(after: &i, maxCount: target.freeCapacity)
      target._append(copying: source)
      c -= source.count
    }
    precondition(c == 0, "Invalid RangeReplaceableContainer")
  }

  @_alwaysEmitIntoClient
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    addingCount newCount: Int,
    copying items: borrowing C,
    at index: Index
  ) {
    var it = items.makeIterableIterator_()
    insert(addingCount: newCount, at: index) { target in
      while !target.isFull {
        let source = it.nextSpan_(maxCount: target.freeCapacity)
        precondition(!source.isEmpty, "Broken container: mismatching count")
        target._append(copying: source)
      }
    }
    precondition(it.nextSpan_().isEmpty, "Broken container: mismatching count")
  }

  @_alwaysEmitIntoClient
  package mutating func _insertCollection(
    addingCount newCount: Int,
    copying items: some Collection<Element>,
    at index: Index
  ) {
    let done: Void? = items.withContiguousStorageIfAvailable { buffer in
      precondition(buffer.count == newCount, "Broken Collection: mismatching count")
      self.insert(addingCount: buffer.count, at: index) { target in
        target._append(copying: buffer)
      }
    }
    if done != nil { return }
    var it = items.makeIterator()
    self.insert(addingCount: newCount, at: index) { target in
      while !target.isFull {
        guard let item = it.next() else { preconditionFailure() }
        target.append(item)
      }
    }
    precondition(it.next() == nil, "Broken Collection")
  }

  /// Copies the elements of a source container into this container, starting
  /// at the specified target position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index in `self`. If you pass the target's `endIndex` as
  /// the `index` parameter, then the new elements are appended to the end.
  ///
  /// The target container must be able to accommodate all items in the source
  /// container.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the container.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of `self`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing C,
    at index: Index
  ) {
    _insertContainer(
      addingCount: items.count, copying: items, at: index)
  }

  /// Copies the elements of a collection into this container at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the container's `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end.
  ///
  /// The target container must be able to accommodate all items in the source
  /// container.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the container.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of `self`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert(
    copying items: some Collection<Element>, at index: Index
  ) {
    _insertCollection(addingCount: items.count, copying: items, at: index)
  }

  /// Copies the elements of a source container into this container, starting
  /// at the specified target position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index in `self`. If you pass the target's `endIndex` as
  /// the `index` parameter, then the new elements are appended to the end.
  ///
  /// The target container must be able to accommodate all items in the source
  /// container.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the container.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of `self`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying items: borrowing C, at index: Index
  ) {
    _insertContainer(
      addingCount: items.count, copying: items, at: index)
  }

  @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
  package mutating func _appendIterable<
    S: Iterable_ & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) throws(S.Failure_)
  where S.Element_ == Element {
    var it = items.makeIterableIterator_()
    while true {
      let span = try it.nextSpan_()
      guard !span.isEmpty else { break }
      self.append(copying: span)
    }
  }

  @_alwaysEmitIntoClient
  public mutating func append<
    S: Iterable_ & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) throws(S.Failure_)
  where S.Element_ == Element {
    try _appendIterable(copying: items)
  }

  /// Copies the elements of a sequence to the end of this container.
  ///
  /// The container must be able to accommodate all items in the sequence.
  ///
  /// - Parameters:
  ///    - newElements: The new elements to copy into the container.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      unsafe self.append(copying: buffer)
      return
    }
    if done != nil { return }

    for item in newElements {
      self.append(item)
    }
  }

  /// Copies the elements of an iterable to the end of this container.
  ///
  /// The container must be able to accommodate all items in the iterable.
  ///
  /// - Parameters:
  ///    - newElements: The new elements to copy into the container.
  @_alwaysEmitIntoClient
  public mutating func append<
    Source: Iterable_ & Sequence<Element>
  >(
    copying newElements: Source
  ) throws(Source.Failure_)
  where Source.Element_ == Element {
    try self._appendIterable(copying: newElements)
  }
}

#endif
