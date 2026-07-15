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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult: (
      consuming Result, consuming Element
    ) throws(Failure) -> Result
  ) throws(Failure) -> Result {
    var initialResult: Optional = initialResult
    return try withTemporaryAllocation(
      of: Element.self, capacity: _producerBufferSize
    ) { buffer throws(Failure) in
      var done = false
      var result = initialResult.take()
      repeat {
        done = try !self.generate(into: &buffer)
        try buffer._consumeAll { span throws(Failure) in
          while let next = span.popFirst() {
            result = try nextPartialResult(result.take()!, next)
          }
        }
      } while !done
      return result!
    }
  }

  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult: (
      inout Result, consuming Element
    ) throws(Failure) -> Void
  ) throws(Failure) -> Result {
    var initialResult: Optional = initialResult
    return try withTemporaryAllocation(
      of: Element.self, capacity: _producerBufferSize
    ) { buffer throws(Failure) in
      var result = initialResult.take()!
      var done = false
      repeat {
        done = try !self.generate(into: &buffer)
        try buffer._consumeAll { span throws(Failure) in
          while let next = span.popFirst() {
            try updateAccumulatingResult(&result, next)
          }
        }
      } while !done
      return result
    }
  }
}

#endif
