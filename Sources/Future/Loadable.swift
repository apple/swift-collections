//===--- Loadable.swift ---------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Indicate that a type can be safely loaded from raw bytes
///
/// A valid type `T` implementing `Loadable` can be stored into
/// a `UnsafeMutableRawBufferPointer` using the `storeBytes(of:as:)` function,
/// then read out of the same memory by loading the `RawBytes`,
/// then initializing `T` using `T.init(rawBytes:)`.
///
/// let t1: T = ...
/// assert(t is any Loadable)
/// let c = MemoryLayout<T>.size
/// let b = UnsafeMutableRawBufferPointer.allocate(byteCount: c, alignment: 16)
/// b.storeBytes(of: t1, as: T.self)
/// let raw = b.load(as: T.RawBytes.self)
/// let t2 = T(rawBytes: raw)
/// // t1 and t2 are identical
///
/// A `Loadable` type is not expected to be usable across executions of a
/// program. Use `Codable` to communicate across program executions.
public protocol Loadable: BitwiseCopyable {

  /// A type that can represent every valid bit pattern our `Loadable` can have.
  ///
  /// Requirements:
  /// - MemoryLayout<T>.size == MemoryLayout<T.RawBytes>.size
  ///
  /// We'd like this to be either
  /// 1. a fixed-size array of an `AutoLoadable` element type, or
  /// 2. a parameter pack where every element type is `AutoLoadable`.
  associatedtype RawBytes: AutoLoadable

  /// Create an instance of `T` with the bit pattern represented by `rawBytes`.
  ///
  /// If a valid instance of `T` cannot be represented, then return nil.
  init?(rawBytes: RawBytes)
}

/// A `Loadable` type for which there is no ambiguous bit pattern.
///
/// In practice, this means a type which has a power-of-two count of states.
public protocol SurjectivelyLoadable: Loadable {
  init(rawBytes: RawBytes)
}

//FIXME: `AutoLoadable` types must be @frozen.
/// Indicate that a type represents every bit pattern.
///
/// Every bit vector of `size` bytes must be a valid instance.
public protocol AutoLoadable: SurjectivelyLoadable where RawBytes == Self {}

extension AutoLoadable {
  public init(rawBytes: Self) {
    self = rawBytes
  }
}

extension Int: AutoLoadable {}
extension UInt: AutoLoadable {}

extension Int8: AutoLoadable {}
extension UInt8: AutoLoadable {}
extension Int16: AutoLoadable {}
extension UInt16: AutoLoadable {}
extension Int32: AutoLoadable {}
extension UInt32: AutoLoadable {}
extension Int64: AutoLoadable {}
extension UInt64: AutoLoadable {}

extension Float32: AutoLoadable {}
extension Float64: AutoLoadable {}

//FIXME: add [U]Int128, Float16, SIMD types

extension RawSpan {
  public func load<T: Loadable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T? {
    let raw = unsafeLoad(fromByteOffset: offset, as: T.RawBytes.self)
    return T(rawBytes: raw)
  }

  public func loadUnaligned<T: Loadable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T? {
    let raw = unsafeLoadUnaligned(fromByteOffset: offset, as: T.RawBytes.self)
    return T(rawBytes: raw)
  }
}

extension Bool: SurjectivelyLoadable {
  public typealias RawBytes = Int8

  public init(rawBytes: Int8) {
    self = (rawBytes & 1) == 1
  }
}

extension RawSpan {
  public func load<T: SurjectivelyLoadable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    let raw = unsafeLoad(fromByteOffset: offset, as: T.RawBytes.self)
    return T(rawBytes: raw)
  }

  public func loadUnaligned<T: SurjectivelyLoadable>(
    fromByteOffset offset: Int = 0, as: T.Type
  ) -> T {
    let raw = unsafeLoadUnaligned(fromByteOffset: offset, as: T.RawBytes.self)
    return T(rawBytes: raw)
  }
}

extension RawSpan {
  public func view<T: AutoLoadable>(as: T.Type) -> Span<T> {
    unsafeView(as: T.self)
  }
}
