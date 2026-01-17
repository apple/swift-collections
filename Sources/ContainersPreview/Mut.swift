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

#if compiler(>=6.2)
import Builtin

/// A safe mutable reference allowing in-place mutation to an exclusive value.
///
/// In order to get an instance of a `Mut<Target>`, one must have exclusive access
/// to the instance of `Target`. This is achieved through the 'inout' operator, '&'.
@frozen
@safe
public struct Mut<Target: ~Copyable /* FIXME: ~Escapable */>: ~Copyable, ~Escapable {
  @usableFromInline
  package let _pointer: UnsafeMutablePointer<Target>

  /// Initializes an instance of 'Mut' extending the exclusive access of the
  /// passed instance.
  ///
  /// - Parameter instance: The desired instance to get a mutable reference to.
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ instance: inout Target) {
    unsafe _pointer = UnsafeMutablePointer<Target>(Builtin.unprotectedAddressOf(&instance))
  }

  /// Unsafely initializes an instance of 'Mut' using the given 'unsafeAddress'
  /// as the mutable reference based on the lifetime of the given 'owner'
  /// argument.
  ///
  /// - Parameter unsafeAddress: The address to use to mutably reference an
  ///                            instance of type 'Target'.
  /// - Parameter owner: The owning instance that this 'Mut' instance's
  ///                    lifetime is based on.
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&owner)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafeMutablePointer<Target>,
    mutating owner: inout Owner
  ) {
    unsafe _pointer = unsafeAddress
  }

  /// Unsafely initializes an instance of 'Mut' using the given
  /// 'unsafeImmortalAddress' as the mutable reference acting as though its
  /// lifetime is immortal.
  ///
  /// - Parameter unsafeImmortalAddress: The address to use to mutably reference
  ///                                    an immortal instance of type 'Target'.
  @_lifetime(immortal)
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  public init(
    unsafeImmortalAddress: UnsafeMutablePointer<Target>
  ) {
    unsafe _pointer = unsafeImmortalAddress
  }
}

extension Mut where Target: ~Copyable {
  /// Dereferences the mutable reference allowing for in-place reads and writes
  /// to the underlying instance.
  @_alwaysEmitIntoClient
  public subscript() -> Target {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<Target>(_pointer)
    }

    @_transparent
    @_lifetime(self: copy self)
    unsafeMutableAddress {
      unsafe _pointer
    }
  }
}

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */ {
  @_lifetime(&self)
  public mutating func mutate() -> Mut<Wrapped>? {
    if self == nil {
      return nil
    }
    let pointer = unsafe UnsafeMutablePointer<Wrapped>(
      Builtin.unprotectedAddressOf(&self))
    return unsafe Mut(unsafeAddress: pointer, mutating: &self)
  }
  
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func insert(_ value: consuming Wrapped) -> Mut<Wrapped> {
    self = .some(value)
    return mutate()._consumingUnsafelyUnwrap()
  }

}
#endif
