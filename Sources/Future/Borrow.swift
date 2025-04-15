//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Builtin

@frozen
@safe
public struct Borrow<T: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  let _pointer: UnsafePointer<T>

  @lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: borrowing @_addressable T) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }

  @lifetime(copy owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafePointer<T>,
    owner: borrowing Owner
  ) {
    unsafe _pointer = unsafeAddress
  }
  
  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      unsafe _pointer
    }
  }
}
