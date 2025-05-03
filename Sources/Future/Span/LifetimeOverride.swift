//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Unsafely discard any lifetime dependency on the `dependent` argument.
/// Return a value identical to `dependent` with a lifetime dependency
/// on the caller's borrow scope of the `source` argument.
@unsafe
@_unsafeNonescapableResult
@_alwaysEmitIntoClient
@_transparent
@lifetime(borrow source)
public func _overrideLifetime<
  T: ~Copyable & ~Escapable, U: ~Copyable & ~Escapable
>(
  _ dependent: consuming T, borrowing source: borrowing U
) -> T {
  // TODO: Remove @_unsafeNonescapableResult. Instead, the unsafe dependence
  // should be expressed by a builtin that is hidden within the function body.
  dependent
}

/// Unsafely discard any lifetime dependency on the `dependent` argument.
/// Return a value identical to `dependent` that inherits
/// all lifetime dependencies from the `source` argument.
@unsafe
@_unsafeNonescapableResult
@_alwaysEmitIntoClient
@_transparent
@lifetime(copy source)
public func _overrideLifetime<
  T: ~Copyable & ~Escapable, U: ~Copyable & ~Escapable
>(
  _ dependent: consuming T, copying source: borrowing U
) -> T {
  // TODO: Remove @_unsafeNonescapableResult. Instead, the unsafe dependence
  // should be expressed by a builtin that is hidden within the function body.
  dependent
}

/// Unsafely discard any lifetime dependency on the `dependent` argument.
/// Return a value identical to `dependent` with a lifetime dependency
/// on the caller's exclusive borrow scope of the `source` argument.
@unsafe
@_unsafeNonescapableResult
@_alwaysEmitIntoClient
@_transparent
#if compiler(>=6.2) && $InoutLifetimeDependence
@lifetime(&source)
#else
@lifetime(borrow source)
#endif
public func _overrideLifetime<
  T: ~Copyable & ~Escapable,
  U: ~Copyable & ~Escapable
>(
  _ dependent: consuming T,
  mutating source: inout U
) -> T {
  // TODO: Remove @_unsafeNonescapableResult. Instead, the unsafe dependence
  // should be expressed by a builtin that is hidden within the function body.
  dependent
}
