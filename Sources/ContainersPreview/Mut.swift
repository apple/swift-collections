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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import Builtin

// FIXME: A better name for the generic argument.

/// A safe mutable reference allowing in-place mutation to an exclusive value.
///
/// In order to get an instance of a `Mut<T>`, one must have exclusive access
/// to the instance of `T`. This is achieved through the 'inout' operator, '&'.
@frozen
@safe
public struct Mut<T: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  package let _pointer: UnsafeMutablePointer<T>

  /// Initializes an instance of 'Mut' extending the exclusive access of the
  /// passed instance.
  ///
  /// - Parameter instance: The desired instance to get a mutable reference to.
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ instance: inout T) {
    unsafe _pointer = UnsafeMutablePointer<T>(Builtin.unprotectedAddressOf(&instance))
  }

  /// Unsafely initializes an instance of 'Mut' using the given 'unsafeAddress'
  /// as the mutable reference based on the lifetime of the given 'owner'
  /// argument.
  ///
  /// - Parameter unsafeAddress: The address to use to mutably reference an
  ///                            instance of type 'T'.
  /// - Parameter owner: The owning instance that this 'Mut' instance's
  ///                    lifetime is based on.
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&owner)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafeMutablePointer<T>,
    mutating owner: inout Owner
  ) {
    unsafe _pointer = unsafeAddress
  }

  /// Unsafely initializes an instance of 'Mut' using the given
  /// 'unsafeImmortalAddress' as the mutable reference acting as though its
  /// lifetime is immortal.
  ///
  /// - Parameter unsafeImmortalAddress: The address to use to mutably reference
  ///                                    an immortal instance of type 'T'.
  @_lifetime(immortal)
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  public init(
    unsafeImmortalAddress: UnsafeMutablePointer<T>
  ) {
    unsafe _pointer = unsafeImmortalAddress
  }
}

extension Mut where T: ~Copyable {
  /// Dereferences the mutable reference allowing for in-place reads and writes
  /// to the underlying instance.
  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<T>(_pointer)
    }
    
    @_transparent
    @_lifetime(self: copy self)
    unsafeMutableAddress {
      unsafe _pointer
    }
  }
}
#endif
