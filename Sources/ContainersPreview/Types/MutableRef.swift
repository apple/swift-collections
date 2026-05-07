//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && UnstableContainersPreview
import Builtin

@available(*, deprecated, renamed: "MutableRef")
public typealias Inout = MutableRef

/// A safe mutable reference allowing in-place mutation to an exclusive value.
///
/// In order to get an instance of a `MutableRef<Target>`, one must have exclusive access
/// to the instance of `Target`. This is achieved through the 'inout' operator, '&'.
@frozen
@safe
public struct MutableRef<Value: ~Copyable /* FIXME: ~Escapable */>: ~Copyable, ~Escapable {
  @available(*, deprecated, renamed: "Value")
  public typealias Target = Value

  @usableFromInline
  package let _pointer: UnsafeMutablePointer<Value>

  /// Initializes an instance of 'Mut' extending the exclusive access of the
  /// passed instance.
  ///
  /// - Parameter value: The desired instance to get a mutable reference to.
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: inout Value) {
    unsafe _pointer = UnsafeMutablePointer<Value>(Builtin.unprotectedAddressOf(&value))
  }

  /// Unsafely initializes an instance of 'Mut' using the given 'unsafeAddress'
  /// as the mutable reference based on the lifetime of the given 'owner'
  /// argument.
  ///
  /// - Parameter unsafeAddress: The address to use to mutably reference an
  ///    instance of type 'Target'.
  /// - Parameter owner: The owning instance that this 'Mut' instance's
  ///    lifetime is based on.
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&owner)
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress: UnsafeMutablePointer<Value>,
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
    unsafeImmortalAddress: UnsafeMutablePointer<Value>
  ) {
    unsafe _pointer = unsafeImmortalAddress
  }
}

extension MutableRef where Value: ~Copyable {
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "value")
  public subscript() -> Value {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<Value>(_pointer)
    }

    @_transparent
    unsafeMutableAddress {
      unsafe _pointer
    }
  }
  
  /// Dereferences the mutable reference allowing for in-place reads and writes
  /// to the underlying instance.
  @_alwaysEmitIntoClient
  public var value: Value {
    @_transparent
    unsafeAddress {
      unsafe .init(_pointer)
    }
    @_transparent
    unsafeMutableAddress {
      unsafe _pointer
    }
  }

}

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */ {
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  public mutating func mutate() -> MutableRef<Wrapped>? {
    if self == nil {
      return nil
    }
    let pointer = unsafe UnsafeMutablePointer<Wrapped>(
      Builtin.unprotectedAddressOf(&self))
    return unsafe MutableRef(unsafeAddress: pointer, mutating: &self)
  }
  
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func insert(_ value: consuming Wrapped) -> MutableRef<Wrapped> {
    self = .some(value)
    return mutate()._consumingUnsafelyUnwrap()
  }

}
#endif
