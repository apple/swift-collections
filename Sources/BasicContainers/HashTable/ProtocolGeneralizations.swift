//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS
/// This is a stand-in for the generalization of Equatable as described in SE-0499.
/// This is a temporary protocol that will be deprecated and later removed
/// when the official generalization becomes widely available.
public protocol GeneralizedEquatable: ~Copyable, ~Escapable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Equality is the inverse of inequality. For any values `a` and `b`,
  /// `a == b` implies that `a != b` is `false`.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool
}

/// This is a stand-in for the generalization of Hashable as described in SE-0499.
/// This is a temporary protocol that will be deprecated and later removed
/// when the official generalization becomes widely available.
public protocol GeneralizedHashable: GeneralizedEquatable, ~Copyable, ~Escapable {
  /// Hashes the essential components of this value by feeding them into the
  /// given hasher.
  ///
  /// Implement this method to conform to the `Hashable` protocol. The
  /// components used for hashing must be the same as the components compared
  /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
  /// with each of these components.
  ///
  /// - Important: In your implementation of `hash(into:)`,
  ///   don't call `finalize()` on the `hasher` instance provided,
  ///   or replace it with a different instance.
  ///   Doing so may become a compile-time error in the future.
  ///
  /// - Parameter hasher: The hasher to use when combining the components
  ///   of this instance.
  func hash(into hasher: inout Hasher)

  /// The temporary substitute to `Hashable._rawHashValue(seed:)`, the raw
  /// top-level hashing interface. Some standard library types (mostly
  /// primitives) specialize this to eliminate small resiliency overheads. (This
  /// only matters for tiny keys.)
  ///
  /// We avoid using the stdlib name as the stdlib's default implementation is
  /// overwhelmingly preferable but it isn't (easily) reimplementable outside
  /// of the stdlib.
  ///
  /// This will be replaced by the actual `Hashable` method when its
  /// generalization ships.
  func _rawHashValue_temp(seed: Int) -> Int
}

extension GeneralizedHashable where Self: ~Copyable & ~Escapable {
  @inlinable
  public func _rawHashValue_temp(seed: Int) -> Int {
    var hasher = Hasher()
    hasher.combine(seed)
    self.hash(into: &hasher)
    return hasher.finalize()
  }
}

extension GeneralizedHashable where Self: Hashable {
  @inlinable
  public func _rawHashValue_temp(seed: Int) -> Int {
    _rawHashValue(seed: seed)
  }
}

extension GeneralizedHashable where Self: ~Copyable & ~Escapable {
  /// The hash value.
  ///
  /// Hash values are not guaranteed to be equal across different executions of
  /// your program. Do not save hash values to use during a future execution.
  @_alwaysEmitIntoClient
  @inline(__always)
  public var hashValue: Int {
    _rawHashValue_temp(seed: 0)
  }
}

extension Int: GeneralizedHashable {}
extension Int8: GeneralizedHashable {}
extension Int16: GeneralizedHashable {}
extension Int32: GeneralizedHashable {}
extension Int64: GeneralizedHashable {}
@available(SwiftStdlib 6.0, *)
extension Int128: GeneralizedHashable {}
extension UInt: GeneralizedHashable {}
extension UInt8: GeneralizedHashable {}
extension UInt16: GeneralizedHashable {}
extension UInt32: GeneralizedHashable {}
extension UInt64: GeneralizedHashable {}
@available(SwiftStdlib 6.0, *)
extension UInt128: GeneralizedHashable {}
extension Float: GeneralizedHashable {}
extension Double: GeneralizedHashable {}
@available(SwiftStdlib 5.7, *)
extension Duration: GeneralizedHashable {}
extension String: GeneralizedHashable {}
extension Substring: GeneralizedHashable {}
extension Character: GeneralizedHashable {}
extension Bool: GeneralizedHashable {}
extension UnsafePointer: GeneralizedHashable {}
extension UnsafeMutablePointer: GeneralizedHashable {}

#endif
