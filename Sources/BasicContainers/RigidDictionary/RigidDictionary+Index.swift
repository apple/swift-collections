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
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  public typealias Index = RigidSet<Key>.Index
  
  @inlinable
  @inline(__always)
  public var startIndex: Index {
    _keys.startIndex
  }
  
  @inlinable
  @inline(__always)
  public var endIndex: Index {
    _keys.endIndex
  }
  
  @inlinable
  @inline(__always)
  public func index(forKey key: borrowing Key) -> Index? {
    _keys.index(of: key)
  }
  
  @inlinable
  @inline(__always)
  public func index(after index: Index) -> Index {
    _keys.index(after: index)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _isOccupied(_ bucket: _Bucket) -> Bool {
    _keys._isOccupied(bucket)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _checkItemIndex(_ index: Index) -> Void {
    _keys._checkItemIndex(index)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @frozen
  @safe
  public struct Element: ~Copyable, ~Escapable {
    // FIXME: See if using (the real) `struct Borrow` would make sense here.
    @_alwaysEmitIntoClient
    @unsafe
    package var _key: UnsafePointer<Key>

    @_alwaysEmitIntoClient
    @unsafe
    package var _value: UnsafePointer<Value>
    
    @_alwaysEmitIntoClient
    @_lifetime(borrow _base)
    @safe
    package init(
      _base: borrowing RigidDictionary<Key, Value>,
      bucket: _Bucket
    ) {
      assert(_base._isOccupied(bucket))
      unsafe self._key = .init(_base._keyPtr(at: bucket))
      unsafe self._value = .init(_base._valuePtr(at: bucket))
    }
    
    @_alwaysEmitIntoClient
    public var key: Key {
      @_unsafeSelfDependentResult
      borrow { unsafe _key.pointee }
    }
    
    @_alwaysEmitIntoClient
    public var value: Value {
      @_unsafeSelfDependentResult
      borrow { unsafe _value.pointee }
    }
  }
  
  @_alwaysEmitIntoClient
  public subscript(index: Index) -> Element {
    _checkItemIndex(index)
    return Element(_base: self, bucket: index._bucket)
  }
}

#endif
