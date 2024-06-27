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

@frozen
@_rawLayout(like: T, movesAsLike)
public struct Cell<T: ~Copyable>: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public var unsafeAddress: UnsafeMutablePointer<T> {
    UnsafeMutablePointer<T>(Builtin.addressOfRawLayout(self))
  }

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    unsafeAddress.initialize(to: value)
  }
}

extension Cell where T: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public func asInout() -> Inout<T> {
    Inout<T>(unsafeAddress: unsafeAddress, owner: self)
  }

  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      UnsafePointer<T>(unsafeAddress)
    }

    @_transparent
    nonmutating unsafeMutableAddress {
      unsafeAddress
    }
  }
}

extension Cell where T: Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func copy() -> T {
    unsafeAddress.pointee
  }
}
