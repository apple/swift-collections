//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@frozen
@safe
public struct Box<T: ~Copyable>: ~Copyable {
  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    unsafe _pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    unsafe _pointer.initialize(to: value)
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    unsafe _pointer.deinitialize(count: 1)
    unsafe _pointer.deallocate()
  }
}

extension Box where T: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func consume() -> T {
    let result = unsafe _pointer.move()
    unsafe _pointer.deallocate()
    discard self
    return result
  }

  @lifetime(immortal)
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func leak() -> Inout<T> {
    let result = unsafe Inout<T>(unsafeImmortalAddress: _pointer)
    discard self
    return result
  }

  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<T>(_pointer)
    }

    @_transparent
    unsafeMutableAddress {
      unsafe _pointer
    }
  }
  
  @lifetime(borrow self)
  @_alwaysEmitIntoClient
  @_transparent
  public func borrow() -> Borrow<T> {
    unsafe Borrow(unsafeAddress: UnsafePointer(_pointer), owner: self)
  }
  
  @lifetime(&self)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func mutate() -> Inout<T> {
    unsafe Inout(unsafeAddress: _pointer, owner: &self)
  }
}

extension Box where T: Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func copy() -> T {
    unsafe _pointer.pointee
  }
}
