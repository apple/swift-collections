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
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  public typealias Index = RigidSet<Key>.Index
  
  @inlinable
  @inline(__always)
  public var startIndex: Index {
    _storage._keys.startIndex
  }
  
  @inlinable
  @inline(__always)
  public var endIndex: Index {
    _storage._keys.endIndex
  }
  
  @inlinable
  @inline(__always)
  public func index(forKey key: borrowing Key) -> Index? {
    _storage._keys.index(of: key)
  }
  
  @inlinable
  @inline(__always)
  public func index(after index: Index) -> Index {
    _storage._keys.index(after: index)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _isOccupied(_ bucket: _Bucket) -> Bool {
    _storage._keys._isOccupied(bucket)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _checkItemIndex(_ index: Index) -> Void {
    _storage._keys._checkItemIndex(index)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  public typealias Element = RigidDictionary<Key, Value>.Element
  
  @_alwaysEmitIntoClient
  public subscript(index: Index) -> Element {
    _storage[index]
  }
}

#endif
