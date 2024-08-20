//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@frozen
public struct Box<T: ~Copyable>: ~Copyable {
  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    _pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    _pointer.initialize(to: value)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ fromInout: consuming Inout<T>) {
    _pointer = fromInout._pointer
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    _pointer.deinitialize(count: 1)
    _pointer.deallocate()
  }
}

extension Box where T: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func consume() -> T {
    let result = _pointer.move()
    _pointer.deallocate()
    discard self
    return result
  }

  @_alwaysEmitIntoClient
  @_transparent
  public consuming func leak() -> dependsOn(immortal) Inout<T> {
    let result = Inout<T>(unsafeImmortalAddress: _pointer)
    discard self
    return result
  }

  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      UnsafePointer<T>(_pointer)
    }

    @_transparent
    nonmutating unsafeMutableAddress {
      _pointer
    }
  }
}

extension Box where T: Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func copy() -> T {
    _pointer.pointee
  }
}
