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

#if compiler(>=6.4) && UnstableContainersPreview
import Builtin

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */  {
  @available(SwiftStdlib 6.4, *)
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

extension Optional where Wrapped: ~Copyable /* FIXME: ~Escapable */ {
  @available(SwiftStdlib 6.4, *)
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  package mutating func mutate() -> MutableRef<Wrapped>? {
    if self == nil {
      return nil
    }
    let pointer = unsafe UnsafeMutablePointer<Wrapped>(
      Builtin.unprotectedAddressOf(&self))
    return unsafe MutableRef(unsafeAddress: pointer, mutating: &self)
  }

  @available(SwiftStdlib 6.4, *)
  @_lifetime(&self)
  @_alwaysEmitIntoClient
  @_transparent
  package mutating func insert(_ value: consuming Wrapped) -> MutableRef<Wrapped> {
    self = .some(value)
    return mutate()._consumingUnsafelyUnwrap()
  }
}

#endif
