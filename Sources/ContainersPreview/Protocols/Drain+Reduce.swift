//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Drain where Self: ~Copyable & ~Escapable {
  @inlinable
  public consuming func reduce<Result: ~Copyable, E: Error>(
    _ initialResult: consuming Result,
    _ nextPartialResult: (
      consuming Result, consuming Element
    ) throws(E) -> Result
  ) throws(E) -> Result {
    var result = initialResult
    while true {
      var span = drainNext()
      if span.isEmpty { break }
      repeat  {
        result = try nextPartialResult(result, span.removeFirst())
      } while !span.isEmpty
    }
    return result
  }

  @inlinable
  public consuming func reduce<Result: ~Copyable, E: Error>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult: (
      inout Result, consuming Element
    ) throws(E) -> Void
  ) throws(E) -> Result {
    var result = initialResult
    while true {
      var span = drainNext()
      if span.isEmpty { break }
      repeat {
        try updateAccumulatingResult(&result, span.removeFirst())
      } while !span.isEmpty
    }
    return result
  }
}

#endif
