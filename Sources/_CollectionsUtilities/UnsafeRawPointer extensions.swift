//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(<5.7) // SE-0334
extension UnsafeRawPointer {
  /// Obtain the next pointer properly aligned to store a value of type `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedUp<T>(for type: T.Type) -> Self {
    let mask = UInt(MemoryLayout<T>.alignment) &- 1
    let bits = (UInt(bitPattern: self) &+ mask) & ~mask
    return Self(bitPattern: bits)!
  }

  /// Obtain the preceding pointer properly aligned to store a value of type `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedDown<T>(for type: T.Type) -> Self {
    let mask = UInt(MemoryLayout<T>.alignment) &- 1
    let bits = UInt(bitPattern: self) & ~mask
    return Self(bitPattern: bits)!
  }
}

extension UnsafeMutableRawPointer {
  /// Obtain the next pointer properly aligned to store a value of type `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedUp<T>(for type: T.Type) -> Self {
    let mask = UInt(MemoryLayout<T>.alignment) &- 1
    let bits = (UInt(bitPattern: self) &+ mask) & ~mask
    return Self(bitPattern: bits)!
  }

  /// Obtain the preceding pointer properly aligned to store a value of type `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedDown<T>(for type: T.Type) -> Self {
    let mask = UInt(MemoryLayout<T>.alignment) &- 1
    let bits = UInt(bitPattern: self) & ~mask
    return Self(bitPattern: bits)!
  }
}
#endif
