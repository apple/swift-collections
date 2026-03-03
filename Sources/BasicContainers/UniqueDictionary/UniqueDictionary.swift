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
@frozen
@_addressableForDependencies
public struct UniqueDictionary<
  Key: GeneralizedHashable & ~Copyable,
  Value: ~Copyable
>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket
  
  @_alwaysEmitIntoClient
  package var _storage: RigidDictionary<Key, Value>
  
  @_alwaysEmitIntoClient
  package init(_storage: consuming RigidDictionary<Key, Value>) {
    self._storage = _storage
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int {
    _assumeNonNegative(_storage._keys._table._count)
  }
  
  @inlinable
  @inline(__always)
  public var capacity: Int {
    _assumeNonNegative(_storage._keys._table._capacity)
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

  @_alwaysEmitIntoClient
  @_transparent
  public var _scale: UInt8 {
    _storage._scale
  }
}

#endif
