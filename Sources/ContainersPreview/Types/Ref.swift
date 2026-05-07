//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && UnstableContainersPreview
import Builtin

#if compiler(>=6.4) && COLLECTIONS_BORROW_BUILTIN
/// A safe reference allowing in-place reads to a shared value.
@available(SwiftStdlib 5.0, *)
@frozen
public struct Ref<Value: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  let _builtin: Builtin.Borrow<Value>

  /// Initializes an instance of `Ref` with the given borrowed value. This
  /// creates a constant reference to that value preventing writes on the
  /// original value while this reference is still active.
  @_alwaysEmitIntoClient
  @_lifetime(borrow value)
  @_transparent
  public init(_ value: borrowing Value) {
    _builtin = Builtin.makeBorrow(value)
  }

  /// Unsafely initializes an instance of `Ref` using the given
  /// 'unsafeAddress' as the reference based on the borrowed lifetime of the
  /// given 'owner' argument.
  ///
  /// - Parameter unsafeAddress: The address to use to reference an instance of
  ///                            type `Value`.
  /// - Parameter owner: The owning instance that this `Ref` instance's
  ///                    lifetime is based on.
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow owner)
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress pointer: UnsafePointer<Value>,
    borrowing owner: borrowing Owner
  ) {
    _builtin = unsafe Builtin.makeBorrow(pointer.pointee)
  }
}

@available(SwiftStdlib 5.0, *)
extension Ref where Value: ~Copyable {
  /// Dereferences the constant reference allowing for in-place reads to the
  /// underlying value.
  @_alwaysEmitIntoClient
  @_transparent
  public var value: Value {
    borrow {
      Builtin.dereferenceBorrow(_builtin)
    }
  }
}

#else

/// A safe reference allowing in-place reads to a shared value.
@available(SwiftStdlib 5.0, *)
@frozen
public struct Ref<Value: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  package let _pointer: UnsafePointer<Value>

  @_lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  internal init(_borrowing value: borrowing @_addressable Value) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }

  /// Initializes an instance of `Ref` with the given borrowed value. This
  /// creates a constant reference to that value preventing writes on the
  /// original value while this reference is still active.
  @_lifetime(borrow value)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: borrowing @_addressable Value) {
    unsafe _pointer = UnsafePointer(Builtin.unprotectedAddressOfBorrow(value))
  }

  /// Unsafely initializes an instance of `Ref` using the given
  /// 'unsafeAddress' as the reference based on the borrowed lifetime of the
  /// given 'owner' argument.
  ///
  /// - Parameter unsafeAddress: The address to use to reference an instance of
  ///                            type `Value`.
  /// - Parameter owner: The owning instance that this `Ref` instance's
  ///                    lifetime is based on.
  @unsafe
  @_alwaysEmitIntoClient
  @_lifetime(borrow owner)
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress pointer: UnsafePointer<Value>,
    borrowing owner: borrowing Owner
  ) {
    _pointer = pointer
  }
}

@available(SwiftStdlib 5.0, *)
extension Ref where Value: ~Copyable {
  /// Dereferences the constant reference allowing for in-place reads to the
  /// underlying value.
  @_alwaysEmitIntoClient
  public var value: Value {
    @_transparent
    unsafeAddress {
      _pointer
    }
  }
}

#endif

@available(SwiftStdlib 5.0, *)
extension Ref where Value: ~Copyable {
  @_lifetime(copy owner)
  @_alwaysEmitIntoClient
  @_transparent
  public init<Owner: ~Copyable & ~Escapable>(
    unsafeAddress pointer: UnsafePointer<Value>,
    copying owner: borrowing Owner
  ) {
#if compiler(>=6.4) && COLLECTIONS_BORROW_BUILTIN
    _builtin = unsafe Builtin.makeBorrow(pointer.pointee)
#else
    _pointer = pointer
#endif
  }
}

@available(*, deprecated, renamed: "Ref")
public typealias Borrow = Ref

@available(SwiftStdlib 5.0, *)
extension Ref where Value: ~Copyable {
  @available(*, deprecated, renamed: "Value")
  public typealias Target = Value
}

@available(SwiftStdlib 5.0, *)
extension Ref where Value: ~Copyable {
#if compiler(>=6.4) && COLLECTIONS_BORROW_BUILTIN
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "value")
  public subscript() -> Value {
    @_transparent
    borrow {
      value
    }
  }
#else
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "value")
  public subscript() -> Value {
    @_transparent
    unsafeAddress {
      _pointer
    }
  }
#endif
}

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */  {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(borrow self)
  @_addressableSelf
  public func borrow() -> Ref<Wrapped>? {
    if self == nil {
      return nil
    }

    // FIXME: This assumes that `Optional<T>.some` is guaranteed to have
    // `T` at the beginning of its layout. Is that true?
    let pointer = unsafe UnsafePointer<Wrapped>(
      Builtin.unprotectedAddressOfBorrow(self)
    )
    
    return unsafe Ref(unsafeAddress: pointer, borrowing: self)
  }
}

#endif
