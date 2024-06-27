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

@frozen
public struct Box<T: ~Copyable>: ~Copyable {
  @usableFromInline
  let pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.initialize(to: value)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ fromInout: consuming Inout<T>) {
    pointer = fromInout.pointer
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    pointer.deinitialize(count: 1)
    pointer.deallocate()
  }
}

extension Box where T: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func consume() -> T {
    let result = pointer.move()
    pointer.deallocate()
    discard self
    return result
  }

  @_alwaysEmitIntoClient
  @_transparent
  public consuming func leak() -> dependsOn(immortal) Inout<T> {
    Inout<T>(unsafeImmortalAddress: pointer)
  }

  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      UnsafePointer<T>(pointer)
    }

    @_transparent
    nonmutating unsafeMutableAddress {
      pointer
    }
  }
}
