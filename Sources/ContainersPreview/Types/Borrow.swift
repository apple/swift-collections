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

@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct Borrow<Target: ~Copyable /* FIXME: ~Escapable */>: Copyable, ~Escapable {
  @usableFromInline
  package let _pointer: UnsafePointer<Target>
  
  @_lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  internal init(_borrowing value: borrowing @_addressable Target) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }
  
#if compiler(>=6.3) // rdar://161844406 (https://github.com/swiftlang/swift/pull/84748)
  @_lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: borrowing @_addressable Target) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }
#endif
  
  @_lifetime(borrow owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafePointer<Target>,
    borrowing owner: borrowing Owner
  ) {
    unsafe _pointer = unsafeAddress
  }
  
  @_lifetime(copy owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafePointer<Target>,
    copying owner: borrowing Owner
  ) {
    unsafe _pointer = unsafeAddress
  }
  
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "value")
  public subscript() -> Target {
    @_transparent
    unsafeAddress {
      unsafe _pointer
    }
  }
  
  @_alwaysEmitIntoClient
  public var value: Target {
    @_transparent
    unsafeAddress {
      unsafe _pointer
    }
  }
}

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */  {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(borrow self)
  @_addressableSelf
  public func borrow() -> Borrow<Wrapped>? {
    if self == nil {
      return nil
    }
    
    let pointer = unsafe UnsafePointer<Wrapped>(
      Builtin.unprotectedAddressOfBorrow(self)
    )
    
    return unsafe Borrow(unsafeAddress: pointer, borrowing: self)
  }
}
#endif
