//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A polyfill of the typed-throws supporting `withUnsafeTemporaryAllocation` in the 6.3 stdlib.
@_alwaysEmitIntoClient @_transparent
@safe
package func _withUnsafeTemporaryAllocation<
  T: ~Copyable, R: ~Copyable,
  E: Error
>(
  of type: T.Type,
  capacity: Int,
  _ body: (UnsafeMutableBufferPointer<T>) throws(E) -> R
) throws(E) -> R {
#if compiler(>=6.4)
  try withUnsafeTemporaryAllocation(of: type, capacity: capacity, body)
#else
  let r: Result<R, E> = unsafe withUnsafeTemporaryAllocation(
    of: T.self, capacity: capacity
  ) { buffer in
    return Result(catching: { () throws(E) in unsafe try body(buffer) })
  }
  return try r.get()
#endif
}

// FIXME: Remove when we drop Swift 6.2
@_alwaysEmitIntoClient
@_transparent
@safe
package func _withUnsafeTemporaryAllocation<R: ~Copyable, E: Error>(
  byteCount: Int,
  alignment: Int,
  _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R
) throws(E) -> R {
#if compiler(<6.3)
  let r: Result<R, E> = unsafe withUnsafeTemporaryAllocation(
    byteCount: byteCount, alignment: alignment
  ) { buffer in
    return Result(catching: { () throws(E) in unsafe try body(buffer) })
  }
  return try r.get()
#else
  return try withUnsafeTemporaryAllocation(byteCount: byteCount, alignment: alignment, body)
#endif
}
