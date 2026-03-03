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
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
@frozen
public struct UniqueSet<Element: GeneralizedHashable & ~Copyable>: ~Copyable {
  @usableFromInline
  package typealias _Bucket = _HTable.Bucket

  @_alwaysEmitIntoClient
  package var _storage: RigidSet<Element>

  @_alwaysEmitIntoClient
  @_transparent
  package init(_storage: consuming RigidSet<Element>) {
    self._storage = _storage
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var count: Int { _storage.count }

  @inlinable
  @inline(__always)
  public var capacity: Int { _storage.capacity }

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
  public var freeCapacity: Int { _storage.freeCapacity }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _scale: UInt8 {
    _storage._table.scale
  }
}

#endif
