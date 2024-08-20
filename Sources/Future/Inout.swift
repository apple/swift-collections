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

import Builtin

// FIXME: A better name for the generic argument.

/// A safe mutable reference allowing in-place mutation to an exclusive value.
///
/// In order to get an instance of an `Inout<T>`, one must have exclusive access
/// to the instance of `T`. This is achieved through the 'inout' operator, '&'.
@frozen
public struct Inout<T: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  /// Initializes an instance of 'Inout' extending the exclusive access of the
  /// passed instance.
  ///
  /// - Parameter instance: The desired instance to get a mutable reference to.
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ instance: inout T) {
    _pointer = UnsafeMutablePointer<T>(Builtin.unprotectedAddressOf(&instance))
  }

  /// Unsafely initializes an instance of 'Inout' using the given 'unsafeAddress'
  /// as the mutable reference based on the lifetime of the given 'owner'
  /// argument.
  ///
  /// - Parameter unsafeAddress: The address to use to mutably reference an
  ///                            instance of type 'T'.
  /// - Parameter owner: The owning instance that this 'Inout' instance's
  ///                    lifetime is based on.
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafeMutablePointer<T>,
    owner: inout Owner
  ) {
    _pointer = unsafeAddress
  }

  /// Unsafely initializes an instance of 'Inout' using the given
  /// 'unsafeImmortalAddress' as the mutable reference acting as though its
  /// lifetime is immortal.
  ///
  /// - Parameter unsafeImmortalAddress: The address to use to mutably reference
  ///                                    an immortal instance of type 'T'.
  @_alwaysEmitIntoClient
  @_transparent
  public init(
    unsafeImmortalAddress: UnsafeMutablePointer<T>
  ) -> dependsOn(immortal) Self {
    _pointer = unsafeImmortalAddress
  }
}

extension Inout where T: ~Copyable {
  /// Dereferences the mutable reference allowing for in-place reads and writes
  /// to the underlying instance.
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
