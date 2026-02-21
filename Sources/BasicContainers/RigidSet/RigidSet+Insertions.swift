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
  package mutating func _insertNew(
    _ item: consuming Element,
    hashValue: Int,
    swapper: (borrowing Element, _Bucket) -> Void = { _, _ in }
  ) -> _Bucket {
    precondition(!isFull, "RigidSet capacity overflow")
    let storage = _memberBuf
    if _table.isSmall {
      let bucket = _table.insertNew_Small(
        swapper: {
          swapper(item, $0)
          swap(&item, &storage[$0])
        })
      storage._initializeElement(at: bucket, to: item)
      return bucket
    }
    return _insertNew_Large(item, hashValue: hashValue, swapper: swapper)
  }
  
  
  @inlinable
  @inline(__always)
  package mutating func _insertNew_Large(
    _ item: consuming Element,
    swapper: (borrowing Element, _Bucket) -> Void = { _, _ in }
  ) -> _Bucket {
    _insertNew_Large(item, hashValue: _hashValue(for: item), swapper: swapper)
  }
  
  @inlinable
  package mutating func _insertNew_Large(
    _ item: consuming Element,
    hashValue: Int,
    swapper: (borrowing Element, _Bucket) -> Void = { _, _ in }
  ) -> _Bucket {
    let storage = _memberBuf
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
    return bucket
  }
  
  @inlinable
  @discardableResult
  package mutating func _insert(
    _ item: consuming Element,
    swapper: (borrowing Element, _Bucket) -> Void = { _, _ in }
  ) -> _InsertResult {
    let r = _find(item)
    if let bucket = r.bucket {
      return .init(bucket: bucket, remnant: item)
    }
    let bucket = _insertNew(item, hashValue: r.hashValue, swapper: swapper)
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
    return exchange(&_memberBuf[r.bucket.offset], with: remnant)
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

#endif
