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
import InternalCollectionsUtilities
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS
@frozen
public struct RigidSet<Element: GeneralizedHashable & ~Copyable>: ~Copyable {
  @_alwaysEmitIntoClient
  package var _members: UnsafeMutablePointer<Element>?
  
  @_alwaysEmitIntoClient
  package var _table: _HTable

  @inlinable
  public init() {
    self.init(capacity: 0)
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Capacity must be nonnegative")
    self._table = _HTable(capacity: capacity)
    if capacity > 0 {
      self._members = .allocate(capacity: Int(bitPattern: _table.bucketCount))
    } else {
      self._members = nil
    }
  }
  
  @_alwaysEmitIntoClient
  deinit {
    _dispose()
  }
  
  @_alwaysEmitIntoClient
  internal func _dispose() {
    if !isEmpty {
      let storage = _memberBuf
      var it = _table.makeBucketIterator()
      while let range = it.nextOccupiedRegion() {
        storage.extracting(range._offsets).deinitialize()
      }
    }
    _members?.deallocate()
  }
}

extension RigidSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    _assumeNonNegative(_table.count)
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    _assumeNonNegative(_table.capacity)
  }
  
  @inlinable
  @inline(__always)
  public var isEmpty: Bool {
    count == 0
  }
  
  @inlinable
  @inline(__always)
  public var isFull: Bool {
    count == capacity
  }
  
  @inlinable
  @inline(__always)
  public var freeCapacity: Int {
    _assumeNonNegative(capacity &- count)
  }
}

extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _memberBuf: UnsafeMutableBufferPointer<Element> {
    .init(start: _members, count: Int(bitPattern: _table.bucketCount))
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal func _memberPtr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Element> {
    assert(_table.isValid(bucket))
    return _members.unsafelyUnwrapped.advanced(by: bucket.offset)
  }

  @_alwaysEmitIntoClient
  internal var _seed: Int {
#if COLLECTIONS_DETERMINISTIC_HASHING
    Int(_table.scale)
#else
    Int(bitPattern: _baseAddress)
#endif
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    at bucket: _HTable.Bucket
  ) -> Int {
    assert(bucket.offset >= 0 && bucket.offset < capacity)
    return _hashValue(for: _members.unsafelyUnwrapped[bucket.offset])
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal borrowing func _hashValue(
    for item: borrowing Element
  ) -> Int {
    item._rawHashValue(seed: _seed)
  }
}


extension RigidSet where Element: ~Copyable {
  @inlinable
  package borrowing func _find(_ item: borrowing Element) -> _HTable.Bucket? {
    func tester(_ bucket: _HTable.Bucket) -> Bool {
      _memberBuf[bucket.offset] == item
    }

    if _table.isSmall {
      return _table.find_Small(tester: tester)
    }
    return _table.find_Large(
      hashValue: _hashValue(for: item),
      tester: tester)
  }

  @inlinable
  public borrowing func contains(_ item: borrowing Element) -> Bool {
    _find(item) != nil
  }
  
  @usableFromInline
  @frozen
  internal struct _InsertResult: ~Copyable {
    // FIXME: This struct really just wants to be a tuple.
    @_alwaysEmitIntoClient
    internal var bucket: _HTable.Bucket
    @_alwaysEmitIntoClient
    internal var remnant: Element?
    
    @_alwaysEmitIntoClient
    internal init(
      bucket: _HTable.Bucket, remnant: consuming Element?
    ) {
      self.bucket = bucket
      self.remnant = remnant
    }
    
    @_alwaysEmitIntoClient
    internal var found: Bool { remnant != nil }
  }
  
  @inlinable
  @discardableResult
  internal mutating func _insert(
    _ item: consuming Element,
    swapper: (borrowing Element, _HTable.Bucket) -> Void = { _, _ in }
  ) -> _InsertResult {
    let storage = _memberBuf

    if _table.isSmall {
      if let bucket = _table.find_Small(
        tester: { storage[$0.offset] == item }
      ) {
        return .init(bucket: bucket, remnant: item)
      }
      precondition(!isFull, "RigidSet capacity overflow")
      let bucket = _table.insertNew_Small(
        swapper: {
          swapper(item, $0)
          swap(&item, &storage[$0.offset])
        })
      storage.initializeElement(at: bucket.offset, to: item)
      return .init(bucket: bucket, remnant: nil)
    }
      
    let hashValue = _hashValue(for: item)
    if let bucket = _table.find_Large(
      hashValue: hashValue,
      tester: { storage[$0.offset] == item }
    ) {
      return .init(bucket: bucket, remnant: item)
    }
    precondition(!isFull, "RigidSet capacity overflow")
    let seed = self._seed
    let bucket = _table.insertNew_Large(
      hashValue: hashValue,
      hashGenerator: {
        storage[$0.offset]._rawHashValue(seed: seed)
      },
      swapper: {
        swapper(item, $0)
        swap(&item, &storage[$0.offset])
      })
    storage.initializeElement(at: bucket.offset, to: item)
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
    if let remnant = r.remnant.take() {
      return exchange(&_memberBuf[r.bucket.offset], with: remnant)
    }
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
    var r = self._insert(item)
    return r.remnant.take()
  }
}

extension RigidSet where Element: ~Copyable {
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @inlinable
  public func _customContainsEquatableElement(
    _ element: borrowing Element
  ) -> Bool? {
    contains(element)
  }

  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(_table: _table, baseAddress: _members)
  }

  @frozen
  public struct BorrowingIterator:
    BorrowingIteratorProtocol,
    ~Copyable,
    ~Escapable
  {
    @_alwaysEmitIntoClient
    internal var _baseAddress: UnsafePointer<Element>?

    @_alwaysEmitIntoClient
    internal var _bucketIterator: _HTable.BucketIterator
  
    @_alwaysEmitIntoClient
    @_lifetime(borrow _table)
    internal init(
      _table: borrowing _HTable,
      baseAddress: UnsafePointer<Element>?
    ) {
      self._baseAddress = baseAddress
      self._bucketIterator = _table.makeBucketIterator()
    }

    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    internal func _span(over buckets: Range<_HTable.Bucket>) -> Span<Element> {
      let items = UnsafeBufferPointer(
        start: _baseAddress.unsafelyUnwrapped + buckets.lowerBound.offset,
        count: buckets.upperBound.offset - buckets.lowerBound.offset)
      return _overrideLifetime(Span(_unsafeElements: items), copying: self)
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
      precondition(maximumCount > 0, "maximumCount must be positive")
      guard
        let next = _bucketIterator.nextOccupiedRegion(maximumCount: maximumCount)
      else {
        return .init()
      }
      return _span(over: next)
    }
  }
}
#endif
