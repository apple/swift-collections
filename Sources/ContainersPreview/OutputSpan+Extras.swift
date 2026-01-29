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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.3)
@available(SwiftStdlib 5.0, *)
@_alwaysEmitIntoClient
package func withTemporaryOutputSpan<Element: ~Copyable, E: Error, R: ~Copyable>(
  of type: Element.Type,
  capacity: Int,
  _ body: (inout OutputSpan<Element>) throws(E) -> R
) throws(E) -> R {
  try withUnsafeTemporaryAllocation(
    of: Element.self, capacity: capacity
  ) { buffer throws(E) in
    var span = OutputSpan(buffer: buffer, initializedCount: 0)
    return try body(&span)
  }
}
#endif

#if compiler(>=6.2)
@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  /// Removes and returns the last element of this output span, if it exists.
  ///
  /// - Returns: The last element of the original span if it wasn't empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  package mutating func _popLast() -> Element? {
    // FIXME: This needs to be in the stdlib.
    _withUnsafeMutableBufferPointer { buffer, count in
      guard count > 0 else { return nil }
      count &-= 1
      return buffer.moveElement(from: count)
    }
  }
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_lifetime(source: copy source)
  @inlinable
  package mutating func _append(moving source: inout InputSpan<Element>) {
    // FIXME: This needs to be in the stdlib.
    self._withUnsafeMutableBufferPointer { dst, dstCount in
      source.withUnsafeMutableBufferPointer { src, srcCount in
        let dstEnd = dstCount + srcCount
        let srcStart = src.count - srcCount
        precondition(dstEnd <= dst.count, "OutputSpan capacity overflow")
        let srcItems = src._extracting(uncheckedFrom: srcStart, to: src.count)
        dst
          ._extracting(uncheckedFrom: dstCount, to: dstEnd)
          .moveInitializeAll(fromContentsOf: srcItems)
        dstCount &+= srcCount
        srcCount = 0
      }
    }
  }
}
#endif

@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inlinable // FIXME: This should be implied by @_aeic
  @_lifetime(self: copy self)
  package mutating func _withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (
      UnsafeMutableBufferPointer<Element>,
      _ initializedCount: inout Int
    ) throws(E) -> R
  ) throws(E) -> R {
    // FIXME: Work around https://github.com/apple/swift-collections/issues/561 / rdar://169036911
    let capacity = self.capacity
    let r = try self.withUnsafeMutableBufferPointer { buffer, initializedCount throws(E) -> R? in
      if buffer.count == capacity {
        return try body(buffer, &initializedCount)
      }
      return nil
    }
    if let r { return r }

    let start = self.span.withUnsafeBufferPointer { $0.baseAddress } // Wow.
    let correctedBuffer = UnsafeMutableRawBufferPointer(
      start: .init(mutating: start), // Wow, wow.
      count: self.capacity &* MemoryLayout<Element>.stride)
    return try correctedBuffer.withMemoryRebound(to: Element.self) { correctBuffer throws(E) in
      precondition(correctBuffer.count == self.capacity)
      return try self.withUnsafeMutableBufferPointer { badBuffer, count throws(E) in
        precondition(badBuffer.baseAddress == correctBuffer.baseAddress)
        return try body(correctBuffer,  &count)
      }
    }
  }
}

#endif
