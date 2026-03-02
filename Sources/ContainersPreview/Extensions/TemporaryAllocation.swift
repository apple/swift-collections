//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

/// A polyfill providing a typed-throws overload of `withUnsafeTemporaryAllocation`.
///
/// Swift 6.3's stdlib does not yet expose a typed-throws version of
/// `withUnsafeTemporaryAllocation`, so we bridge via `Result` on all compiler
/// versions until the stdlib provides it natively.
@_alwaysEmitIntoClient @_transparent
package func _withUnsafeTemporaryAllocation<
  T: ~Copyable, R: ~Copyable,
  E: Error
>(
  of type: T.Type,
  capacity: Int,
  _ body: (UnsafeMutableBufferPointer<T>) throws(E) -> R
) throws(E) -> R {
  let r: Result<R, E> = withUnsafeTemporaryAllocation(
    of: T.self, capacity: capacity
  ) { buffer in
    return Result(catching: { () throws(E) in try body(buffer) })
  }
  return try r.get()
}

#endif
