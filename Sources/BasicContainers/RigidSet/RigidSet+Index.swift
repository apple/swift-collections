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
  @frozen
  public struct Index: Equatable {
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
    // FIXME: Use borrow accessor here
    unsafeAddress {
      _checkItemIndex(index)
      return .init(_memberPtr(at: index._bucket))
    }
  }
}

#endif
