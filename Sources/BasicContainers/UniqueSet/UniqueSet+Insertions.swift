//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @inlinable
  package mutating func _insert(
    _ item: consuming Element
  ) -> RigidSet<Element>._InsertResult {
    let r = _storage._find(item)
    if let bucket = r.bucket {
      return .init(bucket: bucket, remnant: item)
    }
    var hashValue = r.hashValue
    if _ensureFreeCapacity(1), !_storage._table.isSmall {
      hashValue = _storage._hashValue(for: item)
    }
    let bucket = _storage._insertNew(item, hashValue: hashValue)
    return .init(bucket: bucket, remnant: nil)
  }
  
  /// Inserts the given element into the set unconditionally. If the set already
  /// contained a member equal to `item`, then the new item replaces it.
  ///
  /// - Parameter item: An element to insert into the set.
  /// - Returns: An element equal to `item` if the set already contained such
  ///    a member, otherwise `nil`.
  @inlinable
  @discardableResult
  public mutating func update(
    with item: consuming Element
  ) -> Element? {
    var r = self._insert(item)
    guard let remnant = r.remnant.take() else { return nil }
    return exchange(
      &_storage._memberPtr(at: r.bucket).pointee,
      with: remnant)
  }

  /// Inserts the given element in the set if it is not already present.
  ///
  /// - Parameter item: An element to insert into the set.
  /// - Returns:
  @inlinable
  @discardableResult
  public mutating func insert(
    _ item: consuming Element
  ) -> Element? {
    var r = self._insert(item)
    return r.remnant.take()
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public mutating func insert<E: Error>(
    maximumCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    _ensureFreeCapacity(maximumCount)
    try _storage.insert(
      maximumCount: maximumCount, initializingWith: initializer)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: inout P
  ) throws(E) {
    var done = false
    while !done {
      _ensureFreeCapacity(Swift.max(producer.underestimatedCount, 1))
      try self.insert(maximumCount: self.freeCapacity) { target throws(E) in
        while !target.isFull, !done {
          done = try !producer.generate(into: &target)
        }
      }
    }
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func insert<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    from drain: inout D
  ) {
    while true {
      var span = drain.drainNext()
      guard !span.isEmpty else { break }
      while let next = span.popFirst() {
        self.insert(next)
      }
    }
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension UniqueSet /* where Element: Copyable */ {
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying items: borrowing Span<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.insert(copying: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  package mutating func _insert<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) {
    _ensureFreeCapacity(items.underestimatedCount)
    var it = items.makeBorrowingIterator()
    while true {
      let span = it.nextSpan()
      guard !span.isEmpty else { break }
      self.insert(copying: span)
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) {
    _insert(copying: items)
  }
#endif
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert(copying items: some Sequence<Element>) {
    _ensureFreeCapacity(items.underestimatedCount)
    var it = items.makeIterator()
    while let next = it.next() {
      self.insert(next)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    S: BorrowingSequence<Element> & Sequence<Element>
  >(
    copying items: borrowing S
  ) {
    _insert(copying: items)
  }
#endif
}

#endif
