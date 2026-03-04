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

#if compiler(<6.4) || !COLLECTIONS_UNSTABLE_HASHED_CONTAINERS
@available(*, unavailable, message: "RigidSet requires a Swift 6.4 toolchain")
public struct UniqueSet<Element: Hashable>: ~Copyable {
  package init() {
    fatalError()
  }
}
#else
@available(SwiftStdlib 5.0, *)
@frozen
public struct UniqueSet<Element: Hashable & ~Copyable>: ~Copyable {
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
