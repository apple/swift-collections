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

extension Optional where Wrapped: ~Copyable {
  @lifetime(borrow self)
  @_addressableSelf
  public func borrow() -> Borrow<Wrapped>? {
    switch self {
    case .some:
      let pointer = unsafe UnsafePointer<Wrapped>(
        Builtin.unprotectedAddressOfBorrow(self)
      )
      
      return unsafe Borrow(unsafeAddress: pointer, owner: self)
      
    case .none:
      return nil
    }
  }
  
  #if false // Compiler bug preventing this
  @lifetime(&self)
  public mutating func mutate() -> Inout<Wrapped>? {
    switch self {
    case .some:
      let pointer = unsafe UnsafeMutablePointer<Wrapped>(
        Builtin.unprotectedAddressOf(&self)
      )
      
      return unsafe Inout(unsafeAddress: pointer, owner: &self)
      
    case .none:
      return nil
    }
  }
  #endif
}
