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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @frozen
  public struct Index: Equatable, Hashable, CustomDebugStringConvertible {
    @_alwaysEmitIntoClient
    package var _bucket: _HTable.Bucket
    
    @_alwaysEmitIntoClient
    @_transparent
    package init(_bucket: _HTable.Bucket) {
      self._bucket = _bucket
    }

    @_alwaysEmitIntoClient
    @_transparent
    package init(_offset: UInt) {
      self._bucket = _HTable.Bucket(offset: _offset)
    }

    @_alwaysEmitIntoClient
    @_transparent
    package init(_offset: Int) {
      self._bucket = _HTable.Bucket(offset: _offset)
    }

    @_alwaysEmitIntoClient
    @_transparent
    package var _offset: UInt { _bucket._offset }
    
    @_alwaysEmitIntoClient
    public static func ==(left: Self, right: Self) -> Bool {
      left._bucket == right._bucket
    }

    @_alwaysEmitIntoClient
    public func hash(into hasher: inout Hasher) {
      hasher.combine(self._bucket)
    }

    @_alwaysEmitIntoClient
    public func _rawHashValue(seed: Int) -> Int {
      self._bucket._rawHashValue(seed: seed)
    }

    @_alwaysEmitIntoClient
    public var debugDescription: String {
      "@\(_bucket.offset)"
    }
  }

  @inlinable
  public var startIndex: Index {
    if _table.isSmall { return Index(_bucket: _Bucket(offset: 0)) }
    guard let b = _table.bitmap.firstOccupiedBucket(from: _Bucket(offset: 0))
    else { return endIndex }
    return Index(_bucket: b)
  }

  @inlinable
  public var endIndex: Index {
    if _table.isSmall { return Index(_offset: count) }
    return Index(_bucket: _table.endBucket)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _isOccupied(_ bucket: _Bucket) -> Bool {
    _table.isValid(bucket) && _table.isOccupied(bucket)
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _checkValidIndex(_ index: Index) -> Void {
    precondition(
      _isOccupied(index._bucket) || index == endIndex,
      "Index out of bounds")
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _checkItemIndex(_ index: Index) -> Void {
    precondition(_isOccupied(index._bucket), "Index out of bounds")
  }

  @inlinable
  public func index(of member: borrowing Element) -> Index? {
    guard let bucket = self._find(member).bucket else { return nil }
    return Index(_bucket: bucket)
  }

  @inlinable
  public func index(after index: Index) -> Index {
    _checkItemIndex(index)
    if _table.isSmall {
      return Index(_bucket: _Bucket(offset: index._bucket._offset &+ 1))
    }
    var start = index._bucket
    start._offset &+= 1
    guard start < _table.endBucket else { return Index(_bucket: start) }
    guard let b = _table.bitmap.firstOccupiedBucket(from: start)
    else { return endIndex }
    return Index(_bucket: b)
  }
  
  @inlinable
  public subscript(index: Index) -> Element {
    @_unsafeSelfDependentResult
    borrow {
      _checkItemIndex(index)
      return _memberPtr(at: index._bucket).pointee
    }
  }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index
  ) -> Span<Element> {
    _checkValidIndex(index)
    if index == endIndex { return .init() }
    if _table.isSmall {
      let start = Int(index._offset)
      let end = _table.count
      let items = _memberBuf.extracting(start ..< end)
      index = Index(_offset: end)
      let span = Span(_unsafeElements: items)
      return _overrideLifetime(span, borrowing: self)
    }
    let buckets = _table.bitmap.nextOccupiedRegion(
      from: &index._bucket, maxCount: .max, limit: _table.endBucket)
    let span = Span(
      _unsafeStart: _memberPtr(at: buckets.lowerBound),
      count: buckets._offsets.count)
    return _overrideLifetime(span, borrowing: self)
  }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index, maxCount: Int, limitedBy limit: Index
  ) -> Span<Element> {
    _checkValidIndex(index)
    _checkValidIndex(limit)
    precondition(maxCount > 0, "maxCount must be positive")
    if index == endIndex { return .init() }
    let limit = limit._offset < index._offset ? endIndex : limit
    if _table.isSmall {
      let start = Int(index._offset)
      var c = Swift.min(maxCount, _table.count - start)
      var end = start
      end._advance(by: &c, limitedBy: Int(limit._offset))
      let items = _memberBuf.extracting(start ..< end)
      index = Index(_offset: end)
      let span = Span(_unsafeElements: items)
      return _overrideLifetime(span, borrowing: self)
    }
    let buckets = _table.bitmap.nextOccupiedRegion(
      from: &index._bucket, maxCount: maxCount, limit: limit._bucket)
    let span = Span(
      _unsafeStart: _memberPtr(at: buckets.lowerBound),
      count: buckets._offsets.count)
    return _overrideLifetime(span, borrowing: self)
  }
}

#endif
