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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import Builtin

@frozen
@safe
public struct Ref<T: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  package let _pointer: UnsafePointer<T>

#if compiler(>=6.2) && FIXME
  @_lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: borrowing @_addressable T) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }
#endif

  @_lifetime(borrow owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafePointer<T>,
    borrowing owner: borrowing Owner
  ) {
    unsafe _pointer = unsafeAddress
  }

  @_lifetime(copy owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafePointer<T>,
    copying owner: borrowing Owner
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
#endif
