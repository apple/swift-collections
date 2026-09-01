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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  public typealias Index = RigidSet<Element>.Index

  @inlinable
  @inline(__always)
  public var startIndex: Index {
    _storage.startIndex
  }

  @inlinable
  @inline(__always)
  public var endIndex: Index {
    _storage.endIndex
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _isOccupied(_ bucket: _Bucket) -> Bool {
    _storage._isOccupied(bucket)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _checkItemIndex(_ index: Index) -> Void {
    _storage._checkItemIndex(index)
  }

  @inlinable
  @inline(__always)
  public func index(of member: borrowing Element) -> Index? {
    _storage.index(of: member)
  }

  @inlinable
  @inline(__always)
  public func index(after index: Index) -> Index {
    _storage.index(after: index)
  }
  
  @inlinable
  public subscript(index: Index) -> Element {
    borrow {
      _storage[index]
    }
  }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index
  ) -> Span<Element> {
    _storage.nextSpan(after: &index)
  }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index, maxCount: Int, limitedBy limit: Index
  ) -> Span<Element> {
    _storage.nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }
}

#endif
