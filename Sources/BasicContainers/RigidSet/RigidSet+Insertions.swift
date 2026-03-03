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
extension RigidSet where Element: ~Copyable {
  @usableFromInline
  @frozen
  package struct _InsertResult: ~Copyable {
    // FIXME: This struct really just wants to be a tuple.
    @_alwaysEmitIntoClient
    package var bucket: _Bucket
    @_alwaysEmitIntoClient
    package var remnant: Element?
    
    @_alwaysEmitIntoClient
    package init(
      bucket: _Bucket, remnant: consuming Element?
    ) {
      self.bucket = bucket
      self.remnant = remnant
    }
    
    @_alwaysEmitIntoClient
    package var found: Bool { remnant != nil }
  }
  
  @inlinable
  @inline(__always)
  @discardableResult
  package mutating func _insertNew(
    _ item: consuming Element,
    hashValue: Int
  ) -> _Bucket {
    precondition(!isFull, "RigidSet capacity overflow")
    let storage = _memberBuf
    if _table.isSmall {
      let bucket = _table.insertNew_Small(
        swapper: {
          swap(&item, &storage[$0])
        })
      storage._initializeElement(at: bucket, to: item)
      return bucket
    }
    return _insertNew_Large(item, hashValue: hashValue)
  }
  
  @inlinable
  @discardableResult
  package mutating func _insertNew_Large(
    _ item: consuming Element,
    hashValue: Int
  ) -> _Bucket {
    let storage = _memberBuf
    let seed = self._seed
    let bucket = _table.insertNew_Large(
      hashValue: hashValue,
      hashGenerator: {
        storage[$0]._rawHashValue_temp(seed: seed)
      },
      swapper: {
        swap(&item, &storage[$0])
      })
    storage.initializeElement(at: bucket.offset, to: item)
    return bucket
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
    let r = _find(item)
    if let bucket = r.bucket {
      return exchange(&_memberPtr(at: bucket).pointee, with: item)
    }
    _insertNew(item, hashValue: r.hashValue)
    return nil
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
    let r = _find(item)
    if r.bucket != nil {
      return item
    }
    _insertNew(item, hashValue: r.hashValue)
    return nil
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public mutating func insert<E: Error>(
    maximumCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    precondition(maximumCount >= 0, "Cannot insert a negative number of items")
    guard maximumCount > 0 else { return }
    precondition(freeCapacity >= maximumCount, "RigidSet capacity overflow")
    var remainder = maximumCount
    
    // FIXME: Instead of getting temporary buffers, we could place the new
    // items in unoccupied buckets, then incrementally
    // rehash them into their correct location, like the stdlib does for
    // the bridging initializers for Set/Dictionary.
    while remainder > 0 {
      let c = Swift.min(remainder, 16)
      try withTemporaryOutputSpan(
        of: Element.self,
        capacity: c
      ) { output throws(E) in
        defer {
          output._consumeAll { span in
            if span.count < c {
              remainder = 0
            } else {
              remainder &-= span.count
            }
            while let next = span.popFirst() {
              insert(next)
            }
          }
        }
        try initializer(&output)
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    maximumCount: Int? = nil,
    from producer: inout P
  ) throws(E) {
    try self.insert(
      maximumCount: maximumCount ?? freeCapacity
    ) { target throws(E) in
      while !target.isFull {
        guard try producer.generate(into: &target) else { break }
      }
    }
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func insert<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    maximumCount: Int? = nil,
    from drain: inout D
  ) {
    var remainder = maximumCount ?? freeCapacity
    while remainder > 0 {
      var span = drain.drainNext(maximumCount: remainder)
      guard !span.isEmpty else { break }
      while let next = span.popFirst() {
        self.insert(next)
      }
      remainder &-= span.count
    }
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidSet /* where Element: Copyable */ {
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying items: borrowing Span<Element>
  ) {
    var i = 0
    while i < items.count {
      self.insert(items[unchecked: i])
      i &+= 1
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  package mutating func _insert<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) {
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
