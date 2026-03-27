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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult: (
      consuming Result, consuming Element
    ) throws(ProducerError) -> Result
  ) throws(ProducerError) -> Result {
    var initialResult: Optional = initialResult
    return try _withUnsafeTemporaryAllocation(
      of: Element.self, capacity: _producerBufferSize
    ) { buffer throws(ProducerError) in
      var done = false
      var result = initialResult.take()!
      while !done {
        var span = OutputSpan(buffer: buffer, initializedCount: 0)
        done = try !self.generate(into: &span)
        let c = span.finalize(for: buffer)
        for i in 0 ..< c {
          result = try nextPartialResult(
            result,
            buffer.moveElement(from: i))
        }
      }
      return result
    }
  }

  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult: (
      inout Result, consuming Element
    ) throws(ProducerError) -> Void
  ) throws(ProducerError) -> Result {
    var result = initialResult
    try _withUnsafeTemporaryAllocation(
      of: Element.self, capacity: _producerBufferSize
    ) { buffer throws(ProducerError) in
      var done = false
      while !done {
        var span = OutputSpan(buffer: buffer, initializedCount: 0)
        done = try !self.generate(into: &span)
        let c = span.finalize(for: buffer)
        for i in 0 ..< c {
          try updateAccumulatingResult(
            &result,
            buffer.moveElement(from: i))
        }
      }
    }
    return result
  }
}

#endif
